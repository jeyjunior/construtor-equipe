#!/usr/bin/env bash
# Autoteste das travas do kit (hooks de edição e de comando, e o pre-commit) em pasta temporária.
# Não toca no kit nem em projeto real. Todos os valores de segredo aqui são fictícios.
# Uso: bash .claude/bin/testar-hooks.sh

DIR_KIT=$(cd "$(dirname "$0")/.." && pwd)
BASE=$(mktemp -d)
trap 'rm -rf "$BASE"' EXIT
FALHAS=0
K="$BASE/kit"
P="$K/projeto"

ok() { echo "ok    $1"; }
falha() { echo "FALHA $1"; FALHAS=$((FALHAS + 1)); }

# Projeto, comandos e quadro próprios do teste: num projeto real, projeto/ tem o repositório de
# verdade, numa branch qualquer, e o comandos.conf é do projeto. Do kit vêm só as travas.
mkdir -p "$K/.claude" "$K/privado/parametros" "$K/conversor" "$P"
cp -r "$DIR_KIT/hooks" "$DIR_KIT/git-hooks" "$DIR_KIT/bin" "$K/.claude/"
cp "$DIR_KIT/settings.json" "$K/.claude/"
printf 'BRANCH_PRINCIPAL="main"\n' > "$K/.claude/comandos.conf"
printf '*.md\n!/README.md\n!/CHANGELOG.md\n' > "$P/.gitignore"

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
permite "CHANGELOG da raiz de projeto/ é liberado"  "projeto/CHANGELOG.md"
permite "nota de versão da raiz é liberada"         "projeto/release_2.4.0.md"
nega    "CHANGELOG fora da raiz é negado"           "projeto/src/CHANGELOG.md"
nega    "arquivo de conexão em projeto/ é negado"   "projeto/testes/mysql.connection"
permite "sem repositório, o quadro é liberado"      "privado/QUADRO.md"
permite "privado/origem/ é liberado"                "privado/origem/nota.md"
permite "o kit é liberado"                          ".claude/rules/projeto.md"
permite "sem repositório, código é liberado"        "projeto/src/A.cs"
nega    ".. não fura privado/parametros/"           "privado/docs/../parametros/parametro.json"
nega    ".. a partir do kit não fura parametros/"   ".claude/../privado/parametros/x.json"
nega    ".. não solta arquivo no Root"              "projeto/../solto.txt"

# Caminho no formato do Git Bash (/c/...) com o Root no formato do Windows (C:\...).
if command -v cygpath >/dev/null 2>&1; then
  KW=$(cygpath -w "$K"); KM=$(cygpath -m "$K"); KU="/$(printf %s "${KM:0:1}" | tr '[:upper:]' '[:lower:]')${KM:2}"
  bruto() { printf '{"session_id":"s1","tool_input":{"file_path":"%s","content":"x"}}' "$KU/$1" \
    | CLAUDE_PROJECT_DIR="$KW" bash "$K/.claude/hooks/$HOOK" | grep -q '"deny"'; }
  if bruto "solto.txt"; then ok "/c/... com Root C:\\ nega arquivo solto"; else falha "/c/... com Root C:\\ nega arquivo solto"; fi
  if bruto "projeto/.env"; then ok "/c/... com Root C:\\ nega sensível"; else falha "/c/... com Root C:\\ nega sensível"; fi
fi

