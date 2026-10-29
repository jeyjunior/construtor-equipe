#!/usr/bin/env bash
# Hook SessionStart: confere o que os outros hooks não conseguem garantir sozinhos e avisa
# você e o Claude quando algo está errado:
#  - falta jq ou git (sem eles, travas ficam desligadas em silêncio);
#  - estrutura fora do padrão: falta Projeto/ ou Projeto_Documento/, ou há coisa solta no Root;
#  - documentação dentro de um repositório git (iria para o GitHub);
#  - trava de commit (pre-commit do kit) desligada em Projeto/;
#  - documentação ou arquivo sensível já versionado em Projeto/.
# Escreve o JSON sem jq de propósito: precisa funcionar justamente quando falta jq.

# shellcheck source=comum.sh
source "$(dirname "${BASH_SOURCE[0]}")/comum.sh"
AVISOS=()

if ! command -v jq >/dev/null 2>&1; then
  AVISOS+=("Falta jq: os bloqueios de comandos destrutivos e de segredos estão desligados. No Windows: winget install jqlang.jq e reabra o Claude Code.")
fi

[ -d "$RAIZ/$PASTA_PROJETO" ] || AVISOS+=("Estrutura incompleta: falta a pasta $PASTA_PROJETO/ no Root (rode /iniciar-projeto).")
[ -d "$RAIZ/$PASTA_DOCUMENTO" ] || AVISOS+=("Estrutura incompleta: falta a pasta $PASTA_DOCUMENTO/ no Root (rode /iniciar-projeto).")

if ! command -v git >/dev/null 2>&1; then
  AVISOS+=("Falta git: o build roda ao fim de toda resposta e a trava de commit não funciona.")
else
  if [ -e "$RAIZ/.git" ] || { [ -d "$RAIZ/$PASTA_DOCUMENTO" ] && git -C "$RAIZ/$PASTA_DOCUMENTO" rev-parse --is-inside-work-tree >/dev/null 2>&1; }; then
    AVISOS+=("GRAVE: o Root ou $PASTA_DOCUMENTO/ está dentro de um repositório git, então a documentação pode ir para o GitHub. O único repositório deve ser $PASTA_PROJETO/.")
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
      AVISOS+=("GRAVE: $QTD arquivo(s) de documentação ou sensíveis estão no git de $PASTA_PROJETO/, commitados ou em stage ($EXEMPLOS). Mova para $PASTA_DOCUMENTO/ e tire do git com git rm --cached.")
    fi
  fi
  if [ -d "$P" ] && [ ! -f "$P/.gitignore" ]; then
    AVISOS+=("$PASTA_PROJETO/.gitignore não existe; copie o do kit (ele ignora documentação, .env e chaves).")
  fi
fi

# No Root só ficam o kit, Projeto/ e Projeto_Documento/. Pastas de IDE e arquivos do sistema são tolerados.
FORA=()
for item in "$RAIZ"/* "$RAIZ"/.[!.]* "$RAIZ"/..?*; do
  [ -e "$item" ] || continue
  nome=$(basename "$item")
  case "$nome" in
    "$PASTA_PROJETO"|"$PASTA_DOCUMENTO"|.claude|CLAUDE.md|CLAUDE.local.md) ;;
    .git) ;;   # já avisado acima como GRAVE
    .vs|.vscode|.idea|desktop.ini|Desktop.ini|Thumbs.db|.DS_Store) ;;
    *) FORA+=("$nome") ;;
  esac
done
if [ ${#FORA[@]} -gt 0 ]; then
  AVISOS+=("Fora da estrutura no Root: ${FORA[*]}. No Root só ficam $PASTA_PROJETO/ (código), $PASTA_DOCUMENTO/ (documentação) e o kit (CLAUDE.md, .claude/). Mova código para $PASTA_PROJETO/ e documentação para $PASTA_DOCUMENTO/.")
fi

[ ${#AVISOS[@]} -gt 0 ] || exit 0
TEXTO="Kit do projeto:"
for a in "${AVISOS[@]}"; do TEXTO="$TEXTO [$a]"; done
printf '{"systemMessage": "%s", "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "%s Explique ao usuário e ajude a corrigir antes de seguir."}}\n' \
  "$(json_texto "$TEXTO")" "$(json_texto "$TEXTO")"
exit 0
