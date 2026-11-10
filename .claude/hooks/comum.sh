#!/usr/bin/env bash
# Nomes, regras e funções compartilhados pelos hooks do kit, pelo pre-commit e pelo converter.sh.
# Uso: source "<pasta>/comum.sh". Não roda sozinho.

# Estrutura do kit: Root/projeto (código, único repositório git) e Root/privado (quadro,
# documentos, chaves e material antigo, fora de qualquer git). Estes nomes são a regra.
PASTA_PROJETO="projeto"
# shellcheck disable=SC2034  # usado pelos scripts que carregam este arquivo
PASTA_PRIVADO="privado"
RAIZ="${CLAUDE_PROJECT_DIR:-$PWD}"
RAIZ="${RAIZ//\\//}"   # Root sempre com / (no Windows chega com \)

# --- Regras, aplicadas ao caminho relativo a projeto/, em minúsculas --------------------------
# Fonte única para proteger-estrutura.sh, formatar.sh, o pre-commit e o aviso de abertura.

# O que não é código em projeto/: o README da raiz e os arquivos de configuração do git.
# Tudo o mais em projeto/ conta como código. O quadro e os documentos ficam em privado/.
RE_DOC_PROJETO='^readme\.md$|(^|/)\.git(ignore|attributes)$'
# Documentação: não entra em projeto/. Arquivos de texto de documentação e pastas de documentação.
# Mudou aqui? Ajuste também projeto/.gitignore do modelo.
RE_DOC='(^|/)(docs|documentacao)/|\.(md|markdown|mdx|adoc|rst)$'
# Única exceção: o README.md da raiz de projeto/ (a página do repositório no GitHub).
RE_DOC_PERMITIDO='^readme\.md$'
# Sensível: .env com valores, chaves, certificados, cofres de chave, segredos locais.
# Mudou aqui? Ajuste também projeto/.gitignore do modelo.
RE_SENSIVEL='(^|/)sensivel/|(^|/)(privado|projeto_documento)/parametros/|(^|/)parametro\.json$|(^|/)\.env$|(^|/)\.env\.|\.(pem|pfx|p12|key|cer|crt|jks|keystore)$|(^|/)id_(rsa|ed25519|ecdsa|dsa)|(^|/)secrets\.json$|(^|/)segredos?\.json$'
# Exceção: o .env.example, que só tem nomes de variáveis e valores de exemplo.
RE_SENSIVEL_PERMITIDO='(^|/)\.env\.example$'

minusculas() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# Retorna 0 se o caminho (relativo a projeto/) é o README ou configuração do git, e não código.
eh_doc_do_projeto() {
  local p; p=$(minusculas "$1")
  [[ $p =~ $RE_DOC_PROJETO ]]
}

# Retorna 0 se o caminho (relativo a projeto/) é documentação que não pode estar em projeto/.
eh_documentacao() {
  local p; p=$(minusculas "$1")
  [[ $p =~ $RE_DOC ]] && ! [[ $p =~ $RE_DOC_PERMITIDO ]]
}

# Retorna 0 se o caminho (relativo a privado/) é o quadro.
eh_quadro() { [[ $(minusculas "$1") == "quadro.md" ]]; }

# Retorna 0 se o caminho (relativo a projeto/) é arquivo sensível que não pode estar em projeto/.
eh_sensivel() {
  local p; p=$(minusculas "$1")
  [[ $p =~ $RE_SENSIVEL ]] && ! [[ $p =~ $RE_SENSIVEL_PERMITIDO ]]
}

# --- Branches ---------------------------------------------------------------------------------
# ciclo-NN: branch do ciclo. ciclo-NN-etapa-EE e curto-NNN: onde o código muda.

RE_BRANCH_CICLO='^ciclo-[0-9]+$'
RE_BRANCH_TRABALHO='^(ciclo-[0-9]+-etapa-[0-9]+|curto-[0-9]+)$'