# --- Papéis pela branch ----------------------------------------------------------------------
git -C "$P" init -q -b main
git_p config user.email teste@exemplo.invalid; git_p config user.name teste
git_p config core.hooksPath ../.claude/git-hooks
git_p add -A; git_p commit -m "Adicao: arquivos iniciais"
nega    "na principal, código é negado"             "projeto/src/A.cs"
permite "na principal, o README é liberado"         "projeto/README.md"
permite "na principal, o CHANGELOG é liberado"      "projeto/CHANGELOG.md"
permite "na principal, a nota release_X.txt é liberada" "projeto/release_2.4.0.txt"
permite "na principal, o quadro é liberado"         "privado/QUADRO.md"
permite "na principal, docs/ é liberado"            "privado/docs/objetivo.md"
git_p switch -c ciclo-01
nega    "na branch do ciclo, código é negado"       "projeto/src/A.cs"
permite "na branch do ciclo, o quadro é liberado"   "privado/QUADRO.md"
git_p switch -c ciclo-01-etapa-01
permite "na branch da etapa, código é liberado"     "projeto/src/A.cs"
permite "na branch da etapa, docs/ é liberado"      "privado/docs/ciclos/01-x/etapas/01-y.md"
permite "na branch da etapa, o gerente (sem código editado) edita o quadro" "privado/QUADRO.md"
mkdir -p "$K/.claude/.cache"; : > "$K/.claude/.cache/editou-s1"
nega    "na branch da etapa, a sessão que editou código não edita o quadro" "privado/QUADRO.md"
git_p switch -c curto-003 main
permite "na branch de ciclo curto, código é liberado"      "projeto/src/A.cs"
nega    "na branch de ciclo curto, a sessão que editou código não edita o quadro" "privado/QUADRO.md"
rm -f "$K/.claude/.cache/editou-s1"
git_p switch -c release/1.0.0 main
nega    "na branch de release, código é negado"     "projeto/src/A.cs"
permite "na branch de release, o CHANGELOG é liberado" "projeto/CHANGELOG.md"
git_p switch curto-003

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
nega    "senha em YAML sem aspas é negada"          "projeto/src/a.yml"    'password: SuperFicticia123'
permite "variável em YAML é liberada"               "projeto/src/a.yml"    'password: ${SENHA_DO_BANCO}'
permite "anotação de tipo em código é liberada"     "projeto/src/a.ts"     'password: SenhaCriptografada'
nega    "JWT é negado"                              "projeto/src/A.cs"     'var t = \"eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJmaWN0aWNpbyJ9.ZmljdGljaW9maWN0aWNpbw\";'
nega    "chave de API em português é negada"        "projeto/src/A.cs"     'var chaveApi = \"Ficticia1234567890\";'
nega    "AccessKey literal é negada"                "projeto/src/A.cs"     'AccessKey = \"Ficticia1234567890\"'
permite "chave de dicionário é liberada"            "projeto/src/A.cs"     'var chave = \"Concurso:3830\";'
if printf '{"tool_input":{"file_path":"/c/Windows/x.txt","content":"x"}}' \
  | CLAUDE_PROJECT_DIR="$K" bash "$K/.claude/hooks/$HOOK" | grep -q '"deny"'; then
  ok "local de sistema no formato do Git Bash (/c/Windows) é negado"
else
  falha "local de sistema no formato do Git Bash (/c/Windows) é negado"
fi

# --- Comandos --------------------------------------------------------------------------------
comando() {
  printf '{"tool_input":{"command":"%s","description":"%s"}}' "$1" "${2:-}" \
    | CLAUDE_PROJECT_DIR="$K" bash "$K/.claude/hooks/bloquear-comandos.sh"
}
nega_cmd()    { if comando "$1" | grep -q '"deny"'; then ok "nega: $1"; else falha "nega: $1"; fi; }
permite_cmd() { if comando "$1" | grep -q '"deny"'; then falha "permite: $1"; else ok "permite: $1"; fi; }
nega_cmd    'rm -rf /'
nega_cmd    'rm -Rf /'
nega_cmd    'rm -r -f /'
nega_cmd    'rm --no-preserve-root -rf /'
nega_cmd    'rm / -rf'
nega_cmd    'Remove-Item C:\\ -Recurse -Force'
nega_cmd    'Remove-Item -Recurse C:\\'
nega_cmd    'git commit --no-verify -m x'
nega_cmd    'git -c core.hooksPath=/dev/null commit -m x'
nega_cmd    'git -C projeto config core.hooksPath /dev/null'
nega_cmd    'git config --unset core.hooksPath'
nega_cmd    'cat privado/parametros/parametro.json'
nega_cmd    'Get-Content privado\\parametros\\parametro.json'
nega_cmd    'type privado\\parametros\\parametro.json'
nega_cmd    '$x | iex'
permite_cmd 'git -C projeto status'
permite_cmd 'rm -rf ./bin'
permite_cmd 'git rm -r --cached docs/'
permite_cmd 'Remove-Item -Recurse -Force .\\bin'
permite_cmd 'git -C projeto config core.hooksPath ../.claude/git-hooks'
permite_cmd 'ls privado/parametros'
permite_cmd 'Test-Path privado\\parametros\\parametro.json'
permite_cmd 'grep -rn \"Invoke-Expression\" src'
nega_cmd    'git -C projeto commit -n -m x'
permite_cmd 'git -C projeto commit -m \"Adicao: opcao -n de linha\"'
permite_cmd 'git -C projeto commit -m \"Docs: explica por que nunca usar --no-verify\"'
nega_cmd    'git -C projeto commit -nm \"Adicao: x\"'
nega_cmd    'git -C projeto commit -anm \"x\"'
nega_cmd    'git -C projeto commit --no-verif -m \"x\"'
permite_cmd 'git -C projeto log --grep commit -n 5'
printf '# Quadro\n\n## Fazendo\n- #007 [resultados] Ciclo 1, etapa 8 — x — aguardando até 2026-11-25, sem sessão\n\n## Feito\n- #006 [deploy] Ciclo 1, etapa 7 — y — 2026-11-15\n' > "$K/privado/QUADRO.md"
nega_cmd    'git -C projeto branch -d ciclo-01-etapa-08'
nega_cmd    'git -C projeto branch -D ciclo-01-etapa-08'
permite_cmd 'git -C projeto branch -d ciclo-01-etapa-07'
permite_cmd 'git -C projeto branch -d ciclo-01-etapa-18'
rm -f "$K/privado/QUADRO.md"

