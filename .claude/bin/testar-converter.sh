#!/usr/bin/env bash
# Autoteste do converter.sh em pastas temporárias. Não toca no kit nem em projeto real.
# Uso: bash .claude/bin/testar-converter.sh

KIT=$(cd "$(dirname "$0")/../.." && pwd)
BASE=$(mktemp -d)
trap 'rm -rf "$BASE"' EXIT
FALHAS=0

ok() { echo "ok    $1"; }
falha() { echo "FALHA $1"; FALHAS=$((FALHAS + 1)); }
checar() { if eval "$2"; then ok "$1"; else falha "$1"; fi; }

novo_kit() {
  K="$BASE/$1"
  mkdir -p "$K/.claude" "$K/Projeto_Documento" "$K/conversor"
  cp -r "$KIT/.claude/hooks" "$KIT/.claude/bin" "$KIT/.claude/git-hooks" "$K/.claude/"
  cp -r "$KIT/Projeto" "$K/Projeto"
  C="$K/.claude/bin/converter.sh"
}

novo_repo() {
  git init -q -b "$2" "$1"
  git -C "$1" config user.email teste@exemplo.invalid
  git -C "$1" config user.name teste
}

# --- Projeto com o kit antigo: código em Projeto/, documentos e chave fora dele ---
novo_kit kit1
O="$K/conversor/antigo"
mkdir -p "$O/Projeto/src" "$O/Projeto_Documento/decisoes" "$O/Projeto_Documento/sensivel" "$O/.claude/skills/velha"
novo_repo "$O/Projeto" master
printf 'bin/\n' > "$O/Projeto/.gitignore"
echo 'class A {}' > "$O/Projeto/src/A.cs"
mkdir "$O/Projeto/bin"; echo gerado > "$O/Projeto/bin/x.dll"
git -C "$O/Projeto" add -A; git -C "$O/Projeto" commit -qm inicial
ORIGEM_HEAD=$(git -C "$O/Projeto" rev-parse HEAD)
echo regra > "$O/CLAUDE.md"
echo skill > "$O/.claude/skills/velha/SKILL.md"
echo decisao > "$O/Projeto_Documento/decisoes/001.md"
echo chave > "$O/Projeto_Documento/sensivel/segredos.json"

echo 'alterado' >> "$O/Projeto/src/A.cs"
bash "$C" preparar >/dev/null 2>&1; checar "código sem commit para a conversão" '[ $? -eq 2 ]'
git -C "$O/Projeto" checkout -q -- src/A.cs

checar "preparar roda com o git limpo" 'bash "$C" preparar >/dev/null'
checar "CLAUDE.md antigo foi renomeado" '[ -f "$O/CLAUDE.md.antigo" ] && [ ! -e "$O/CLAUDE.md" ]'
checar ".claude antigo foi renomeado" '[ -d "$O/.claude.antigo" ] && [ ! -e "$O/.claude" ]'
checar "preparar pode rodar de novo" 'bash "$C" preparar >/dev/null'
checar "plano roda e não copia" 'bash "$C" plano >/dev/null && [ ! -e "$K/Projeto/.git" ]'
bash "$C" plano --incluir bin >/dev/null
checar "copiar roda" 'bash "$C" copiar >/dev/null'
checar "commit é o mesmo da origem" '[ "$(git -C "$K/Projeto" rev-parse HEAD)" = "$ORIGEM_HEAD" ]'
checar "branch atual é mantida" '[ "$(git -C "$K/Projeto" symbolic-ref --short HEAD)" = master ]'
checar "código chegou" '[ -f "$K/Projeto/src/A.cs" ]'
checar "item ignorado não veio" '[ ! -e "$K/Projeto/bin" ]'
checar "gitignore do projeto foi mantido" 'grep -Fxq "bin/" "$K/Projeto/.gitignore"'
checar "gitignore recebeu as regras do kit" 'grep -Fxq "segredo.json" "$K/Projeto/.gitignore"'
checar "trava de commit ligada" '[ "$(git -C "$K/Projeto" config core.hooksPath)" = ../.claude/git-hooks ]'
checar "decisão foi guardada" '[ -f "$K/Projeto_Documento/origem/Projeto_Documento/decisoes/001.md" ]'
checar "instrução antiga guardada com .antigo" '[ -f "$K/Projeto_Documento/origem/CLAUDE.md.antigo" ]'
checar "chave não foi guardada" '! find "$K/Projeto_Documento/origem" -name "segredos.json" | grep -q .'
checar "chave não foi para o código" '! find "$K/Projeto" -name "segredos.json" | grep -q .'
checar "segunda cópia é recusada" '! bash "$C" copiar >/dev/null 2>&1'

