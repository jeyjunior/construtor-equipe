#!/usr/bin/env bash
# Hook SessionStart: confere o que os outros hooks não conseguem garantir sozinhos e avisa
# você e o Claude quando algo está errado:
#  - falta jq ou git (sem jq, os bloqueios ficam menos precisos);
#  - estrutura fora do padrão: falta projeto/ ou privado/, ou há coisa solta no Root;
#  - o Root ou privado/ dentro de um repositório git (chaves e documentos poderiam ir para o GitHub);
#  - trava de commit (pre-commit do kit) desligada em projeto/;
#  - documentação ou arquivo sensível já versionado em projeto/.
# Escreve o JSON sem jq de propósito: precisa funcionar justamente quando falta jq.

# shellcheck source=comum.sh
source "$(dirname "${BASH_SOURCE[0]}")/comum.sh"
AVISOS=()

if ! command -v jq >/dev/null 2>&1; then
  AVISOS+=("Falta jq: os bloqueios de comandos destrutivos e de segredos funcionam em modo menos preciso. No Windows: winget install jqlang.jq e reabra o Claude Code.")
fi

[ -d "$RAIZ/$PASTA_PROJETO" ] || AVISOS+=("Estrutura incompleta: falta a pasta $PASTA_PROJETO/ no Root (rode /iniciar).")
[ -d "$RAIZ/$PASTA_PRIVADO" ] || AVISOS+=("Estrutura incompleta: falta a pasta $PASTA_PRIVADO/ no Root (rode /iniciar).")

if ! command -v git >/dev/null 2>&1; then
  AVISOS+=("Falta git: o build roda ao fim de toda resposta e as travas de branch e de commit não funcionam.")
else
  if [ -e "$RAIZ/.git" ] || { [ -d "$RAIZ/$PASTA_PRIVADO" ] && git -C "$RAIZ/$PASTA_PRIVADO" rev-parse --is-inside-work-tree >/dev/null 2>&1; }; then
    AVISOS+=("GRAVE: o Root ou $PASTA_PRIVADO/ está dentro de um repositório git, então chaves, documentos e material antigo podem ir para o GitHub. O único repositório deve ser $PASTA_PROJETO/.")
  fi
  P="$RAIZ/$PASTA_PROJETO"
  if [ -e "$P/.git" ]; then
    if [ "$(git -C "$P" config core.hooksPath 2>/dev/null)" != "../.claude/git-hooks" ]; then
      AVISOS+=("A trava de commit do kit está desligada em $PASTA_PROJETO/. Para ligar, rode no Root: git -C $PASTA_PROJETO config core.hooksPath ../.claude/git-hooks")
    fi
    # ls-files lista o que está commitado e o que está em stage: os dois iriam para o GitHub.
    NO_GIT=$(git -C "$P" -c core.quotePath=false ls-files 2>/dev/null \
      | grep -iE "$RE_DOC|$RE_SENSIVEL" | grep -viE "$RE_DOC_PERMITIDO|$RE_SENSIVEL_PERMITIDO")
    if [ -n "$NO_GIT" ]; then
      QTD=$(printf '%s\n' "$NO_GIT" | wc -l | tr -d ' ')
      EXEMPLOS=$(printf '%s\n' "$NO_GIT" | head -n 5 | paste -sd ',' - | sed 's/,/, /g')
      AVISOS+=("GRAVE: $QTD arquivo(s) de documentação ou sensíveis estão no git de $PASTA_PROJETO/, commitados ou em stage ($EXEMPLOS). Mova documentação para $PASTA_PRIVADO/docs/ e sensível para $PASTA_PRIVADO/parametros/, tire do git com git rm --cached e troque o segredo se ele já foi enviado.")
    fi
  fi
  if [ -d "$P" ] && [ ! -f "$P/.gitignore" ]; then
    AVISOS+=("$PASTA_PROJETO/.gitignore não existe; copie o do kit (ele ignora documentação, .env e chaves).")
  fi
fi

# No Root só ficam o kit, projeto/, privado/ e conversor/. Pastas de IDE e arquivos do sistema são tolerados.
FORA=()
for item in "$RAIZ"/* "$RAIZ"/.[!.]* "$RAIZ"/..?*; do
  [ -e "$item" ] || continue
  nome=$(basename "$item")
  case "$nome" in
    "$PASTA_PROJETO"|"$PASTA_PRIVADO"|.claude|CLAUDE.md|CLAUDE.local.md|conversor) ;;
    .git) ;;   # já avisado acima como GRAVE
    .vs|.vscode|.idea|desktop.ini|Desktop.ini|Thumbs.db|.DS_Store) ;;
    *) FORA+=("$nome") ;;
  esac
done
if [ ${#FORA[@]} -gt 0 ]; then
  AVISOS+=("Fora da estrutura no Root: ${FORA[*]}. No Root só ficam $PASTA_PROJETO/ (código), $PASTA_PRIVADO/ (quadro e documentos), conversor/ e o kit (CLAUDE.md, .claude/).")
fi

# Lista só o primeiro nível: ler dentro de conversor/ carregaria as regras do projeto antigo.
if [ -n "$(ls -A "$RAIZ/conversor" 2>/dev/null | grep -vx '.gitignore')" ]; then
  if [ -f "$RAIZ/$PASTA_PRIVADO/QUADRO.md" ]; then
    AVISOS+=("Há material em conversor/, mas este projeto já tem quadro. Se a conversão terminou, o usuário pode esvaziar a pasta; para converter outro projeto, use uma cópia nova do kit.")
  else
    AVISOS+=("Há um projeto em conversor/. Se esta é a sessão principal, a primeira coisa a fazer é perguntar: quer analisar e trazer esse projeto para cá? Com um sim, rode a skill converter. Sessão de etapa ignora este aviso.")
  fi
fi

[ ${#AVISOS[@]} -gt 0 ] || exit 0
TEXTO="Kit do projeto:"
for a in "${AVISOS[@]}"; do TEXTO="$TEXTO [$a]"; done
printf '{"systemMessage": "%s", "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "%s Explique ao usuário e ajude a corrigir antes de seguir."}}\n' \
  "$(json_texto "$TEXTO")" "$(json_texto "$TEXTO")"
exit 0
