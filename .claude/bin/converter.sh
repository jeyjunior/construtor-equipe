#!/usr/bin/env bash
# Parte mecânica do /converter: prepara o projeto em conversor/, mostra o plano e copia.
# O original fica em conversor/ sem alteração de conteúdo: só CLAUDE.md e .claude são renomeados.
#
#   converter.sh preparar [pasta]   confere pendências e renomeia as instruções antigas
#   converter.sh plano   [pasta] [--raiz REL] [--incluir REL]... [--excluir REL]...
#   converter.sh copiar  [pasta] [--raiz REL] [--incluir REL]... [--excluir REL]...
#
# --raiz     pasta do código, só em projeto sem git (padrão: Projeto/, se existir; senão, a raiz)
# --incluir  item ignorado pelo git que deve vir para Projeto/ (relativo à pasta do código)
# --excluir  item que não deve ser guardado em Projeto_Documento/origem/ (relativo à pasta do projeto)
#
# Saídas: 0 = ok; 1 = uso ou estado inválido; 2 = pendência na origem.

set -u
export CLAUDE_PROJECT_DIR
CLAUDE_PROJECT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
# shellcheck source=../hooks/comum.sh
source "$CLAUDE_PROJECT_DIR/.claude/hooks/comum.sh"

CONVERSOR="$RAIZ/conversor"
P="$RAIZ/$PASTA_PROJETO"
GUARDA="$RAIZ/$PASTA_DOCUMENTO/origem"
# Gerados pela ferramenta: não são código nem documento e podem ter muitos GB.
GERADOS=(.git .vs .vscode .idea bin obj node_modules .venv venv __pycache__ .cache Library Temp Logs UserSettings)

parar() { echo "ERRO: $1" >&2; exit "${2:-1}"; }