# Branch atual de projeto/. Vazio se não há repositório, não há commit ou o HEAD está solto.
branch_do_projeto() {
  local p="$RAIZ/$PASTA_PROJETO"
  [ -e "$p/.git" ] || return 0
  git -C "$p" rev-parse -q --verify HEAD >/dev/null 2>&1 || return 0
  git -C "$p" symbolic-ref --short -q HEAD 2>/dev/null
}

# Retorna 0 se há um merge em andamento em projeto/ (resolução de conflito).
merge_em_andamento() {
  git -C "$RAIZ/$PASTA_PROJETO" rev-parse -q --verify MERGE_HEAD >/dev/null 2>&1
}

# --- Caminhos ---------------------------------------------------------------------------------

# Caminho relativo ao Root, sempre com /. No Windows chegam \ e a letra do drive pode variar de caixa.
relativo_a_raiz() {
  local arq="${1//\\//}" raiz="${RAIZ//\\//}" estava
  raiz="${raiz%/}"
  estava=$(shopt -p nocasematch)
  shopt -s nocasematch
  [[ "$arq" == "$raiz"/* ]] && arq="${arq:${#raiz}+1}"
  eval "$estava"
  while [[ "$arq" == ./* ]]; do arq="${arq#./}"; done
  printf '%s' "$arq"
}

# dentro_de PASTA CAMINHO: se o caminho (relativo ao Root) fica dentro de PASTA/, imprime o caminho
# relativo a PASTA/ e retorna 0. Sem diferenciar maiúsculas (o Windows não diferencia).
dentro_de() {
  local p r
  p=$(minusculas "$1"); r=$(minusculas "$2")
  [[ "$r" == "$p"/* ]] || return 1
  printf '%s' "${2:${#1}+1}"
}
dentro_do_projeto() { dentro_de "$PASTA_PROJETO" "$1"; }

# Retorna 0 se o caminho (já passado por relativo_a_raiz) ficou fora do Root.
fora_do_root() { [[ "$1" == /* || "$1" =~ ^[A-Za-z]:/ ]]; }

# Caminho do arquivo na entrada de um hook de Edit/Write. Funciona sem jq.
caminho_da_entrada() {
  local arq
  if command -v jq >/dev/null 2>&1; then
    arq=$(printf '%s' "$1" | jq -r '.tool_input.file_path // empty')
  else
    arq=$(printf '%s' "$1" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
    arq=${arq//\\\\/\\}
  fi
  printf '%s' "$arq"
}

# Id da sessão na entrada de qualquer hook. Funciona sem jq (o id não tem aspas nem barras).
sessao_da_entrada() {
  printf '%s' "$1" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1
}

# Marca de que a sessão editou código em projeto/: só essa sessão compila no Stop.
marca_de_edicao() { printf '%s' "$RAIZ/.claude/.cache/editou-$1"; }

# --- Saídas de hook ---------------------------------------------------------------------------

json_texto() {
  local s=$1
  s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\n'/ }; s=${s//$'\r'/}; s=${s//$'\t'/ }
  printf '%s' "$s"
}

# Nega a ferramenta (PreToolUse) com o motivo dado e encerra o hook.
negar_ferramenta() {
  printf '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "%s"}}\n' "$(json_texto "$1")"
  exit 0
}

# Mensagem para o usuário (aparece na tela, não vai para o Claude), sem bloquear.
avisar_usuario() {
  printf '{"systemMessage": "%s"}\n' "$(json_texto "$1")"
}

# --- Comandos do projeto ----------------------------------------------------------------------

# Carrega .claude/comandos.conf (tolerando quebra de linha CRLF). Retorna 1 se não existir.
carregar_comandos() {
  local conf="$RAIZ/.claude/comandos.conf"
  [ -f "$conf" ] || return 1
  # shellcheck disable=SC1090
  source <(tr -d '\r' < "$conf")
}
