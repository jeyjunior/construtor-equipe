#!/usr/bin/env bash
# Conta secundária do Claude Code (CLI) para rodar subagentes fora da conta principal.
# Uso: bash .claude/bin/secundaria.sh status
#      bash .claude/bin/secundaria.sh mcp
#      bash .claude/bin/secundaria.sh rodar <modelo> <esforço> [--mcp] [ferramenta...] < prompt
#      bash .claude/bin/secundaria.sh regras | instrucoes   (o que a chamada recebe, para conferir)
# Pasta da conta: $CONSTRUTOR_CONTA_CLI, ou ~/.claude-secundaria. Nada é gravado nela.
# Regra de uso: .claude/skills/construtor-equipe-subagente/SKILL.md.

set -u
CONTA="${CONSTRUTOR_CONTA_CLI:-$HOME/.claude-secundaria}"
PRINCIPAL="${CONSTRUTOR_CONTA_PRINCIPAL:-$HOME/.claude}"
RAIZ=$(cd "$(dirname "$0")/../.." && pwd)
MODELOS_CONHECIDOS="haiku sonnet opus fable"
ESFORCOS="low medium high xhigh max"

# O processo herda variáveis da sessão do app (conta, sessão, conectores); sem limpar, a CLI se mistura com a principal.
limpo() {
  local fora=() v
  for v in $(env | grep -oE '^(CLAUDE|ANTHROPIC|MCP_)[A-Za-z0-9_]*'); do fora+=(-u "$v"); done
  env "${fora[@]}" CLAUDE_CONFIG_DIR="$CONTA" "$@"
}

status() {
  command -v claude >/dev/null 2>&1 && [ -d "$CONTA" ] || { echo ausente; return; }
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

# Regras do projeto sem "ask" (o modo -p não pergunta: "ask" vira negação), somadas aos hooks globais da principal.
regras() {
  local globais='{}'
  [ -f "$PRINCIPAL/settings.json" ] && globais=$(jq '.hooks // {}' "$PRINCIPAL/settings.json")
  jq -c --argjson g "$globais" '
    del(.permissions.ask)
    | .hooks = reduce ($g | keys[]) as $k ((.hooks // {}); .[$k] = ((.[$k] // []) + $g[$k]))
  ' "$RAIZ/.claude/settings.json"
}

# A chamada roda sem as configurações do projeto, e com isso o Claude não carrega nenhum CLAUDE.md: vão todos aqui.
instrucoes() {
  local f
  for f in "$PRINCIPAL/CLAUDE.md" "$RAIZ/CLAUDE.md" "$RAIZ"/.claude/rules/*.md; do
    [ -f "$f" ] && printf '\n# Instruções de %s\n\n%s\n' "$f" "$(cat "$f")"
  done
  printf '\n# Seu papel\n\nVocê é um subagente do kit Construtor Equipe, numa sessão sem usuário. A tarefa vem no pedido de quem disparou. Não pergunte nem espere resposta: o que fugir do pedido, pare e devolva. Responda só com o que o pedido pede.\n'
}

carregar_limites() {
  SUBAGENTES_MODELOS="" SUBAGENTES_ESFORCO_MAX=""
  # shellcheck disable=SC1090
  [ -f "$RAIZ/.claude/comandos.conf" ] && source <(tr -d '\r' < "$RAIZ/.claude/comandos.conf")
  LIBERADOS="${SUBAGENTES_MODELOS:-haiku sonnet opus}"
  TETO="${SUBAGENTES_ESFORCO_MAX:-high}"
}

posicao() {
  local alvo=$1 i=0 e
  for e in $ESFORCOS; do i=$((i + 1)); [ "$e" = "$alvo" ] && { echo "$i"; return; }; done
  echo 0
}

rodar() {
  local modelo=${1:-} esforco=${2:-} estrito=(--strict-mcp-config)
  shift 2 2>/dev/null || { echo "uso: rodar <modelo> <esforço> [--mcp] [ferramenta...] < prompt" >&2; exit 2; }
  [[ " $MODELOS_CONHECIDOS " == *" $modelo "* ]] || { echo "modelo: $MODELOS_CONHECIDOS" >&2; exit 2; }
  [ "$(posicao "$esforco")" -gt 0 ] || { echo "esforço: $ESFORCOS" >&2; exit 2; }
  carregar_limites
  [[ " $LIBERADOS " == *" $modelo "* ]] || { echo "modelo $modelo fora dos liberados em SUBAGENTES_MODELOS ($LIBERADOS)" >&2; exit 4; }
  [ "$(posicao "$esforco")" -le "$(posicao "$TETO")" ] || { echo "esforço $esforco acima do teto SUBAGENTES_ESFORCO_MAX ($TETO)" >&2; exit 4; }
  if [ "${1:-}" = "--mcp" ]; then estrito=(); shift; fi
  local situacao
  situacao=$(status)
  [ "$situacao" = ok ] || { echo "conta secundária indisponível: $situacao" >&2; exit 3; }
  cd "$RAIZ" || exit 1
  limpo claude -p --setting-sources user --settings "$(regras)" "${estrito[@]}" \
    --model "$modelo" --effort "$esforco" \
    --append-system-prompt "$(instrucoes)" \
    --allowedTools Read Glob Grep WebSearch WebFetch "$@"
}

case "${1:-}" in
  status) status ;;
  mcp) mcp ;;
  rodar) shift; rodar "$@" ;;
  regras) regras ;;
  instrucoes) instrucoes ;;
  *) echo "uso: secundaria.sh status | mcp | rodar <modelo> <esforço> [--mcp] [ferramenta...] < prompt | regras | instrucoes" >&2; exit 2 ;;
esac
