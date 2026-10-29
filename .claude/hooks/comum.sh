#!/usr/bin/env bash
# Nomes, regras e funções compartilhados pelos hooks do kit e pelo pre-commit do git.
# Uso: source "<pasta>/comum.sh". Não roda sozinho.

PASTA_PROJETO="Projeto"
# shellcheck disable=SC2034  # usado pelos scripts que carregam este arquivo
PASTA_DOCUMENTO="Projeto_Documento"
# Estrutura fixa do kit: Root/Projeto (código, versionado) e Root/Projeto_Documento (documentação,
# fora de qualquer git). Não é configurável: estes nomes são a regra.
RAIZ="${CLAUDE_PROJECT_DIR:-$PWD}"
RAIZ="${RAIZ//\\//}"   # Root sempre com / (no Windows chega com \)

# --- Regras da separação Projeto/ x Projeto_Documento/ ---------------------------------------
# Aplicadas ao caminho relativo a Projeto/, em minúsculas. São a fonte única para o hook
# proteger-estrutura.sh, o pre-commit e o aviso de abertura de sessão.
# Mudou aqui? Ajuste também Projeto/.gitignore do modelo.

# Documentação: arquivos de texto de documentação e pastas de documentação.
RE_DOC='(^|/)(docs|documentacao)/|\.(md|markdown|mdx|adoc|rst)$'
# Única exceção: o README.md da raiz de Projeto/ (a página do repositório no GitHub).
RE_DOC_PERMITIDO='^readme\.md$'
# Sensível: .env com valores, chaves, certificados, cofres de chave, segredos locais.
RE_SENSIVEL='(^|/)sensivel/|(^|/)\.env$|(^|/)\.env\.|\.(pem|pfx|p12|key|cer|crt|jks|keystore)$|(^|/)id_(rsa|ed25519|ecdsa|dsa)|(^|/)secrets\.json$|(^|/)segredo\.json$'
# Exceção: o .env.example, que só tem nomes de variáveis e valores de exemplo.
RE_SENSIVEL_PERMITIDO='(^|/)\.env\.example$'

minusculas() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# Retorna 0 se o caminho (relativo a Projeto/) é documentação que não pode estar em Projeto/.
eh_documentacao() {
  local p; p=$(minusculas "$1")
  [[ $p =~ $RE_DOC ]] && ! [[ $p =~ $RE_DOC_PERMITIDO ]]
}

# Retorna 0 se o caminho (relativo a Projeto/) é arquivo sensível que não pode estar em Projeto/.
eh_sensivel() {
  local p; p=$(minusculas "$1")
  [[ $p =~ $RE_SENSIVEL ]] && ! [[ $p =~ $RE_SENSIVEL_PERMITIDO ]]
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
