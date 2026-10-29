#!/usr/bin/env bash
# Hook PreToolUse (Bash|PowerShell): nega comandos destrutivos óbvios antes de rodarem.
# Trazido do vault (security-gate-bash). Precisa de jq; sem ele, não faz nada
# (o hook verificar-ambiente.sh avisa ao abrir a sessão).

ENTRADA=$(cat)
command -v jq >/dev/null 2>&1 || exit 0
COMANDO=$(printf '%s' "$ENTRADA" | jq -r '.tool_input.command // empty')
[ -n "$COMANDO" ] || exit 0

# Shell POSIX (diferencia maiúsculas: nome de comando tem caixa fixa).
POSIX=(
  'rm\s+(-rf?|-fr?|--recursive)\s+["'"'"']?[~/$]'          # apagar a partir de /, ~ ou variável
  'rm\s+(-rf?|-fr?|--recursive)\s+["'"'"']?[A-Za-z]:[\\/]' # apagar a partir de um drive (Git Bash)
  'git\s+push\s+(--force|-f)\s+.*\s+(main|master)\b'
  '>\s*/dev/sd[a-z]'
  'chmod\s+-R\s+777'
  '(curl|wget)\s+[^|]+\|\s*(sh|bash)'               # baixar e executar
  'mkfs\.'
  'dd\s+if=.*of=/dev/[sh]d'
)

# Windows: cmd e PowerShell (sem diferenciar maiúsculas). Mira o catastrófico e raramente
# legítimo em desenvolvimento; limpeza comum de pasta não entra.
WINDOWS=(
  '\b(del|erase|rd|rmdir)\b[^|]*\s/s\b'
  'format\s+[A-Za-z]:'
  '\bdiskpart\b'
  '\bcipher\s+/w'
  'remove-item\b[^|]*-recurse[^|]*([A-Za-z]:\\?(\s|["'"'"']|$)|\\(windows|system32|users)\\)'
  '\bvssadmin\s+delete\b'
  '\bwbadmin\s+delete\b'
  '\bbcdedit\b[^|]*(delete|recoveryenabled\s+no)'
  '(add|set)-mppreference\b'
  '\bcertutil\b[^|]*(-urlcache|-decode)'
  '\b(iex|invoke-expression)\b'
  '\bdownloadstring\b'
  '\bbitsadmin\b[^|]*/transfer'
  '\bmshta\s+https?'
  '\bregsvr32\b[^|]*/i:http'
  '\brundll32\b[^|]*javascript:'
  '\bnetsh\s+advfirewall\b[^|]*state\s+off'
  '\bwevtutil\s+cl\b'
  '\bfsutil\b[^|]*deletejournal'
  'set-executionpolicy\s+(bypass|unrestricted)'
  '-verb\s+runas'
  '\brunas\s+/'
  '\b(powershell|pwsh)(\.exe)?\b[^|]*\s-(e|ec|enc|encodedcommand)\s+[A-Za-z0-9+/=]{16,}'
  '\bnet\s+(user|localgroup)\b[^|]*\s/add'
  '\btakeown\b[^|]*\s/r\b'
  '\bicacls\b[^|]*/grant[^|]*everyone'
  '\bschtasks\b[^|]*/create'
  '\bsc\s+(create|delete)\b'
  '\breg\s+delete\s+[^|]*hklm'
  '\breg\s+add\s+[^|]*\\run\b'
)

MOTIVO=""
for p in "${POSIX[@]}"; do
  if printf '%s' "$COMANDO" | grep -qE -- "$p"; then MOTIVO="$p"; break; fi
done
if [ -z "$MOTIVO" ]; then
  for p in "${WINDOWS[@]}"; do
    if printf '%s' "$COMANDO" | grep -qiE -- "$p"; then MOTIVO="$p"; break; fi
  done
fi
[ -n "$MOTIVO" ] || exit 0

jq -nc --arg r "Comando destrutivo bloqueado pelo kit (padrão: $MOTIVO). Se for intencional, peça ao usuário que rode ele mesmo." \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
exit 0
