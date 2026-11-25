#!/usr/bin/env bash
# Autoteste do converter.sh em pastas temporárias. Não toca no kit nem em projeto real.
# Uso: bash .claude/bin/testar-converter.sh

DIR_KIT=$(cd "$(dirname "$0")/.." && pwd)
KIT=$(dirname "$DIR_KIT")
BASE=$(mktemp -d)
trap 'rm -rf "$BASE"' EXIT
FALHAS=0

ok() { echo "ok    $1"; }
falha() { echo "FALHA $1"; FALHAS=$((FALHAS + 1)); }
checar() { if eval "$2"; then ok "$1"; else falha "$1"; fi; }

novo_kit() {
  K="$BASE/$1"
  mkdir -p "$K/.claude" "$K/privado" "$K/conversor"
  cp -r "$DIR_KIT/hooks" "$DIR_KIT/bin" "$DIR_KIT/git-hooks" "$K/.claude/"
  printf 'BRANCH_PRINCIPAL="main"\n' > "$K/.claude/comandos.conf"
  # Só os arquivos de configuração do git: num projeto real, projeto/ tem o repositório de verdade.
  mkdir -p "$K/projeto"
  cp "$KIT/projeto/.gitignore" "$KIT/projeto/.gitattributes" "$K/projeto/" 2>/dev/null
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
mkdir -p "$O/Projeto/src" "$O/Projeto_Documento/decisoes" "$O/Projeto_Documento/sensivel" "$O/Projeto_Documento/parametros" "$O/.claude/skills/velha"
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
echo chave > "$O/Projeto_Documento/parametros/parametro.json"
mkdir "$O/Lixo"; echo grande > "$O/Lixo/x.bin"

echo 'alterado' >> "$O/Projeto/src/A.cs"
bash "$C" preparar >/dev/null 2>&1; checar "código sem commit para a conversão" '[ $? -eq 2 ]'
git -C "$O/Projeto" checkout -q -- src/A.cs

checar "preparar roda com o git limpo" 'bash "$C" preparar >/dev/null'
checar "CLAUDE.md antigo foi renomeado" '[ -f "$O/CLAUDE.md.antigo" ] && [ ! -e "$O/CLAUDE.md" ]'
checar ".claude antigo foi renomeado" '[ -d "$O/.claude.antigo" ] && [ ! -e "$O/.claude" ]'
checar "preparar pode rodar de novo" 'bash "$C" preparar >/dev/null'
checar "plano roda e não copia" 'bash "$C" plano >/dev/null && [ ! -e "$K/projeto/.git" ]'
bash "$C" plano --incluir bin >/dev/null
checar "copiar roda" 'bash "$C" copiar --excluir Lixo >/dev/null'
checar "--excluir vale para a guarda" '[ ! -e "$K/privado/origem/Lixo" ]'
checar "commit é o mesmo da origem" '[ "$(git -C "$K/projeto" rev-parse HEAD)" = "$ORIGEM_HEAD" ]'
checar "branch atual é mantida" '[ "$(git -C "$K/projeto" symbolic-ref --short HEAD)" = master ]'
checar "código chegou" '[ -f "$K/projeto/src/A.cs" ]'
checar "item ignorado não veio" '[ ! -e "$K/projeto/bin" ]'
checar "gitignore do projeto foi mantido" 'grep -Fxq "bin/" "$K/projeto/.gitignore"'
checar "gitignore recebeu as regras do kit" 'grep -Fxq "parametro.json" "$K/projeto/.gitignore"'
checar "trava de commit ligada" '[ "$(git -C "$K/projeto" config core.hooksPath)" = ../.claude/git-hooks ]'
checar "branch principal detectada e gravada (master)" 'grep -Fxq "BRANCH_PRINCIPAL=\"master\"" "$K/.claude/comandos.conf"'
checar "decisão foi guardada" '[ -f "$K/privado/origem/Projeto_Documento/decisoes/001.md" ]'
checar "instrução antiga guardada com .antigo" '[ -f "$K/privado/origem/CLAUDE.md.antigo" ]'
checar "chave não foi guardada" '! find "$K/privado/origem" -name "segredos.json" | grep -q .'
checar "chave não foi para o código" '! find "$K/projeto" -name "segredos.json" | grep -q .'
checar "parametro.json não foi guardado" '! find "$K/privado/origem" -name "parametro.json" | grep -q .'
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
checar "documento do código foi guardado" '[ -f "$K/privado/origem/Lib/notas.md" ]'
checar "--excluir vale para a guarda do código" '[ ! -e "$K/privado/origem/Pesado" ]'

# --- Sem git, com pastas geradas e um arquivo sensível ---
novo_kit kit3
O="$K/conversor/jogo"
mkdir -p "$O/Assets" "$O/Library/cache" "$O/config"
echo script > "$O/Assets/C.cs"; echo gerado > "$O/Library/cache/z.bin"; echo doc > "$O/LEIA.md"
echo chave > "$O/config/app.pfx"
bash "$C" preparar >/dev/null
bash "$C" plano >/dev/null 2>&1; checar "sem git exige o repositório criado antes" '[ $? -eq 1 ]'
git -C "$K/projeto" init -q -b main
printf 'Library/\n' >> "$K/projeto/.gitignore"
checar "copiar sem git roda" 'bash "$C" copiar >/dev/null'
checar "código sem git chegou" '[ -f "$K/projeto/Assets/C.cs" ]'
checar "pasta gerada não veio" '[ ! -e "$K/projeto/Library" ]'
checar "arquivo sensível não veio" '[ ! -e "$K/projeto/config/app.pfx" ]'
checar "documento foi guardado, não copiado" '[ -f "$K/privado/origem/LEIA.md" ] && [ ! -e "$K/projeto/LEIA.md" ]'

# --- Kit antigo sem git: código em Projeto/, com P maiúsculo ---
novo_kit kit5
O="$K/conversor/antigo"
mkdir -p "$O/Projeto/src" "$O/Projeto_Documento"
echo codigo > "$O/Projeto/src/D.cs"; echo nota > "$O/Projeto_Documento/nota.md"
bash "$C" preparar >/dev/null
git -C "$K/projeto" init -q -b main
checar "kit antigo sem git roda" 'bash "$C" copiar >/dev/null'
checar "código de Projeto/ chegou em projeto/" '[ -f "$K/projeto/src/D.cs" ]'
checar "documento antigo foi guardado" '[ -f "$K/privado/origem/Projeto_Documento/nota.md" ]'

# --- Biblioteca: master + release/X, trabalho na release, testes ignorados com arquivo de conexão ---
novo_kit kit6
O="$K/conversor/lib"
mkdir -p "$O/Lib" "$O/Testes"
novo_repo "$O" master
printf '/Testes/\n' > "$O/.gitignore"
echo codigo > "$O/Lib/E.cs"; echo notas > "$O/release_1.0.0.txt"; echo notas > "$O/CHANGELOG.md"
git -C "$O" add -A; git -C "$O" commit -qm inicial
git -C "$O" switch -q -c release/1.0.0
echo conexao > "$O/Testes/banco.connection"
bash "$C" preparar >/dev/null
checar "plano sugere a master, não a branch atual" 'bash "$C" plano | grep -Fq "Branch principal: master"'
checar "arquivo .connection aparece como sensível" 'bash "$C" plano | grep -Fq "Testes/banco.connection"'
checar "--principal inexistente é recusado" '! bash "$C" plano --principal nao-existe >/dev/null 2>&1'
checar "copiar de biblioteca roda" 'bash "$C" copiar >/dev/null'
checar "BRANCH_PRINCIPAL=master gravada com o trabalho na release" 'grep -Fxq "BRANCH_PRINCIPAL=\"master\"" "$K/.claude/comandos.conf"'
checar "notas de versão ficam em projeto/" '[ -f "$K/projeto/release_1.0.0.txt" ] && [ -f "$K/projeto/CHANGELOG.md" ]'
checar "CHANGELOG não vai para a guarda" '[ ! -e "$K/privado/origem/CHANGELOG.md" ]'
checar "arquivo .connection não foi guardado nem copiado" '! find "$K/privado/origem" "$K/projeto" -name "*.connection" | grep -q .'

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
