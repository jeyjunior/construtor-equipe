#!/usr/bin/env bash
# Hook PreToolUse (Edit|Write|MultiEdit): faz o Claude seguir a estrutura fixa do Root.
#   Projeto/            só código: nega documentação (.md e afins, pastas docs/), exceto o
#                       README.md da raiz de Projeto/, e nega arquivo sensível (.env, chaves...).
#   Projeto_Documento/  documentação: liberado, menos sensivel/ (o Claude não grava lá).
#   .claude/, CLAUDE.md o kit: liberado.
#   qualquer outra coisa no Root: negado (nada solto, nenhuma pasta fora do padrão).
# Fora do Root não interfere. As regras ficam em comum.sh, as mesmas do pre-commit. Funciona sem jq.

ENTRADA=$(cat)
# shellcheck source=comum.sh
source "$(dirname "${BASH_SOURCE[0]}")/comum.sh"

ARQ=$(caminho_da_entrada "$ENTRADA")
[ -n "$ARQ" ] || exit 0
REL=$(relativo_a_raiz "$ARQ")
fora_do_root "$REL" && exit 0

REGRA="Estrutura fixa do kit: Root/$PASTA_PROJETO/ é onde o projeto é construído (só código, vai para o GitHub); Root/$PASTA_DOCUMENTO/ é onde fica a documentação (não entra em git nem em lugar nenhum)."

if NO_PROJETO=$(dentro_do_projeto "$REL"); then
  if eh_documentacao "$NO_PROJETO"; then
    negar_ferramenta "$REGRA Documentação não vai em $PASTA_PROJETO/: grave em $PASTA_DOCUMENTO/ (ex.: $PASTA_DOCUMENTO/$(basename "$NO_PROJETO")). O único .md permitido em $PASTA_PROJETO/ é o README.md da raiz dele."
  fi
  if eh_sensivel "$NO_PROJETO"; then
    negar_ferramenta "$REGRA Arquivo sensível não vai em $PASTA_PROJETO/ ($NO_PROJETO). O arquivo real fica em $PASTA_DOCUMENTO/sensivel/ (o usuário guarda) e o sistema lê pelo padrão segredo.json de .claude/rules/segredos.md. Para documentar as chaves, use segredo.exemplo.json com valores vazios."
  fi
  exit 0
fi

if NO_DOC=$(dentro_de "$PASTA_DOCUMENTO" "$REL"); then
  if [[ $(minusculas "$NO_DOC") == sensivel/* ]]; then
    negar_ferramenta "$PASTA_DOCUMENTO/sensivel/ é do usuário: o Claude não lê nem grava nessa pasta."
  fi
  exit 0
fi

dentro_de ".claude" "$REL" >/dev/null && exit 0
case "$(minusculas "$REL")" in
  claude.md|claude.local.md) exit 0 ;;
esac

negar_ferramenta "$REGRA No Root não se cria nada fora disso ($REL). Código vai em $PASTA_PROJETO/, documentação em $PASTA_DOCUMENTO/."
