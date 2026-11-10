#!/usr/bin/env bash
# Autoteste das travas do kit (hooks de edição e de comando, e o pre-commit) em pasta temporária.
# Não toca no kit nem em projeto real. Todos os valores de segredo aqui são fictícios.
# Uso: bash .claude/bin/testar-hooks.sh

KIT=$(cd "$(dirname "$0")/../.." && pwd)
BASE=$(mktemp -d)
trap 'rm -rf "$BASE"' EXIT
FALHAS=0
K="$BASE/kit"
P="$K/projeto"

ok() { echo "ok    $1"; }
falha() { echo "FALHA $1"; FALHAS=$((FALHAS + 1)); }

mkdir -p "$K/.claude" "$K/privado/parametros" "$K/conversor"
cp -r "$KIT/.claude/hooks" "$KIT/.claude/git-hooks" "$KIT/.claude/comandos.conf" "$K/.claude/"
cp -r "$KIT/projeto" "$P"

# editar ARQUIVO [CONTEUDO_JSON]: saída do hook dado em $HOOK para uma edição do arquivo (relativo ao Root).
editar() {
  printf '{"session_id":"s1","tool_input":{"file_path":"%s","content":"%s"}}' "$K/$1" "${2:-x}" \
    | CLAUDE_PROJECT_DIR="$K" bash "$K/.claude/hooks/$HOOK"
}
nega()    { if editar "$2" "${3:-x}" | grep -q '"deny"'; then ok "$1"; else falha "$1"; fi; }
permite() { if editar "$2" "${3:-x}" | grep -q '"deny"'; then falha "$1"; else ok "$1"; fi; }
git_p() { git -C "$P" "$@" >/dev/null 2>&1; }

# --- Estrutura do Root -----------------------------------------------------------------------
HOOK=proteger-estrutura.sh
nega    "arquivo solto no Root é negado"            "solto.txt"
nega    "sensível em projeto/ é negado"             "projeto/.env"
nega    "privado/parametros/ é negado"              "privado/parametros/parametro.json"
nega    "quadro em projeto/ é negado"               "projeto/QUADRO.md"
nega    "documento .md em projeto/ é negado"        "projeto/src/notas.md"
nega    "pasta docs/ em projeto/ é negada"          "projeto/docs/guia.txt"
permite "README da raiz de projeto/ é liberado"     "projeto/README.md"
permite "sem repositório, o quadro é liberado"      "privado/QUADRO.md"
permite "privado/origem/ é liberado"                "privado/origem/nota.md"
permite "o kit é liberado"                          ".claude/rules/projeto.md"
permite "sem repositório, código é liberado"        "projeto/src/A.cs"

# --- Papéis pela branch ----------------------------------------------------------------------
git -C "$P" init -q -b main
git_p config user.email teste@exemplo.invalid; git_p config user.name teste
git_p config core.hooksPath ../.claude/git-hooks
git_p add -A; git_p commit -m "Adicao: arquivos iniciais"
nega    "na principal, código é negado"             "projeto/src/A.cs"
permite "na principal, o README é liberado"         "projeto/README.md"
permite "na principal, o quadro é liberado"         "privado/QUADRO.md"
permite "na principal, docs/ é liberado"            "privado/docs/objetivo.md"
git_p switch -c ciclo-01
nega    "na branch do ciclo, código é negado"       "projeto/src/A.cs"
permite "na branch do ciclo, o quadro é liberado"   "privado/QUADRO.md"
git_p switch -c ciclo-01-etapa-01
permite "na branch da etapa, código é liberado"     "projeto/src/A.cs"
permite "na branch da etapa, docs/ é liberado"      "privado/docs/ciclos/01-x/etapas/01-y.md"
nega    "na branch da etapa, o quadro é negado"     "privado/QUADRO.md"
git_p switch -c curto-003 main
permite "na branch de ciclo curto, código é liberado"      "projeto/src/A.cs"
nega    "na branch de ciclo curto, o quadro é negado"      "privado/QUADRO.md"