# --- Repositório na raiz, com pasta ignorada e documento versionado ---
novo_kit kit2
O="$K/conversor/raiz"
mkdir -p "$O/Lib" "$O/Pesado"
novo_repo "$O" main
printf 'Pesado/\n' > "$O/.gitignore"
echo codigo > "$O/Lib/B.cs"; echo notas > "$O/Lib/notas.md"; echo grande > "$O/Pesado/x.bin"; echo doc > "$O/Pesado/y.md"
git -C "$O" add -A; git -C "$O" commit -qm inicial
bash "$C" preparar >/dev/null
checar "--incluir com sensível é recusado" '! (echo k > "$O/Pesado/a.pem"; bash "$C" plano --incluir Pesado >/dev/null 2>&1)'
rm "$O/Pesado/a.pem"
checar "copiar com --excluir roda" 'bash "$C" copiar --excluir Pesado >/dev/null'
checar "documento do código foi guardado" '[ -f "$K/Projeto_Documento/origem/Lib/notas.md" ]'
checar "--excluir vale para a guarda" '[ ! -e "$K/Projeto_Documento/origem/Pesado" ]'

# --- Sem git, com pastas geradas e um arquivo sensível ---
novo_kit kit3
O="$K/conversor/jogo"
mkdir -p "$O/Assets" "$O/Library/cache" "$O/config"
echo script > "$O/Assets/C.cs"; echo gerado > "$O/Library/cache/z.bin"; echo doc > "$O/LEIA.md"
echo chave > "$O/config/app.pfx"
bash "$C" preparar >/dev/null
bash "$C" plano >/dev/null 2>&1; checar "sem git exige o repositório criado antes" '[ $? -eq 1 ]'
git -C "$K/Projeto" init -q -b main
printf 'Library/\n' >> "$K/Projeto/.gitignore"
checar "copiar sem git roda" 'bash "$C" copiar >/dev/null'
checar "código sem git chegou" '[ -f "$K/Projeto/Assets/C.cs" ]'
checar "pasta gerada não veio" '[ ! -e "$K/Projeto/Library" ]'
checar "arquivo sensível não veio" '[ ! -e "$K/Projeto/config/app.pfx" ]'
checar "documento foi guardado, não copiado" '[ -f "$K/Projeto_Documento/origem/LEIA.md" ] && [ ! -e "$K/Projeto/LEIA.md" ]'

# --- Recusas ---
novo_kit kit4
checar "conversor vazio é recusado" '! bash "$C" preparar >/dev/null 2>&1'
mkdir "$K/conversor/a" "$K/conversor/b"
checar "dois projetos são recusados" '! bash "$C" preparar >/dev/null 2>&1'
rm -r "$K/conversor/b"; mkdir -p "$K/conversor/a/x" "$K/conversor/a/y"
novo_repo "$K/conversor/a/x" main; novo_repo "$K/conversor/a/y" main
checar "dois repositórios são recusados" '! bash "$C" preparar >/dev/null 2>&1'

echo
if [ "$FALHAS" -eq 0 ]; then echo "Todos os testes passaram."; else echo "$FALHAS teste(s) falharam."; exit 1; fi
