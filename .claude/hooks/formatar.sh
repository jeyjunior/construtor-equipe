#!/usr/bin/env bash
# Hook PostToolUse (Edit|Write): formata o arquivo de código de projeto/ que o Claude acabou de
# editar, com o comando FORMATAR de .claude/comandos.conf, rodado dentro de projeto/.
# Também marca que esta sessão editou código: o verificar-build.sh só compila na sessão que
# mexeu no código, nunca no gerente, que divide a mesma pasta e não edita código.
# Nunca bloqueia: arquivo fora de projeto/, documento, sem comando, extensão fora de
# FORMATAR_EXTENSOES ou falha na formatação, sai sem fazer nada.

ENTRADA=$(cat)
# shellcheck source=comum.sh
source "$(dirname "${BASH_SOURCE[0]}")/comum.sh"

ARQ=$(caminho_da_entrada "$ENTRADA")
[ -n "$ARQ" ] || exit 0
NO_PROJETO=$(dentro_do_projeto "$(relativo_a_raiz "$ARQ")") || exit 0
eh_doc_do_projeto "$NO_PROJETO" && exit 0

# shortcut: arquivo criado só por comando (ex.: dotnet new) não marca; a primeira edição já marca.
SESSAO=$(sessao_da_entrada "$ENTRADA")
if [ -n "$SESSAO" ]; then
  MARCA=$(marca_de_edicao "$SESSAO")
  mkdir -p "$(dirname "$MARCA")" 2>/dev/null && : > "$MARCA"
fi

carregar_comandos || exit 0
[ -n "${FORMATAR:-}" ] && [ -n "${FORMATAR_EXTENSOES:-}" ] || exit 0

# Só formata as extensões configuradas (sem diferenciar maiúsculas).
EXT=$(minusculas "${NO_PROJETO##*.}")
LISTA=" $(minusculas "$FORMATAR_EXTENSOES") "
[[ "$LISTA" == *" $EXT "* ]] || exit 0

cd "$RAIZ/$PASTA_PROJETO" || exit 0
ARQ_Q=$(printf '%q' "$NO_PROJETO")
if [[ "$FORMATAR" == *"{arquivo}"* ]]; then
  CMD="${FORMATAR%%\{arquivo\}*}${ARQ_Q}${FORMATAR#*\{arquivo\}}"
else
  CMD="$FORMATAR $ARQ_Q"
fi
eval "$CMD" >/dev/null 2>&1
exit 0