# Merge com conflito na branch do ciclo: o código fica liberado para resolver.
mkdir -p "$P/src"; echo um > "$P/src/A.cs"; git_p add -A; git_p commit -m "Adicao: A"
git_p switch ciclo-01-etapa-01; mkdir -p "$P/src"; echo dois > "$P/src/A.cs"; git_p add -A; git_p commit -m "Adicao: A"
git_p switch ciclo-01; git_p merge --no-ff ciclo-01-etapa-01
git_p merge curto-003
permite "com merge em andamento, código é liberado" "projeto/src/A.cs"
git_p merge --abort

# --- Segredos no conteúdo (valores fictícios) ------------------------------------------------
HOOK=bloquear-segredos.sh
nega    "segredo em JSON (dois-pontos) é negado"    "projeto/src/app.json" '{\"ApiKey\": \"abcdef1234567890XYZ\"}'
nega    "senha em português é negada"               "projeto/src/A.cs"     'var senha = \"SuperFicticia123\";'
nega    "segredo em YAML é negado"                  "projeto/src/a.yml"    'password: \"SuperFicticia123\"'
nega    "senha em connection string é negada"       "projeto/src/A.cs"     'Server=x;Password=Ficticia123;'
permite "valor vazio é liberado"                    "projeto/parametro.exemplo.json" '{\"ApiKey\": \"\"}'
permite "documento .md é liberado"                  "privado/docs/nota.md" 'ApiKey = \"abcdef1234567890XYZ\"'
permite "código comum é liberado"                   "projeto/src/A.cs"     'var nome = \"valor qualquer\";'

# --- Comandos destrutivos --------------------------------------------------------------------
comando() {
  printf '{"tool_input":{"command":"%s"}}' "$1" | CLAUDE_PROJECT_DIR="$K" bash "$K/.claude/hooks/bloquear-comandos.sh"
}
if comando "rm -rf /" | grep -q '"deny"'; then ok "rm -rf / é negado"; else falha "rm -rf / é negado"; fi
if comando "git -C projeto status" | grep -q '"deny"'; then falha "git status é liberado"; else ok "git status é liberado"; fi

# --- Trava de commit -------------------------------------------------------------------------
git_p switch main
mkdir -p "$P/src"; echo x > "$P/src/B.cs"; git_p add -A
if git_p commit -m "Adicao: B"; then falha "código direto na principal é recusado"; else ok "código direto na principal é recusado"; fi
git_p restore --staged .; rm "$P/src/B.cs"
echo "# Projeto" > "$P/README.md"; git_p add -A
if git_p commit -m "Docs: README"; then ok "README direto na principal é aceito"; else falha "README direto na principal é aceito"; fi
git_p switch ciclo-01-etapa-01
echo 'class B {}' > "$P/src/B.cs"; git_p add -A
if git_p commit -m "Adicao: B"; then ok "código na branch da etapa é aceito"; else falha "código na branch da etapa é aceito"; fi
echo '{"ApiKey": "abcdef1234567890XYZ"}' > "$P/src/app.json"; git_p add -A
if git_p commit -m "Adicao: app"; then falha "commit com segredo é recusado"; else ok "commit com segredo é recusado"; fi
git_p restore --staged .; rm "$P/src/app.json"
echo nota > "$P/src/notas.md"; git_p add -f src/notas.md
if git_p commit -m "Adicao: notas"; then falha "commit com documentação é recusado"; else ok "commit com documentação é recusado"; fi
git_p restore --staged .; rm "$P/src/notas.md"
echo chave > "$P/src/cert.pfx"; git_p add -f src/cert.pfx
if git_p commit -m "Adicao: cert"; then falha "commit com arquivo sensível é recusado"; else ok "commit com arquivo sensível é recusado"; fi

echo
command -v jq >/dev/null 2>&1 && echo "(rodou com jq)" || echo "(rodou sem jq: modo menos preciso)"
if [ "$FALHAS" -eq 0 ]; then echo "Todos os testes passaram."; else echo "$FALHAS teste(s) falharam."; exit 1; fi