# Sem jq, a descrição (texto livre) não conta.
SEM_JQ=""
IFS=: read -r -a DIRS <<< "$PATH"
for d in "${DIRS[@]}"; do [ -x "$d/jq" ] || [ -x "$d/jq.exe" ] || SEM_JQ="${SEM_JQ:+$SEM_JQ:}$d"; done
if PATH="$SEM_JQ" command -v sed >/dev/null && PATH="$SEM_JQ" command -v grep >/dev/null \
  && ! PATH="$SEM_JQ" command -v jq >/dev/null; then
  sem_jq() { printf '{"tool_input":{"command":"%s","description":"%s"}}' "$1" "$2" \
    | PATH="$SEM_JQ" CLAUDE_PROJECT_DIR="$K" bash "$K/.claude/hooks/bloquear-comandos.sh"; }
  if sem_jq 'git -C projeto status' 'antes de Invoke-Expression' | grep -q '"deny"'; then
    falha "sem jq, a descrição não nega o comando"; else ok "sem jq, a descrição não nega o comando"; fi
  if sem_jq 'rm -rf /' 'limpeza' | grep -q '"deny"'; then
    ok "sem jq, rm -rf / continua negado"; else falha "sem jq, rm -rf / continua negado"; fi
fi

# --- Limpeza do cache ------------------------------------------------------------------------
mkdir -p "$K/.claude/.cache"
: > "$K/.claude/.cache/editou-velha"; touch -d '40 days ago' "$K/.claude/.cache/editou-velha"
: > "$K/.claude/.cache/editou-nova"
CLAUDE_PROJECT_DIR="$K" bash "$K/.claude/hooks/verificar-ambiente.sh" >/dev/null
if [ ! -e "$K/.claude/.cache/editou-velha" ] && [ -e "$K/.claude/.cache/editou-nova" ]; then
  ok "marca de edição com mais de 30 dias é apagada ao abrir a sessão"
else
  falha "marca de edição com mais de 30 dias é apagada ao abrir a sessão"
fi

# --- Trava de commit -------------------------------------------------------------------------
git_p switch main
mkdir -p "$P/src"; echo x > "$P/src/B.cs"; git_p add -A
if git_p commit -m "Adicao: B"; then falha "código direto na principal é recusado"; else ok "código direto na principal é recusado"; fi
git_p restore --staged .; rm "$P/src/B.cs"
echo "# Projeto" > "$P/README.md"; git_p add -A
if git_p commit -m "Docs: README"; then ok "README direto na principal é aceito"; else falha "README direto na principal é aceito"; fi
echo "# Versões" > "$P/CHANGELOG.md"; git_p add -A
if git_p commit -m "Docs: CHANGELOG"; then ok "CHANGELOG direto na principal é aceito"; else falha "CHANGELOG direto na principal é aceito"; fi
echo x > "$P/a.connection"; git_p add -f a.connection
if git_p commit -m "Adicao: conexao"; then falha "commit com arquivo de conexão é recusado"; else ok "commit com arquivo de conexão é recusado"; fi
git_p restore --staged .; rm -f "$P/a.connection"
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
git_p restore --staged .; rm "$P/src/cert.pfx"
printf 'banco:\n  password: SuperFicticia123\n' > "$P/src/app.yml"; git_p add -A
if git_p commit -m "Adicao: yml"; then falha "commit com senha em YAML sem aspas é recusado"; else ok "commit com senha em YAML sem aspas é recusado"; fi
git_p restore --staged .; rm "$P/src/app.yml"

