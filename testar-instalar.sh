#!/usr/bin/env bash
# Autoteste do instalar.sh: instalação nova, conversão e atualização de um projeto no formato da v2.
#   bash testar-instalar.sh

set -u
KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
export INSTALAR_SEM_AUTOTESTE=1
FALHAS=0

confere() {
  if eval "$2"; then echo "ok    $1"; else echo "FALHA $1"; FALHAS=$((FALHAS + 1)); fi
}

bash "$KIT/instalar.sh" "$T/novo" >/dev/null
confere "novo: kit copiado" '[ -f "$T/novo/CLAUDE.md" ] && [ -f "$T/novo/.claude/VERSAO" ] && [ -f "$T/novo/projeto/.gitignore" ]'
confere "novo: parametro.json base" 'jq -e ".NomeDaEmpresa.ApiKey == \"\"" "$T/novo/privado/parametros/parametro.json" >/dev/null'
confere "novo: sem arquivos do instalador" '[ ! -e "$T/novo/instalar.sh" ] && [ ! -e "$T/novo/README.md" ]'

mkdir -p "$T/antigo/src/bin" && echo x > "$T/antigo/src/a.cs" && echo y > "$T/antigo/src/bin/a.dll"
bash "$KIT/instalar.sh" "$T/conv" "$T/antigo" >/dev/null
confere "conversão: código em conversor/" '[ -f "$T/conv/conversor/antigo/src/a.cs" ]'
confere "conversão: sem pasta gerada" '[ ! -e "$T/conv/conversor/antigo/src/bin" ]'
confere "conversão: recusa origem inexistente" '! bash "$KIT/instalar.sh" "$T/x" "$T/nada" 2>/dev/null && [ ! -e "$T/x" ]'
confere "recusa pasta não vazia sem kit" '! bash "$KIT/instalar.sh" "$T/antigo" 2>/dev/null'

R="$T/v2"
bash "$KIT/instalar.sh" "$R" >/dev/null
rm "$R/.claude/VERSAO"
for s in "$R"/.claude/skills/construtor-*; do mv "$s" "$R/.claude/skills/construtor-equipe-${s##*/construtor-}"; done
mkdir -p "$R/.claude/skills/construtor-equipe-homologar" "$R/.claude/skills/minha-skill"
echo velha > "$R/.claude/skills/construtor-equipe-homologar/SKILL.md"
echo minha > "$R/.claude/skills/minha-skill/SKILL.md"
echo velho > "$R/.claude/bin/secundaria.sh"
sed -i -e 's/^SUBAGENTES_VIA=.*/SUBAGENTES_CONTA="secundaria"/' -e 's/^BUILD=.*/BUILD="dotnet build X.slnx"/' "$R/.claude/comandos.conf"
echo 'MINHA_VAR="1"' >> "$R/.claude/comandos.conf"
jq '.permissions.allow = ["Bash(bash .claude/bin/secundaria.sh status)", "Bash(ssh meu-servidor *)"] | .permissions.deny += ["Bash(*operador@*)"] | .env = {"A": "1"}' \
  "$R/.claude/settings.json" > "$R/s" && mv "$R/s" "$R/.claude/settings.json"
printf '# Projeto\n\n**Nome:** X\n**Testes:** não\n' > "$R/.claude/rules/projeto.md"
mkdir -p "$R/privado/docs" && echo quadro > "$R/privado/QUADRO.md"
rm "$R/privado/parametros/parametro.json"
bash "$KIT/instalar.sh" "$T/p2/r" >/dev/null && echo '{"Meu":{"ApiKey":"x"}}' > "$T/p2/r/privado/parametros/parametro.json"
git -C "$R/projeto" init -q -b main
git -C "$R/projeto" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "Docs: início"
git -C "$R/projeto" branch ciclo-01
git -C "$R/projeto" branch ciclo-01-etapa-01

SAIDA="$(bash "$KIT/instalar.sh" "$R")"
C="$R/.claude"
confere "atualizar: versão nova" '[ "$(cat "$C/VERSAO")" = "$(cat "$KIT/.claude/VERSAO")" ]'
confere "atualizar: kit anterior guardado" '[ -f "$R"/privado/kit-anterior/*/.claude/bin/secundaria.sh ]'
confere "atualizar: skill e script antigos saem" '[ ! -e "$C/skills/construtor-equipe-homologar" ] && [ ! -e "$C/bin/secundaria.sh" ]'
confere "atualizar: skill do projeto fica" '[ -f "$C/skills/minha-skill/SKILL.md" ]'
confere "atualizar: skills da v2 viram construtor-*" '[ -f "$C/skills/construtor-iniciar/SKILL.md" ] && ! compgen -G "$C/skills/construtor-equipe-*" >/dev/null'
confere "atualizar: valor do projeto fica" 'grep -qx "BUILD=\"dotnet build X.slnx\"" "$C/comandos.conf"'
confere "atualizar: SUBAGENTES_CONTA vira VIA=cli" 'grep -qx "SUBAGENTES_VIA=\"cli\"" "$C/comandos.conf" && ! grep -q SUBAGENTES_CONTA "$C/comandos.conf"'
confere "atualizar: variável própria fica" 'grep -qx "MINHA_VAR=\"1\"" "$C/comandos.conf"'
confere "atualizar: regra do projeto fica" 'jq -e ".permissions.allow | index(\"Bash(ssh meu-servidor *)\")" "$C/settings.json" >/dev/null'
confere "atualizar: regra do kit entra" 'jq -e ".permissions.allow | index(\"Bash(git -C projeto commit *)\")" "$C/settings.json" >/dev/null'
confere "atualizar: regra obsoleta sai" '! grep -q secundaria "$C/settings.json"'
confere "atualizar: deny do projeto fica, sem duplicar" '[ "$(jq "[.permissions.deny[] | select(. == \"Bash(*operador@*)\")] | length" "$C/settings.json")" = 1 ]'
confere "atualizar: outras chaves ficam" '[ "$(jq -r .env.A "$C/settings.json")" = 1 ]'
confere "atualizar: Commits e Versão" 'grep -q "^\*\*Commits:\*\*" "$C/rules/projeto.md" && grep -q "^\*\*Versão:\*\*" "$C/rules/projeto.md"'
confere "atualizar: privado intacto" '[ "$(cat "$R/privado/QUADRO.md")" = quadro ]'
confere "atualizar: cria parametro.json base se falta" '[ -f "$R/privado/parametros/parametro.json" ]'
bash "$KIT/instalar.sh" "$T/p2/r" >/dev/null
confere "atualizar: não sobrescreve parametro.json" 'grep -q "\"Meu\"" "$T/p2/r/privado/parametros/parametro.json"'
confere "atualizar: aponta branches mescladas" 'grep -q "ciclo-01-etapa-01" <<< "$SAIDA"'

cp "$C/comandos.conf" "$T/c1"; cp "$C/settings.json" "$T/s1"
bash "$KIT/instalar.sh" "$R" >/dev/null
confere "atualizar de novo não muda nada" 'diff -q "$T/c1" "$C/comandos.conf" >/dev/null && diff -q "$T/s1" "$C/settings.json" >/dev/null && [ "$(grep -c "^\*\*Versão:\*\*" "$C/rules/projeto.md")" = 1 ]'

echo
if [ "$FALHAS" = 0 ]; then echo "Todos os testes passaram."; else echo "$FALHAS falha(s)."; exit 1; fi
