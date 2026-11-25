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

# O que não é código em projeto/: o README e as notas de versão da raiz, e os arquivos de configuração do git.
# Tudo o mais em projeto/ conta como código. O quadro e os documentos ficam em privado/.
RE_DOC_PROJETO='^(readme|changelog)\.md$|^release[-_][^/]+\.(md|txt)$|(^|/)\.git(ignore|attributes)$'
# Documentação: não entra em projeto/. Arquivos de texto de documentação e pastas de documentação.
# Mudou aqui? Ajuste também projeto/.gitignore do modelo.
RE_DOC='(^|/)(docs|documentacao)/|\.(md|markdown|mdx|adoc|rst)$'
# Exceções: o README.md e as notas de versão públicas (CHANGELOG.md, release_X.Y.Z.md) na raiz de projeto/.
RE_DOC_PERMITIDO='^(readme|changelog)\.md$|^release[-_][^/]+\.md$'
# Sensível: .env com valores, chaves, certificados, cofres de chave, arquivos de conexão, segredos locais.
# Mudou aqui? Ajuste também projeto/.gitignore do modelo.
RE_SENSIVEL='(^|/)sensivel/|(^|/)(privado|projeto_documento)/parametros/|(^|/)parametro\.json$|(^|/)\.env$|(^|/)\.env\.|\.(pem|pfx|p12|key|cer|crt|jks|keystore)$|(^|/)id_(rsa|ed25519|ecdsa|dsa)|(^|/)secrets\.json$|(^|/)segredos?\.json$|\.connection$|(^|/)\.pgpass$|(^|/)\.my\.cnf$|\.(ppk|kdbx)$'
# Exceção: o .env.example, que só tem nomes de variáveis e valores de exemplo.
RE_SENSIVEL_PERMITIDO='(^|/)\.env\.example$'

minusculas() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# casa_sem_caixa TEXTO REGEX: [[ =~ ]] sem diferenciar maiúsculas. Não abre processo: no Git Bash,
# cada processo custa dezenas de milissegundos, e os hooks rodam a cada ferramenta.
casa_sem_caixa() {
  if shopt -q nocasematch; then [[ $1 =~ $2 ]]; return; fi
  shopt -s nocasematch
  local r=1; [[ $1 =~ $2 ]] && r=0
  shopt -u nocasematch
  return $r
}

# Retorna 0 se o caminho (relativo a projeto/) é o README ou configuração do git, e não código.
eh_doc_do_projeto() { casa_sem_caixa "$1" "$RE_DOC_PROJETO"; }

# Retorna 0 se o caminho (relativo a projeto/) é documentação que não pode estar em projeto/.
eh_documentacao() {
  casa_sem_caixa "$1" "$RE_DOC" && ! casa_sem_caixa "$1" "$RE_DOC_PERMITIDO"
}

# Retorna 0 se o caminho (relativo a privado/) é o quadro.
eh_quadro() { casa_sem_caixa "$1" '^quadro\.md$'; }

# Retorna 0 se o caminho (relativo a projeto/) é arquivo sensível que não pode estar em projeto/.
eh_sensivel() {
  casa_sem_caixa "$1" "$RE_SENSIVEL" && ! casa_sem_caixa "$1" "$RE_SENSIVEL_PERMITIDO"
}

# --- Branches ---------------------------------------------------------------------------------
# ciclo-NN: branch do ciclo. ciclo-NN-etapa-EE e curto-NNN: onde o código muda.

RE_BRANCH_CICLO='^ciclo-[0-9]+$'
RE_BRANCH_TRABALHO='^(ciclo-[0-9]+-etapa-[0-9]+|curto-[0-9]+)$'
# release/X.Y.Z (biblioteca publicada): como a principal, só recebe merge e tag.
RE_BRANCH_RELEASE='^release[/-]'

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

# O Git Bash escreve C:\x como /c/x. Deixa em REPLY a forma c:/x, para comparar com o Root.
de_git_bash() {
  if [[ $1 =~ ^/([A-Za-z])(/.*)?$ ]]; then REPLY="${BASH_REMATCH[1]}:${BASH_REMATCH[2]:-/}"; else REPLY=$1; fi
}

