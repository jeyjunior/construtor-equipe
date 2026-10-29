#!/usr/bin/env bash
# Hook PreToolUse (Edit|Write|MultiEdit): nega a edição quando
#  1. o destino é um local de sistema ou de persistência do Windows (Startup, System32, hosts,
#     perfil do PowerShell), seja qual for o conteúdo;
#  2. o conteúdo novo casa com um padrão de segredo de padroes-segredos.txt.
# Trazido do vault (security-gate-edit). Precisa de jq para ler o conteúdo; sem ele, não faz nada
# (o hook verificar-ambiente.sh avisa ao abrir a sessão).

ENTRADA=$(cat)
command -v jq >/dev/null 2>&1 || exit 0
# shellcheck source=comum.sh
source "$(dirname "${BASH_SOURCE[0]}")/comum.sh"

ARQ=$(printf '%s' "$ENTRADA" | jq -r '.tool_input.file_path // empty')
[ -n "$ARQ" ] || exit 0
CONTEUDO=$(printf '%s' "$ENTRADA" | jq -r '.tool_input | (.new_string // .content // ((.edits // []) | map(.new_string // "") | join("\n")))')

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
  negar_ferramenta "O conteúdo para $REL parece conter um segredo (padrão de .claude/hooks/padroes-segredos.txt). Use o padrão segredo.json de .claude/rules/segredos.md: o valor real fica em $PASTA_DOCUMENTO/sensivel/segredo.json, guardado pelo usuário."
fi
exit 0