# Exatamente um projeto por conversão, numa pasta própria dentro de conversor/.
achar_origem() {
  [ -d "$CONVERSOR" ] || parar "a pasta conversor/ não existe."
  if [ -n "${1:-}" ]; then
    O="$CONVERSOR/$1"
    [ -d "$O" ] || parar "conversor/$1 não existe."
    return
  fi
  local itens=() i
  for i in "$CONVERSOR"/* "$CONVERSOR"/.[!.]*; do
    [ -e "$i" ] || continue
    [ "$(basename "$i")" = ".gitignore" ] || itens+=("$i")
  done
  [ ${#itens[@]} -gt 0 ] || parar "conversor/ está vazia."
  [ ${#itens[@]} -eq 1 ] && [ -d "${itens[0]}" ] \
    || parar "conversor/ deve ter uma única pasta, com um projeto. Encontrado: ${#itens[@]} item(ns)."
  O="${itens[0]}"
}

# Define R (pasta do código) e MODO. Mais de um repositório não cabe na estrutura do kit.
achar_repositorio() {
  local repos=()
  mapfile -d '' -t repos < <(find "$O" -type d -name .git -prune -print0 2>/dev/null)
  [ ${#repos[@]} -le 1 ] || parar "há ${#repos[@]} repositórios git na pasta. O kit trabalha com um só; converta um por vez."
  if [ ${#repos[@]} -eq 1 ]; then
    MODO=git; R=$(dirname "${repos[0]}")
  else
    MODO=sem-git
    if [ -n "${ARG_RAIZ:-}" ]; then R="$O/$ARG_RAIZ"
    elif [ -d "$O/$PASTA_PROJETO" ]; then R="$O/$PASTA_PROJETO"
    else R="$O"; fi
    [ -d "$R" ] || parar "a pasta do código não existe: $R"
  fi
}

# CLAUDE.md e .claude renomeados aqui não contam como pendência.
RE_INSTRUCOES='(^|/)(CLAUDE\.md|CLAUDE\.local\.md|\.claude)(\.antigo)?(/|"?$)'

conferir_pendencias() {
  [ "$MODO" = git ] || return 0
  local sujo sem_push=""
  sujo=$(git -C "$R" -c core.quotePath=false status --porcelain | cut -c4- | grep -Ev "$RE_INSTRUCOES")
  if [ -n "$(git -C "$R" remote)" ]; then
    sem_push=$(git -C "$R" log --branches --not --remotes --oneline)
  fi
  if [ -n "$sujo" ] || [ -n "$sem_push" ]; then
    {
      echo "PENDÊNCIA na origem. Resolva no projeto original e copie de novo para conversor/."
      [ -z "$sujo" ] || { echo "Sem commit:"; printf '%s\n' "$sujo" | head -n 30; }
      [ -z "$sem_push" ] || { echo "Sem push:"; printf '%s\n' "$sem_push" | head -n 30; }
    } >&2
    exit 2
  fi
}

# Renomeia as instruções antigas: o Claude Code carregaria essas regras e skills ao ler a pasta.
preparar() {
  local itens=() i qtd=0
  mapfile -d '' -t itens < <(find "$O" \( -name .git -o -name node_modules -o -name Library \) -prune -o \
    \( -name CLAUDE.md -o -name CLAUDE.local.md -o -name .claude \) -print0 2>/dev/null | sort -zr)
  for i in "${itens[@]}"; do
    [ -e "$i.antigo" ] && parar "já existe $i.antigo."
    mv "$i" "$i.antigo" || parar "não consegui renomear $i."
    qtd=$((qtd + 1))
  done
  echo "Projeto: $O"
  echo "Tipo: $MODO"
  echo "Instruções antigas renomeadas: $qtd"
}

conferir_destino() {
  local i nome
  for i in "$P"/* "$P"/.[!.]*; do
    [ -e "$i" ] || continue
    nome=$(basename "$i")
    case "$nome" in
      .gitignore|.gitattributes) ;;
      .git) [ "$MODO" = sem-git ] || parar "$PASTA_PROJETO/ já tem um repositório." ;;
      *) parar "$PASTA_PROJETO/ não está vazia ($nome). A conversão só roda numa cópia nova do kit." ;;
    esac
  done
  if [ "$MODO" = sem-git ]; then
    [ -d "$P/.git" ] || parar "projeto sem git: crie antes o repositório em $PASTA_PROJETO/ (git -C $PASTA_PROJETO init -b main)."
    ! git -C "$P" rev-parse -q --verify HEAD >/dev/null || parar "o repositório de $PASTA_PROJETO/ já tem commits."
  fi
  if [ -d "$GUARDA" ] && [ -n "$(ls -A "$GUARDA")" ]; then
    parar "$PASTA_DOCUMENTO/origem/ não está vazia. A conversão só roda numa cópia nova do kit."
  fi
}

# Arquivos do código em projeto sem git, relativos a R: tudo menos o que Projeto/.gitignore ignora.
listar_codigo_sem_git() {
  git --git-dir="$P/.git" --work-tree="$R" -c core.quotePath=false ls-files -z -o \
    --exclude-from="$P/.gitignore" --exclude-per-directory=.gitignore
}

# Separa em GUARDAR (vai para origem/) e SENSIVEIS (fica para o usuário). Caminhos relativos a O.
classificar_guarda() {
  GUARDAR=(); SENSIVEIS=()
  local args=() n e arq rel dentro prefixo=""
  for n in "${GERADOS[@]}"; do args+=(-name "$n" -prune -o); done
  for e in "${ARG_EXCLUIR[@]}"; do args+=(-path "$O/${e%/}" -prune -o); done
  [ "$R" = "$O" ] || prefixo="${R#"$O"/}/"
  while IFS= read -r -d '' arq; do
    rel="${arq#"$O"/}"
    if eh_sensivel "$rel"; then SENSIVEIS+=("$rel"); continue; fi
    case "$rel" in *.antigo|*.antigo/*) GUARDAR+=("$rel"); continue ;; esac
    # Dentro do código só os documentos são guardados: o resto já vai para Projeto/.
    if [ -z "$prefixo" ] || [[ "$rel" == "$prefixo"* ]]; then
      dentro="${rel#"$prefixo"}"
      eh_documentacao "$dentro" && GUARDAR+=("$rel")
    else
      GUARDAR+=("$rel")
    fi
  done < <(find "$O" "${args[@]}" -type f -print0 2>/dev/null)
}

# Item de --incluir: precisa existir e não pode ter nada sensível. Chave o usuário copia.
conferir_incluidos() {
  local item arq rel
  for item in "${ARG_INCLUIR[@]}"; do
    [ -e "$R/$item" ] || parar "--incluir: $item não existe na pasta do código."
    while IFS= read -r -d '' arq; do
      rel="${arq#"$R"/}"
      eh_sensivel "$rel" && parar "--incluir: $rel é sensível. Arquivo sensível você copia para $PASTA_DOCUMENTO/sensivel/."
    done < <(find "$R/$item" -type f -print0 2>/dev/null)
  done
}

mostrar_plano() {
  local i
  echo "Tipo: $MODO"
  echo "Pasta do código: $R"
  if [ "$MODO" = git ]; then
    echo "Branch atual: $(git -C "$R" symbolic-ref --short -q HEAD)"
    echo "Último commit: $(git -C "$R" log -1 --format='%h %ad %s' --date=short 2>/dev/null)"
    echo "Branches locais: $(git -C "$R" branch --format='%(refname:short)' | paste -sd ' ' -)"
    echo "Remoto: $(git -C "$R" remote get-url origin 2>/dev/null || echo nenhum)"
    echo "Arquivos versionados: $(git -C "$R" ls-files | wc -l)"
    [ ! -f "$R/.gitmodules" ] || echo "ATENÇÃO: tem submódulos; o conteúdo deles não é copiado."
    echo "Ignorados pelo git, que só vêm com --incluir:"
    git -C "$R" -c core.quotePath=false ls-files --others --ignored --exclude-standard --directory \
      | head -n 40 | while IFS= read -r i; do printf '  %s  %s\n' "$(du -sh "$R/$i" 2>/dev/null | cut -f1)" "$i"; done
  else
    echo "Arquivos de código a copiar: $(listar_codigo_sem_git | tr -cd '\0' | wc -c)"
  fi
  echo "Arquivos a guardar em origem/: ${#GUARDAR[@]}"
  echo "Sensíveis, que não vêm (copie você para $PASTA_DOCUMENTO/sensivel/): ${#SENSIVEIS[@]}"
  for i in "${SENSIVEIS[@]}"; do echo "  $i"; done
}

# Acrescenta ao arquivo do projeto as linhas do modelo do kit que faltam. Não remove nada.
juntar_modelo() {
  local modelo=$1 destino=$2 linha cabecalho=0
  [ -f "$modelo" ] || return 0
  touch "$destino"
  while IFS= read -r linha || [ -n "$linha" ]; do
    linha=${linha%$'\r'}
    case "$linha" in ''|\#*) continue ;; esac
    tr -d '\r' < "$destino" | grep -Fxq -- "$linha" && continue
    if [ "$cabecalho" = 0 ]; then
      [ -z "$(tail -c1 "$destino")" ] || echo >> "$destino"
      printf '\n# Regras do Construtor Equipe\n' >> "$destino"
      cabecalho=1
    fi
    printf '%s\n' "$linha" >> "$destino"
  done < "$modelo"
}

copiar_guarda() {
  local rel
  for rel in "${GUARDAR[@]}"; do
    mkdir -p "$GUARDA/$(dirname "$rel")"
    cp -p "$O/$rel" "$GUARDA/$rel" || parar "falha ao guardar $rel."
  done
  [ -d "$GUARDA" ] || mkdir -p "$GUARDA"
}

copiar() {
  local tmp item qtd=0 arq
  tmp=$(mktemp -d)
  cp "$P/.gitignore" "$tmp/gitignore" 2>/dev/null
  cp "$P/.gitattributes" "$tmp/gitattributes" 2>/dev/null

  if [ "$MODO" = git ]; then
    cp -a "$R/.git" "$P/.git" || parar "falha ao copiar o .git."
    if git -C "$P" rev-parse -q --verify HEAD >/dev/null; then
      git -C "$P" checkout HEAD -- . || parar "falha ao restaurar os arquivos versionados."
    fi
    for item in "${ARG_INCLUIR[@]}"; do
      (cd "$R" && cp -a --parents "$item" "$P/") || parar "falha ao copiar $item."
    done
  else
    while IFS= read -r -d '' arq; do
      eh_sensivel "$arq" && continue
      case "$arq" in *.antigo|*.antigo/*) continue ;; esac
      (cd "$R" && cp -p --parents "$arq" "$P/") || parar "falha ao copiar $arq."
      qtd=$((qtd + 1))
    done < <(listar_codigo_sem_git)
  fi

  juntar_modelo "$tmp/gitignore" "$P/.gitignore"
  juntar_modelo "$tmp/gitattributes" "$P/.gitattributes"
  rm -rf "$tmp"
  git -C "$P" config core.hooksPath ../.claude/git-hooks
  copiar_guarda

  # Autoconferência: em repositório, o commit tem de ser o mesmo da origem.
  if [ "$MODO" = git ] && git -C "$P" rev-parse -q --verify HEAD >/dev/null; then
    local a b
    a=$(git -C "$R" rev-parse HEAD); b=$(git -C "$P" rev-parse HEAD)
    [ "$a" = "$b" ] || parar "o commit em $PASTA_PROJETO/ ($b) não é o mesmo da origem ($a)."
    echo "Commit conferido: $b"
    git -C "$P" -c core.quotePath=false status --porcelain | cut -c4- \
      | grep -Fxv -e .gitignore -e .gitattributes | sed 's/^/ALTERADO: /'
  else
    echo "Arquivos de código copiados: $qtd"
  fi
  echo "Arquivos guardados em origem/: ${#GUARDAR[@]}"
  echo "Sensíveis que ficaram para você: ${#SENSIVEIS[@]}"
  for item in "${SENSIVEIS[@]}"; do echo "  $item"; done
}

ACAO=${1:-}; [ $# -eq 0 ] || shift
PASTA=""; ARG_RAIZ=""; ARG_INCLUIR=(); ARG_EXCLUIR=()
while [ $# -gt 0 ]; do
  case "$1" in
    --raiz) ARG_RAIZ=${2:?}; shift 2 ;;
    --incluir) ARG_INCLUIR+=("${2:?}"); shift 2 ;;
    --excluir) ARG_EXCLUIR+=("${2:?}"); shift 2 ;;
    --*) parar "opção desconhecida: $1" ;;
    *) PASTA=$1; shift ;;
  esac
done

case "$ACAO" in
  preparar)
    achar_origem "$PASTA"; achar_repositorio; conferir_pendencias; preparar ;;
  plano)
    achar_origem "$PASTA"; achar_repositorio; conferir_pendencias; conferir_destino
    conferir_incluidos; classificar_guarda; mostrar_plano ;;
  copiar)
    achar_origem "$PASTA"; achar_repositorio; conferir_pendencias; conferir_destino
    conferir_incluidos; classificar_guarda; copiar ;;
  *) parar "uso: converter.sh preparar|plano|copiar [pasta] [--raiz REL] [--incluir REL]... [--excluir REL]..." ;;
esac
