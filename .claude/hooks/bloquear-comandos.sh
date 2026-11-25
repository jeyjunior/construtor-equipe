#!/usr/bin/env bash
# Hook PreToolUse (Bash|PowerShell): nega, antes de rodar, comandos destrutivos óbvios, os que
# desligam a trava de commit, os que leem privado/parametros/ e o que apaga a branch de uma etapa
# que ainda está em "Fazendo" no quadro.
# Com jq, examina o comando. Sem jq, examina a entrada inteira menos a descrição (menos preciso,
# mas não fica desligado); o verificar-ambiente.sh avisa ao abrir a sessão.
# Os padrões são testados juntos num grep só: no Git Bash cada processo custa dezenas de ms.

ENTRADA=$(cat)
# shellcheck source=comum.sh
source "${BASH_SOURCE[0]%/*}/comum.sh"

COMANDO=$(campo_da_entrada "$ENTRADA" command)
if [ -z "$COMANDO" ] && ! command -v jq >/dev/null 2>&1; then
  # Sem jq e sem conseguir ler o campo: a entrada inteira, menos a descrição (texto livre: citar
  # nela um comando perigoso não pode negar o comando).
  COMANDO=$(sed -E 's/"description"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"//' <<< "$ENTRADA")
fi
[ -n "$COMANDO" ] || exit 0

Q="[\"']"                       # aspas simples ou duplas antes de um caminho
ALVO_RAIZ="$Q?([~/\$]|[A-Za-z]:[\\\\/])"   # caminho a partir de /, ~, variável ou drive
RECURSIVO='(-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)'

# Diferenciam maiúsculas: comando de shell POSIX tem caixa fixa.
COM_CAIXA=(
  "\\brm\\s([^;&|]*\\s)?$RECURSIVO\\s([^;&|]*\\s)?$ALVO_RAIZ"     # rm -rf /, rm -r -f ~, rm -Rf "\$X"
  "\\brm\\s([^;&|]*\\s)?$ALVO_RAIZ[^;&|]*\\s$RECURSIVO(\\s|\$)"    # rm / -rf
  '\brm\s[^;&|]*--no-preserve-root'
  'git\s+push\s+(--force|-f)\s+.*\s+(main|master)\b'
  '>\s*/dev/sd[a-z]'
  'chmod\s+-R\s+777'
  '(curl|wget)\s+[^|]+\|\s*(sh|bash)'               # baixar e executar
  'mkfs\.'
  'dd\s+if=.*of=/dev/[sh]d'
)

# Sem diferenciar maiúsculas: cmd, PowerShell e chaves do git. Mira o catastrófico e raramente
# legítimo em desenvolvimento; limpeza comum de pasta não entra.
SEM_CAIXA=(
  '\b(del|erase|rd|rmdir)\b[^|]*\s/s\b'
  'format\s+[A-Za-z]:'
  '\bdiskpart\b'
  '\bcipher\s+/w'
  '\bvssadmin\s+delete\b'
  '\bwbadmin\s+delete\b'
  '\bbcdedit\b[^|]*(delete|recoveryenabled\s+no)'
  '(add|set)-mppreference\b'
  '\bcertutil\b[^|]*(-urlcache|-decode)'
  '(^|[;&|({])\s*(iex|invoke-expression)\b'          # executar texto como comando (não a palavra num grep)
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
  'core\.hookspath\s*='                               # git -c core.hooksPath=... desliga a trava
  '--unset(-all)?\s+core\.hookspath'
)

# Apagar recursivo no PowerShell, com o alvo antes ou depois do -Recurse.
RE_APAGAR='(^|[;&|({])\s*(remove-item|ri|rm|rmdir|del|erase)(\s[^;&|]*)?\s-r[a-z]*\b'
RE_ALVO_SISTEMA="(^|\\s|$Q)[a-z]:[\\\\/]?$Q?(\\s|\$|[;&|)])|[\\\\/](windows|system32|users)([\\\\/]|\\s|$Q|\$)"
# Comandos que leem ou copiam conteúdo. Listar (ls, dir, Test-Path) fica de fora.
RE_LEITURA='(^|[;&|({`[:space:]])(cat|type|get-content|gc|head|tail|less|more|grep|egrep|rg|sed|awk|cp|copy|copy-item|cpi|mv|move|move-item|base64|xxd|od|strings|select-string|sls|findstr|jq|sort|uniq|cut|diff|tar|zip|7z|compress-archive|scp|curl|iwr|invoke-webrequest|irm|invoke-restmethod|python3?|py|node|notepad|code|ii|invoke-item|import-csv)(\s|$)|<'
# Desligar a trava de commit. Conferido sem o texto entre aspas: "-n" ou "--no-verify" dentro da
# mensagem do commit não é opção.
RE_SEM_TRAVA='\bgit\b[^;&|]*\s--no-veri[a-z]*\b|\bgit(\s+(-C|-c)\s+[^ ;&|]+|\s+--[a-z-]+(=[^ ;&|]+)?)*\s+commit\b[^;&|]*\s-[a-z]*n[a-z]*(\s|$)'

