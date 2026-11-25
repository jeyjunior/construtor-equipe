#!/usr/bin/env bash
# Subagente pela CLI: roda a tarefa num processo `claude -p`, com o login atual da CLI.
# Uso: bash .claude/bin/subagente-cli.sh status
#      bash .claude/bin/subagente-cli.sh mcp
#      bash .claude/bin/subagente-cli.sh rodar <modelo> <esforço> [--mcp] [--verificar] [ferramenta...] < prompt
#      bash .claude/bin/subagente-cli.sh regras | instrucoes | ferramentas [--verificar]   (o que a chamada recebe)
# Outra configuração da CLI (outro login): $CONSTRUTOR_CLI_CONFIG com a pasta dela. Nada é gravado nela.
# Regra de uso: .claude/skills/construtor-subagente/SKILL.md.

set -u
CONFIG="${CONSTRUTOR_CLI_CONFIG:-}"
GLOBAL="${CONSTRUTOR_CLAUDE_GLOBAL:-$HOME/.claude}"
RAIZ=$(cd "$(dirname "$0")/../.." && pwd)
MODELOS_CONHECIDOS="haiku sonnet opus fable"
ESFORCOS="low medium high xhigh max"

# O processo herda variáveis da sessão do app (sessão, conectores); sem limpar, a CLI se mistura com ela.
limpo() {
  local fora=() v
  for v in $(env | grep -oE '^(CLAUDE|ANTHROPIC|MCP_)[A-Za-z0-9_]*'); do fora+=(-u "$v"); done
  if [ -n "$CONFIG" ]; then env "${fora[@]}" CLAUDE_CONFIG_DIR="$CONFIG" "$@"; else env "${fora[@]}" "$@"; fi
}

status() {
  command -v claude >/dev/null 2>&1 || { echo ausente; return; }
  [ -z "$CONFIG" ] || [ -d "$CONFIG" ] || { echo ausente; return; }
  command -v jq >/dev/null 2>&1 || { echo sem-jq; return; }
  [ "$(limpo claude auth status 2>/dev/null | jq -r '.loggedIn // false')" = true ] && echo ok || echo sem-login
}

# Saída: <prefixo das ferramentas> <conectado|desconectado> <nome do servidor>.
# Conector do claude.ai vira mcp__claude_ai_<Nome>; servidor da própria CLI vira mcp__<nome>.
mcp() {
  limpo claude mcp list 2>/dev/null | tr -d '\r' | awk '
    index($0, ": ") == 0 { next }
    {
      nome = substr($0, 1, index($0, ": ") - 1)
      estado = ($0 ~ /Connected[[:space:]]*$/) ? "conectado" : "desconectado"
      base = nome
      if (sub(/^claude\.ai /, "", base)) base = "claude_ai_" base
      gsub(/[^A-Za-z0-9_-]/, "_", base)
      print "mcp__" base " " estado " " nome
    }'
}

