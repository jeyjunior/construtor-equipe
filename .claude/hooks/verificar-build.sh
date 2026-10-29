#!/usr/bin/env bash
# Hook Stop: ao fim de cada resposta do Claude, se houver código alterado e não commitado em
# Projeto/, roda o BUILD de .claude/comandos.conf dentro de Projeto/.
#  - Build falhou: devolve os erros ao Claude (exit 2) para ele corrigir antes de encerrar.
#  - Falhou de novo logo depois da correção: não barra outra vez, só avisa você.
#  - Erro de ambiente (BUILD_IGNORAR, ex.: arquivo travado pelo programa rodando): só avisa você.
#  - Nada mudou desde o último build que passou: não compila de novo.

ENTRADA=$(cat)
# shellcheck source=comum.sh
source "$(dirname "${BASH_SOURCE[0]}")/comum.sh"
carregar_comandos || exit 0
[ -n "${BUILD:-}" ] || exit 0   # sem comando de build: o projeto ainda está em planejamento
cd "$RAIZ/$PASTA_PROJETO" 2>/dev/null || exit 0

SEGUNDA=0
printf '%s' "$ENTRADA" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && SEGUNDA=1

# O cache fica no kit, nunca dentro de Projeto/.
CACHE="$RAIZ/.claude/.cache"
ASSINATURA=""
if [ -e .git ] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [ -n "${CODIGO:-}" ]; then
    read -r -a ALVOS <<< "$CODIGO"
  else
    ALVOS=(. ':(exclude)*.md')
  fi
  MUDANCAS=$(git status --porcelain --untracked-files=all -- "${ALVOS[@]}" 2>/dev/null)
  [ -n "$MUDANCAS" ] || exit 0
  # Assinatura do estado atual do código: igual à do último build que passou = nada a compilar.
  ASSINATURA=$(
    {
      git diff -- "${ALVOS[@]}"
      git diff --cached -- "${ALVOS[@]}"
      git -c core.quotePath=false ls-files --others --exclude-standard -- "${ALVOS[@]}" \
        | git hash-object --stdin-paths
    } 2>/dev/null | cksum | cut -d' ' -f1
  )
  if [ -f "$CACHE/build-ok" ] && [ "$(cat "$CACHE/build-ok" 2>/dev/null)" = "$ASSINATURA" ]; then
    exit 0
  fi
fi

SAIDA=$(eval "$BUILD" 2>&1)
STATUS=$?

if [ $STATUS -eq 0 ]; then
  if [ -n "$ASSINATURA" ]; then
    mkdir -p "$CACHE" 2>/dev/null && printf '%s' "$ASSINATURA" > "$CACHE/build-ok"
  fi
  exit 0
fi
rm -f "$CACHE/build-ok" 2>/dev/null

if [ -n "${BUILD_IGNORAR:-}" ] && printf '%s' "$SAIDA" | grep -qE -- "$BUILD_IGNORAR"; then
  avisar_usuario "O build falhou por um motivo de ambiente (casou com BUILD_IGNORAR em .claude/comandos.conf), provavelmente arquivo travado pelo programa em execução. Pare o programa e compile de novo."
  exit 0
fi

if [ $SEGUNDA -eq 1 ]; then
  avisar_usuario "O build continua quebrado depois da tentativa de correção do Claude. Para ver os erros, rode em $PASTA_PROJETO/: $BUILD"
  exit 0
fi

{
  echo "O build falhou. Corrija os erros abaixo antes de encerrar."
  echo "Se você parou para fazer uma pergunta ao usuário, avise também que o build está quebrado."
  echo "Comando (rodado em $PASTA_PROJETO/): $BUILD"
  echo
  printf '%s\n' "$SAIDA" | tail -n 40
} >&2
exit 2