MOTIVO=""
primeiro_que_casa() {   # primeiro_que_casa OPÇÃO_DO_GREP PADRÃO...: só roda quando algum casou
  local opcao=$1 p; shift
  for p in "$@"; do
    if grep -q"$opcao" -- "$p" <<< "$COMANDO"; then MOTIVO="padrão: $p"; return; fi
  done
}

printf -v JUNTO '(%s)|' "${COM_CAIXA[@]}"
grep -qE -- "${JUNTO%|}" <<< "$COMANDO" && primeiro_que_casa E "${COM_CAIXA[@]}"
if [ -z "$MOTIVO" ]; then
  printf -v JUNTO '(%s)|' "${SEM_CAIXA[@]}"
  grep -qiE -- "${JUNTO%|}" <<< "$COMANDO" && primeiro_que_casa iE "${SEM_CAIXA[@]}"
fi

shopt -s nocasematch
if [ -z "$MOTIVO" ] && [[ $COMANDO == *git* ]] && [[ $COMANDO == *commit* || $COMANDO == *no-veri* ]]; then
  SEM_ASPAS=$(sed -E "s/\"([^\"\\\\]|\\\\.)*\"//g; s/'[^']*'//g" <<< "$COMANDO")
  grep -qiE -- "$RE_SEM_TRAVA" <<< "$SEM_ASPAS" && MOTIVO="commit sem a trava do kit (--no-verify ou -n)"
fi
if [ -z "$MOTIVO" ] && [[ $COMANDO == *-r* ]] \
  && grep -qiE -- "$RE_APAGAR" <<< "$COMANDO" && grep -qiE -- "$RE_ALVO_SISTEMA" <<< "$COMANDO"; then
  MOTIVO="apagar com -Recurse a partir de um drive ou de pasta do sistema"
fi
if [ -z "$MOTIVO" ] && [[ $COMANDO == *core.hookspath* ]] \
  && grep -qiE "core\.hookspath\s+$Q?[./~\$a-z]" <<< "$COMANDO" \
  && ! grep -qiE "core\.hookspath\s+$Q?\.\./\.claude/git-hooks$Q?(\s|\$|[;&|])" <<< "$COMANDO"; then
  MOTIVO="core.hooksPath só pode apontar para ../.claude/git-hooks, a trava de commit do kit"
fi
if [ -z "$MOTIVO" ] && [[ $COMANDO == *parametros* ]] \
  && grep -qiE "(privado|projeto_documento)[\\\\/]+parametros" <<< "$COMANDO" \
  && grep -qiE -- "$RE_LEITURA" <<< "$COMANDO"; then
  MOTIVO="$PASTA_PRIVADO/parametros/ é do usuário: o Claude não lê, não copia nem mostra o que está lá (listar pode)"
fi
# Etapa em "Fazendo" (com sessão ou aguardando uma data) ainda vai voltar à própria branch.
if [ -z "$MOTIVO" ] && [[ $COMANDO == *branch* ]] && [ -f "$RAIZ/$PASTA_PRIVADO/QUADRO.md" ] \
  && grep -qiE -- '\bbranch\b[^;&|]*\s(-d|--delete)\b' <<< "$COMANDO"; then
  FAZENDO=$(tr -d '\r' < "$RAIZ/$PASTA_PRIVADO/QUADRO.md" | awk '/^## /{f=($0 ~ /^## Fazendo/)} f')
  for B in $(grep -oiE 'ciclo-[0-9]+-etapa-[0-9]+' <<< "$COMANDO"); do
    [[ $B =~ ^ciclo-0*([0-9]+)-etapa-0*([0-9]+)$ ]] || continue
    if grep -qiE -- "ciclo ${BASH_REMATCH[1]}, etapa ${BASH_REMATCH[2]}([^0-9]|\$)|$B([^0-9]|\$)" <<< "$FAZENDO"; then
      MOTIVO="a etapa da branch $B está em \"Fazendo\" no quadro (com sessão ou aguardando): a branch ainda vai ser usada"
      break
    fi
  done
fi
shopt -u nocasematch

[ -n "$MOTIVO" ] || exit 0
negar_ferramenta "Comando bloqueado pelo kit ($MOTIVO). Se for intencional, peça ao usuário que rode ele mesmo."