# Caminho relativo ao Root, sempre com / e sem . nem .. (sem isso, privado/docs/../parametros
# escaparia das regras). No Windows chegam \, /c/... e a letra do drive em qualquer caixa.
relativo_a_raiz() {
  local arq="${1//\\//}" raiz="${RAIZ%/}" prefixo="" seg partes saida=() n
  if [[ $raiz =~ ^[A-Za-z]:/ || $arq =~ ^[A-Za-z]:/ ]]; then
    de_git_bash "$arq"; arq=$REPLY
    de_git_bash "$raiz"; raiz=${REPLY%/}
  fi
  [[ $arq == /* ]] && prefixo=/
  IFS=/ read -r -a partes <<< "$arq"
  for seg in "${partes[@]}"; do
    n=${#saida[@]}
    case "$seg" in
      ''|.) ;;
      ..)
        if [ "$n" -gt 0 ] && [ "${saida[n-1]}" != .. ] && [[ ${saida[n-1]} != *: ]]; then
          unset "saida[n-1]"
        elif [ -z "$prefixo" ] && { [ "$n" -eq 0 ] || [ "${saida[n-1]}" = .. ]; }; then
          saida+=(..)
        fi ;;
      *) saida+=("$seg") ;;
    esac
  done
  local IFS=/
  arq="$prefixo${saida[*]}"
  [[ $arq =~ ^[A-Za-z]:$ ]] && arq="$arq/"
  dentro_de "$raiz" "$arq" || printf '%s' "$arq"
}

# dentro_de PASTA CAMINHO: se o caminho (relativo ao Root) fica dentro de PASTA/, imprime o caminho
# relativo a PASTA/ e retorna 0. Sem diferenciar maiúsculas (o Windows não diferencia).
dentro_de() {
  local r=1 tinha=0
  shopt -q nocasematch && tinha=1
  shopt -s nocasematch
  [[ $2 == "$1"/* ]] && r=0
  [ $tinha -eq 1 ] || shopt -u nocasematch
  [ $r -eq 0 ] && printf '%s' "${2:${#1}+1}"
  return $r
}
dentro_do_projeto() { dentro_de "$PASTA_PROJETO" "$1"; }

# Retorna 0 se o caminho (já passado por relativo_a_raiz) ficou fora do Root.
fora_do_root() { [[ $1 == /* || $1 == .. || $1 == ../* || $1 =~ ^[A-Za-z]:/ ]]; }

# campo_da_entrada ENTRADA CAMPO: valor de tool_input.CAMPO. Sem jq, lê só o valor do campo, com as
# aspas escapadas, e desfaz os escapes do JSON (\\ guardado antes num caractere de controle, para \\n
# não virar quebra de linha). Usa extensões do GNU sed (Git Bash e Linux têm).
campo_da_entrada() {
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg c "$2" '.tool_input[$c] // empty' <<< "$1"
  else
    sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\(\([^\"\\\\]\|\\\\.\)*\)\".*/\1/p" <<< "$1" | head -n1 \
      | sed -e 's/\\\\/\x01/g' -e 's/\\n/\n/g' -e 's/\\t/\t/g' -e 's/\\\(.\)/\1/g' -e 's/\x01/\\/g'
  fi
}

# Caminho do arquivo na entrada de um hook de Edit/Write. Funciona sem jq.
caminho_da_entrada() {
  local arq
  if command -v jq >/dev/null 2>&1; then
    arq=$(jq -r '.tool_input.file_path // empty' <<< "$1")
  else
    arq=$(sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' <<< "$1")
    arq=${arq%%$'\n'*}
    arq=${arq//\\\\/\\}
  fi
  printf '%s' "$arq"
}

# Id da sessão na entrada de qualquer hook. Funciona sem jq (o id não tem aspas nem barras).
sessao_da_entrada() {
  local s
  s=$(sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' <<< "$1")
  printf '%s' "${s%%$'\n'*}"
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
