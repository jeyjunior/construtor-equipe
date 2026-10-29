#!/usr/bin/env bash
# Hook PostToolUse (Edit|Write): formata o arquivo de Projeto/ que o Claude acabou de editar,
# com o comando FORMATAR de .claude/comandos.conf, rodado dentro de Projeto/.
# Nunca bloqueia: arquivo fora de Projeto/, sem comando, extensão fora de FORMATAR_EXTENSOES
# ou falha na formatação, sai sem fazer nada.

ENTRADA=$(cat)
# shellcheck source=comum.sh
source "$(dirname "${BASH_SOURCE[0]}")/comum.sh"
carregar_comandos || exit 0
[ -n "${FORMATAR:-}" ] && [ -n "${FORMATAR_EXTENSOES:-}" ] || exit 0

ARQ=$(caminho_da_entrada "$ENTRADA")
[ -n "$ARQ" ] || exit 0
NO_PROJETO=$(dentro_do_projeto "$(relativo_a_raiz "$ARQ")") || exit 0

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