# No modo -p ninguém confirma: o "ask" do projeto vira "deny", para um --allowedTools largo não liberar
# o que aqui pede confirmação. Com outra configuração da CLI, os hooks globais desta máquina vão junto.
regras() {
  local globais='{}'
  [ -n "$CONFIG" ] && [ -f "$GLOBAL/settings.json" ] && globais=$(jq '.hooks // {}' "$GLOBAL/settings.json")
  jq -c --argjson g "$globais" '
    .permissions.deny = ((.permissions.deny // []) + (.permissions.ask // []))
    | del(.permissions.ask)
    | .hooks = reduce ($g | keys[]) as $k ((.hooks // {}); .[$k] = ((.[$k] // []) + $g[$k]))
  ' "$RAIZ/.claude/settings.json"
}

carregar_conf() {
  BUILD="" TESTE="" SUBAGENTES_MODELOS="" SUBAGENTES_ESFORCO_MAX=""
  # shellcheck disable=SC1090
  [ -f "$RAIZ/.claude/comandos.conf" ] && source <(tr -d '\r' < "$RAIZ/.claude/comandos.conf")
  LIBERADOS="${SUBAGENTES_MODELOS:-haiku sonnet opus}"
  TETO="${SUBAGENTES_ESFORCO_MAX:-high}"
}

# Git de leitura sempre; com --verificar, o BUILD e o TESTE de comandos.conf exatamente como estão lá.
# Cada regra vai para Bash e PowerShell: no Windows a CLI pode usar qualquer das duas ferramentas.
ferramentas() {
  local c comandos=()
  for c in status diff log show ls-files rev-parse "branch --list" "config --get"; do comandos+=("git -C projeto $c *"); done
  if [ "${1:-}" = "--verificar" ]; then
    carregar_conf
    for c in "$BUILD" "$TESTE"; do [ -z "$c" ] || comandos+=("$c"); done
  fi
  printf '%s\n' Read Glob Grep WebSearch WebFetch
  for c in "${comandos[@]}"; do printf 'Bash(%s)\nPowerShell(%s)\n' "$c" "$c"; done
}

# A chamada roda sem as configurações do projeto, e com isso o Claude não carrega nenhum CLAUDE.md: vão todos aqui.
instrucoes() {
  local f
  for f in "$GLOBAL/CLAUDE.md" "$RAIZ/CLAUDE.md" "$RAIZ"/.claude/rules/*.md; do
    [ -f "$f" ] && printf '\n# Instruções de %s\n\n%s\n' "$f" "$(cat "$f")"
  done
  printf '\n# Seu papel\n\nVocê é um subagente do kit Construtor Equipe, numa sessão sem usuário. A tarefa vem no pedido de quem disparou. Não pergunte nem espere resposta: o que fugir do pedido, pare e devolva. Responda só com o que o pedido pede.\n\nNesta sessão nada pede confirmação: o que não está liberado é negado. Use a ferramenta Bash, um comando por chamada. Git sempre como `git -C projeto <comando>`, com o caminho relativo: caminho absoluto no `-C` e `cd` antes de git são negados. O BUILD e o TESTE de `.claude/comandos.conf`, quando liberados, rodam exatamente como estão lá, na forma `cd projeto && <comando>`. Comando negado: não tente outra forma; diga na resposta qual foi.\n'
}

posicao() {
  local alvo=$1 i=0 e
  for e in $ESFORCOS; do i=$((i + 1)); [ "$e" = "$alvo" ] && { echo "$i"; return; }; done
  echo 0
}

rodar() {
  local modelo=${1:-} esforco=${2:-} estrito=(--strict-mcp-config) verificar="" lista=()
  shift 2 2>/dev/null || { echo "uso: rodar <modelo> <esforço> [--mcp] [--verificar] [ferramenta...] < prompt" >&2; exit 2; }
  [[ " $MODELOS_CONHECIDOS " == *" $modelo "* ]] || { echo "modelo: $MODELOS_CONHECIDOS" >&2; exit 2; }
  [ "$(posicao "$esforco")" -gt 0 ] || { echo "esforço: $ESFORCOS" >&2; exit 2; }
  carregar_conf
  [[ " $LIBERADOS " == *" $modelo "* ]] || { echo "modelo $modelo fora dos liberados em SUBAGENTES_MODELOS ($LIBERADOS)" >&2; exit 4; }
  [ "$(posicao "$esforco")" -le "$(posicao "$TETO")" ] || { echo "esforço $esforco acima do teto SUBAGENTES_ESFORCO_MAX ($TETO)" >&2; exit 4; }
  while [ "${1:-}" = "--mcp" ] || [ "${1:-}" = "--verificar" ]; do
    if [ "$1" = "--mcp" ]; then estrito=(); else verificar=--verificar; fi
    shift
  done
  local situacao
  situacao=$(status)
  [ "$situacao" = ok ] || { echo "subagente pela CLI indisponível: $situacao" >&2; exit 3; }
  mapfile -t lista < <(ferramentas $verificar)
  cd "$RAIZ" || exit 1
  limpo claude -p --setting-sources user --settings "$(regras)" "${estrito[@]}" \
    --model "$modelo" --effort "$esforco" \
    --append-system-prompt "$(instrucoes)" \
    --allowedTools "${lista[@]}" "$@"
}

case "${1:-}" in
  status) status ;;
  mcp) mcp ;;
  rodar) shift; rodar "$@" ;;
  regras) regras ;;
  instrucoes) instrucoes ;;
  ferramentas) shift; ferramentas "$@" ;;
  *) echo "uso: subagente-cli.sh status | mcp | rodar <modelo> <esforço> [--mcp] [--verificar] [ferramenta...] < prompt | regras | instrucoes | ferramentas [--verificar]" >&2; exit 2 ;;
esac