# Tirar do git o que já entrou (o conserto que o verificar-ambiente.sh manda fazer).
echo chave > "$P/.env"; git_p add -f .env; git_p commit --no-verify -m "Adicao: env por engano"
git_p rm --cached .env
if git_p commit -m "Correcao: tira o .env do git"; then ok "tirar sensível do git (git rm --cached) é aceito"; else falha "tirar sensível do git (git rm --cached) é aceito"; fi
rm -f "$P/.env"
git_p switch main
mkdir -p "$P/src"; echo 'class C {}' > "$P/src/C.cs"; git_p add src/C.cs; git_p commit --no-verify -m "Adicao: C"
git_p rm --cached src/C.cs
if git_p commit -m "Correcao: x"; then falha "apagar código direto na principal é recusado"; else ok "apagar código direto na principal é recusado"; fi
git_p restore --staged .; git_p checkout -- .
git_p switch release/1.0.0
mkdir -p "$P/src"; echo 'class R {}' > "$P/src/R.cs"; git_p add src/R.cs
if [ -z "$(git -C "$P" diff --cached --name-only)" ]; then falha "código direto na branch de release é recusado (nada em stage)"
elif git_p commit -m "Adicao: R"; then falha "código direto na branch de release é recusado"; else ok "código direto na branch de release é recusado"; fi
git_p restore --staged .

# --- Subagente pela CLI (com um claude falso que só mostra o que recebeu) --------------------
SUB="$K/.claude/bin/subagente-cli.sh"
if command -v jq >/dev/null 2>&1; then
  export CONSTRUTOR_CLAUDE_GLOBAL="$BASE/sem-global"
  REGRAS=$(bash "$SUB" regras)
  if jq -e '(.permissions.ask == null) and (.permissions.deny | index("Bash(git push*)"))' <<< "$REGRAS" >/dev/null; then
    ok "subagente pela CLI: o que pede confirmação vira negação"
  else falha "subagente pela CLI: o que pede confirmação vira negação"; fi
  FERR=$(bash "$SUB" ferramentas)
  if grep -Fxq 'Bash(git -C projeto diff *)' <<< "$FERR" && grep -Fxq 'PowerShell(git -C projeto diff *)' <<< "$FERR"; then
    ok "subagente pela CLI: git de leitura liberado no Bash e no PowerShell"
  else falha "subagente pela CLI: git de leitura liberado no Bash e no PowerShell"; fi
  printf 'BUILD="dotnet build X.slnx -nologo"\nTESTE=""\n' >> "$K/.claude/comandos.conf"
  if bash "$SUB" ferramentas --verificar | grep -Fxq 'Bash(dotnet build X.slnx -nologo)' \
    && ! bash "$SUB" ferramentas | grep -Fq 'dotnet build'; then
    ok "subagente pela CLI: --verificar libera o BUILD exato, e só com ele"
  else falha "subagente pela CLI: --verificar libera o BUILD exato, e só com ele"; fi
  mkdir -p "$BASE/falso" "$BASE/outra-cli"
  printf '#!/usr/bin/env bash\nif [ "$1 $2" = "auth status" ]; then echo "{\\"loggedIn\\": true}"; exit 0; fi\necho "config=${CLAUDE_CONFIG_DIR:-}"\nprintf "%%s\\n" "$@"\n' > "$BASE/falso/claude"
  chmod +x "$BASE/falso/claude"
  SAIDA=$(PATH="$BASE/falso:$PATH" CLAUDE_CONFIG_DIR="$BASE/da-sessao" bash "$SUB" rodar haiku low --verificar <<< "tarefa")
  if grep -Fxq 'config=' <<< "$SAIDA" && grep -Fxq 'Bash(dotnet build X.slnx -nologo)' <<< "$SAIDA" && grep -Fxq -- '-p' <<< "$SAIDA"; then
    ok "subagente pela CLI: usa o login atual da CLI por padrão"
  else falha "subagente pela CLI: usa o login atual da CLI por padrão"; fi
  SAIDA=$(PATH="$BASE/falso:$PATH" CONSTRUTOR_CLI_CONFIG="$BASE/outra-cli" bash "$SUB" rodar haiku low <<< "tarefa")
  if grep -Fxq "config=$BASE/outra-cli" <<< "$SAIDA"; then
    ok "subagente pela CLI: outra configuração só quando apontada"
  else falha "subagente pela CLI: outra configuração só quando apontada"; fi
  if PATH="$BASE/falso:$PATH" bash "$SUB" rodar opus max <<< "x" >/dev/null 2>&1; then
    falha "subagente pela CLI: esforço acima do teto é recusado"
  else ok "subagente pela CLI: esforço acima do teto é recusado"; fi
else
  echo "pulado subagente pela CLI (sem jq)"
fi

echo
command -v jq >/dev/null 2>&1 && echo "(rodou com jq)" || echo "(rodou sem jq: modo menos preciso)"
if [ "$FALHAS" -eq 0 ]; then echo "Todos os testes passaram."; else echo "$FALHAS teste(s) falharam."; exit 1; fi
