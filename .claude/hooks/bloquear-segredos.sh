#!/usr/bin/env bash
# Hook PreToolUse (Edit|Write|MultiEdit): nega a edição quando
#  1. o destino é um local de sistema ou de persistência do Windows (Startup, System32, hosts,
#     perfil do PowerShell), seja qual for o conteúdo;
#  2. o conteúdo novo casa com um padrão de segredo de padroes-segredos.txt.
# Com jq, examina só o conteúdo novo. Sem jq, examina a entrada inteira do hook, o que inclui o
# texto antigo de uma edição (menos preciso, mas não fica desligado).

ENTRADA=$(cat)
# shellcheck source=comum.sh
source "$(dirname "${BASH_SOURCE[0]}")/comum.sh"

ARQ=$(caminho_da_entrada "$ENTRADA")
[ -n "$ARQ" ] || exit 0
SEM_JQ=""
if command -v jq >/dev/null 2>&1; then
  CONTEUDO=$(printf '%s' "$ENTRADA" | jq -r '.tool_input | (.new_string // .content // ((.edits // []) | map(.new_string // "") | join("\n")))')
else
  CONTEUDO=${ENTRADA//\\\"/\"}   # no JSON cru, as aspas do conteúdo chegam como \"
  SEM_JQ=" (Sem jq, a checagem também olha o texto antigo da edição; instale o jq para ela olhar só o novo.)"
fi

# 1. Locais de sistema do Windows.
ARQ_N=$(minusculas "${ARQ//\\//}")
SISTEMA=(
  '^[a-z]:/windows/'
  '/system32/'
  '/start menu/programs/startup/'
  '/drivers/etc/hosts'
  '/microsoft\.powershell_profile\.ps1$'
  '/documents/(windows)?powershell/profile\.ps1$'
  '/programdata/microsoft/windows/start menu/'
)
for s in "${SISTEMA[@]}"; do
  if [[ "$ARQ_N" =~ $s ]]; then
    negar_ferramenta "Escrita em local de sistema do Windows bloqueada pelo kit ($ARQ). Se for intencional, o usuário faz à mão."
  fi
done

# 2. Segredos no conteúdo.
[ -n "$CONTEUDO" ] || exit 0
PADROES="$(dirname "${BASH_SOURCE[0]}")/padroes-segredos.txt"
[ -f "$PADROES" ] || exit 0
REL=$(relativo_a_raiz "$ARQ")
[[ "$REL" == ".claude/hooks/padroes-segredos.txt" ]] && exit 0

# Junta os padrões que valem para este arquivo numa expressão só (um grep, não um por padrão).
JUNTO=""
while IFS= read -r linha || [ -n "$linha" ]; do
  linha=${linha%$'\r'}
  [[ -z "$linha" || "$linha" == \#* ]] && continue
  if [[ "$linha" == *"|||"* ]]; then
    PADRAO="${linha%%|||*}"
    EXCECAO="${linha#*|||}"
    [[ "$REL" =~ $EXCECAO ]] && continue
  else
    PADRAO="$linha"
  fi
  JUNTO="${JUNTO:+$JUNTO|}($PADRAO)"
done < "$PADROES"
[ -n "$JUNTO" ] || exit 0

if printf '%s' "$CONTEUDO" | grep -qE -- "$JUNTO"; then
  negar_ferramenta "O conteúdo para $REL parece conter um segredo (padrão de .claude/hooks/padroes-segredos.txt). Use o padrão parametro.json de .claude/rules/parametros.md: o valor real fica em $PASTA_PRIVADO/parametros/parametro.json, guardado pelo usuário.$SEM_JQ"
fi
exit 0
