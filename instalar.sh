#!/usr/bin/env bash
# Instala o Construtor Equipe numa pasta nova ou atualiza o kit de um projeto que já o usa.
#
#   bash instalar.sh                          pergunta onde fica o Root e o nome dele
#   bash instalar.sh <root> [projeto-antigo]  sem perguntas (projeto-antigo: só na instalação nova)
#
# Root novo: copia o kit e, se informado, um projeto existente para conversor/ (sem pastas geradas).
# Root que já tem o kit: guarda o kit atual em privado/kit-anterior/, troca o que é do kit e mantém o que é
# do projeto (comandos.conf, rules/, permissões próprias do settings.json, settings.local.json).

set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSAO_NOVA="$(tr -d '[:space:]' < "$KIT/.claude/VERSAO")"
PASTAS_DO_KIT=(hooks git-hooks bin modelos)
GERADOS=(.vs .vscode .idea bin obj node_modules .venv venv __pycache__ .cache packages TestResults)
INTERATIVO=1
[ $# -gt 0 ] && INTERATIVO=0

parar() { echo "ERRO: $1" >&2; exit 1; }
info() { echo "  $1"; }

caminho() {
  local c="${1#\"}"; c="${c%\"}"; c="${c#\'}"; c="${c%\'}"
  c="${c/#\~/$HOME}"
  if command -v cygpath >/dev/null 2>&1; then cygpath -u "$c"; else printf '%s' "$c"; fi
}

exibir() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi; }

perguntar() {
  local resposta
  read -r -p "$1 " resposta || true
  printf '%s' "${resposta:-${2:-}}"
}

confirmar() {
  [ "$INTERATIVO" = 0 ] && return 0
  local r; r="$(perguntar "$1 [S/n]" s)"
  [[ $r =~ ^[sSyY] ]]
}

tem_kit() { compgen -G "$1/.claude/skills/construtor-*" >/dev/null; }

copiar_kit() {
  cp -r "$KIT/CLAUDE.md" "$KIT/.claude" "$KIT/projeto" "$KIT/privado" "$KIT/conversor" "$1/"
  rm -rf "$1/.claude/.cache"
}

trazer_projeto() {
  local origem="$1" destino="$2/conversor/$(basename "$1")" exclusoes=() g
  [ -d "$origem" ] || parar "$origem não existe."
  for g in "${GERADOS[@]}"; do exclusoes+=(--exclude="$g"); done
  mkdir -p "$destino"
  tar -C "$origem" "${exclusoes[@]}" -cf - . | tar -C "$destino" -xf -
  info "Projeto copiado para conversor/$(basename "$origem")/ (sem ${GERADOS[*]}). O original não foi alterado."
}

instalar_novo() {
  local root="$1" antigo="${2:-}"
  [ -n "$(ls -A "$root" 2>/dev/null)" ] && parar "$(exibir "$root") já existe, não está vazia e não tem o kit. Para trazer um projeto existente, rode de novo com um Root novo e informe essa pasta como o projeto que já existe."
  [ -z "$antigo" ] || [ -d "$antigo" ] || parar "$antigo não existe."
  mkdir -p "$root"
  copiar_kit "$root"
  echo "Kit $VERSAO_NOVA instalado em $(exibir "$root")"
  [ -n "$antigo" ] && trazer_projeto "$antigo" "$root"
  echo
  echo "Próximo passo: abra o Claude Code (aba Code do app) na pasta $(exibir "$root") e diga o que quer:"
  if [ -n "$antigo" ]; then
    echo "  /construtor-iniciar   (faz a conversão do projeto que está em conversor/)"
  else
    echo "  /construtor-iniciar <o que você quer, com todo o contexto que tiver>"
  fi
}

mesclar_comandos() {
  local antigo="$1" novo="$2"
  awk '
    FNR == NR {
      sub(/\r$/, "")
      if (match($0, /^[A-Z_][A-Z0-9_]*=/)) { nome = substr($0, 1, RLENGTH - 1); valor[nome] = $0; ordem[++n] = nome }
      next
    }
    match($0, /^[A-Z_][A-Z0-9_]*=/) {
      nome = substr($0, 1, RLENGTH - 1); usado[nome] = 1
      if (nome in valor) { print valor[nome]; next }
      if (nome == "SUBAGENTES_VIA" && ("SUBAGENTES_CONTA" in valor)) {
        usado["SUBAGENTES_CONTA"] = 1
        print (valor["SUBAGENTES_CONTA"] ~ /="?secundaria"?$/) ? "SUBAGENTES_VIA=\"cli\"" : "SUBAGENTES_VIA=\"app\""
        next
      }
    }
    { print }
    END {
      for (i = 1; i <= n; i++) if (!(ordem[i] in usado)) extra[++e] = valor[ordem[i]]
      if (e) { print ""; print "# Do projeto (vieram do comandos.conf anterior)"; for (i = 1; i <= e; i++) print extra[i] }
    }
  ' "$antigo" "$novo"
}

mesclar_settings() {
  jq -s '
    def obsoleta: test("secundaria\\.sh");
    def uniao(a; b): reduce (a + b)[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end);
    .[0] as $kit | .[1] as $proj
    | $proj + {"$schema": $kit["$schema"], hooks: $kit.hooks}
    | .permissions = (($proj.permissions // {}) + (reduce ("allow", "ask", "deny") as $k ({};
        .[$k] = uniao($kit.permissions[$k]; [($proj.permissions[$k] // [])[] | select(obsoleta | not)]))))
  ' "$1" "$2"
}

completar_regras() {
  local regras="$1"
  [ -f "$regras" ] || return 0
  if ! grep -q '^\*\*Commits:\*\*' "$regras"; then
    sed -i '/^\*\*Testes:\*\*/a **Commits:** padrão do kit (`<Tipo>: <descrição>`)' "$regras"
    info "rules/projeto.md: linha \"Commits\" acrescentada (padrão do kit)."
  fi
  if ! grep -q '^\*\*Versão:\*\*' "$regras"; then
    sed -i '/^\*\*Commits:\*\*/a **Versão:** a decidir' "$regras"
    info "rules/projeto.md: linha \"Versão\" acrescentada (\"a decidir\": o gerente pergunta no encerramento do ciclo)."
  fi
}

relatar_projeto() {
  local root="$1" git="$1/projeto" principal atual faltam b base
  [ -d "$git/.git" ] || return 0
  if [ "$(git -C "$git" config --get core.hooksPath || true)" != "../.claude/git-hooks" ]; then
    git -C "$git" config core.hooksPath ../.claude/git-hooks
    info "Trava de commit ligada (core.hooksPath)."
  fi
  faltam="$(grep -vxF -f <(tr -d '\r' < "$git/.gitignore" 2>/dev/null) <(tr -d '\r' < "$KIT/projeto/.gitignore") \
    | grep -v -e '^#' -e '^$' || true)"
  if [ -n "$faltam" ]; then
    echo
    echo "projeto/.gitignore: faltam as linhas abaixo (copie na branch principal e faça um commit Docs:):"
    sed 's/^/    /' <<< "$faltam"
  fi
  principal="$(sed -n 's/^BRANCH_PRINCIPAL="\(.*\)"/\1/p' "$root/.claude/comandos.conf")"
  atual="$(git -C "$git" branch --show-current)"
  local mescladas=()
  while read -r b; do
    [ "$b" = "$principal" ] || [ "$b" = "$atual" ] && continue
    base="$principal"
    [[ $b =~ ^(ciclo-[0-9]+)-etapa- ]] && base="${BASH_REMATCH[1]}"
    git -C "$git" rev-parse -q --verify "refs/heads/$base" >/dev/null || continue
    git -C "$git" merge-base --is-ancestor "$b" "$base" && mescladas+=("$b")
  done < <(git -C "$git" for-each-ref --format='%(refname:short)' refs/heads)
  [ ${#mescladas[@]} -eq 0 ] && return 0
  echo
  echo "Branches que já entraram no ciclo ou na principal (o kit agora apaga depois do merge): ${mescladas[*]}"
  if [ "$INTERATIVO" = 1 ] && [[ "$(perguntar "Apagar agora com git branch -d? [s/N]" n)" =~ ^[sSyY] ]]; then
    git -C "$git" branch -d "${mescladas[@]}"
  else
    info "Para apagar depois: git -C projeto branch -d ${mescladas[*]}"
  fi
}

atualizar() {
  local root="$1" c="$1/.claude" anterior guarda pasta f
  command -v jq >/dev/null 2>&1 || parar "a atualização precisa do jq (https://jqlang.org) para juntar o settings.json."
  anterior="v2 ou anterior"
  [ -f "$c/VERSAO" ] && anterior="$(tr -d "[:space:]" < "$c/VERSAO")"
  echo "Kit encontrado em $(exibir "$root") (versão $anterior). Nova: $VERSAO_NOVA."
  echo "Feche antes as sessões do Claude Code abertas neste projeto."
  confirmar "Atualizar?" || { echo "Nada foi alterado."; exit 0; }

  guarda="$root/privado/kit-anterior/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$guarda"
  cp -r "$root/CLAUDE.md" "$c" "$guarda/"
  rm -rf "$guarda/.claude/.cache"
  info "Kit anterior guardado em privado/kit-anterior/$(basename "$guarda")/"

  for f in $(cd "$c" && find skills/construtor-* "${PASTAS_DO_KIT[@]}" -type f 2>/dev/null); do
    [ -e "$KIT/.claude/$f" ] || removidos+=("$f")
  done
  rm -rf "$c"/skills/construtor-*
  for pasta in "${PASTAS_DO_KIT[@]}"; do rm -rf "${c:?}/$pasta"; done
  mkdir -p "$c/skills" "$c/rules"
  cp -r "$KIT"/.claude/skills/construtor-* "$c/skills/"
  for pasta in "${PASTAS_DO_KIT[@]}"; do cp -r "$KIT/.claude/$pasta" "$c/"; done
  cp "$KIT/CLAUDE.md" "$root/CLAUDE.md"
  cp "$KIT/.claude/VERSAO" "$KIT/.claude/.gitattributes" "$c/"
  cp "$KIT/.claude/rules/parametros.md" "$c/rules/"
  info "Trocados: CLAUDE.md, skills construtor-*, ${PASTAS_DO_KIT[*]}, rules/parametros.md."
  [ ${#removidos[@]} -gt 0 ] && info "Saíram do kit (estão na cópia guardada): ${removidos[*]}"

  if [ -f "$guarda/.claude/comandos.conf" ]; then
    mesclar_comandos "$guarda/.claude/comandos.conf" "$KIT/.claude/comandos.conf" > "$c/comandos.conf"
    info "comandos.conf: modelo novo com os valores do projeto."
  else
    cp "$KIT/.claude/comandos.conf" "$c/"
  fi
  if [ -f "$guarda/.claude/settings.json" ]; then
    mesclar_settings "$KIT/.claude/settings.json" "$guarda/.claude/settings.json" > "$c/settings.json"
    info "settings.json: permissões e hooks do kit novo, mais as regras próprias do projeto."
  else
    cp "$KIT/.claude/settings.json" "$c/"
  fi
  completar_regras "$c/rules/projeto.md"
  if [ ! -e "$root/privado/parametros/parametro.json" ]; then
    mkdir -p "$root/privado/parametros"
    cp "$KIT/privado/parametros/parametro.json" "$root/privado/parametros/"
    info "privado/parametros/parametro.json criado com a estrutura base (não existia)."
  fi

  if grep -q '^SUBAGENTES_CONTA="secundaria"' "$guarda/.claude/comandos.conf" 2>/dev/null; then
    echo
    echo "Subagentes pela CLI: o kit agora usa o login atual da CLI."
    echo "  Para continuar no login que estava em ~/.claude-secundaria, defina (PowerShell, uma vez):"
    echo "  [Environment]::SetEnvironmentVariable('CONSTRUTOR_CLI_CONFIG', \"\$HOME\\.claude-secundaria\", 'User')"
  fi
  relatar_projeto "$root"

  if [ -z "${INSTALAR_SEM_AUTOTESTE:-}" ]; then
    echo
    echo "Autotestes do kit:"
    (cd "$root" && bash .claude/bin/testar-hooks.sh 2>&1 | tail -n 3) || echo "  Autotestes falharam: rode no Root bash .claude/bin/testar-hooks.sh"
  fi
  echo
  echo "Kit atualizado para $VERSAO_NOVA. O quadro e privado/docs/ não foram tocados."
}

principal() {
  local root antigo="" pai nome
  if [ "$INTERATIVO" = 1 ]; then
    echo "Construtor Equipe $VERSAO_NOVA"
    pai="$(caminho "$(perguntar "Pasta onde fica (ou vai ficar) o Root [$(pwd)]:" "$(pwd)")")"
    nome="$(perguntar "Nome da pasta do Root:")"
    [ -n "$nome" ] || parar "informe o nome da pasta."
    root="$pai/$nome"
  else
    root="$(caminho "$1")"
    antigo="${2:+$(caminho "$2")}"
  fi
  root="${root%/}"
  [ "$(cd "$root" 2>/dev/null && pwd)" = "$KIT" ] && parar "essa é a pasta do próprio kit."

  if tem_kit "$root"; then
    [ -n "$antigo" ] && parar "$root já tem o kit: a conversão de outro projeto é numa pasta nova."
    atualizar "$root"
    return
  fi
  if [ "$INTERATIVO" = 1 ]; then
    antigo="$(perguntar "Projeto que já existe para trazer (caminho; vazio = projeto novo):")"
    [ -n "$antigo" ] && antigo="$(caminho "$antigo")"
  fi
  instalar_novo "$root" "$antigo"
}

removidos=()
principal "$@"
