#!/usr/bin/env bash
# Hook PreToolUse (Edit|Write|MultiEdit): faz o Claude seguir a estrutura do Root e os papéis.
#   projeto/   só código. Nega arquivo sensível (.env, chaves...) e documentação (.md e afins,
#              pastas docs/), exceto o README.md e as notas de versão da raiz de projeto/. Na branch
#              principal, do ciclo (ciclo-NN) ou de release (release/X.Y.Z): nega editar código; só o README, as notas de versão e
#              a configuração do git. Liberado durante um merge, para resolver conflito.
#   privado/   quadro e documentos, fora do git. parametros/ é do usuário: negado. Em branch de
#              trabalho (ciclo-NN-etapa-EE, curto-NNN): nega o QUADRO.md à sessão que editou código
#              (a da etapa ou do ciclo curto); o gerente, que não edita código, continua editando.
#   .claude/, CLAUDE.md   o kit: liberado.
#   qualquer outra coisa no Root: negado (nada solto, nenhuma pasta fora do padrão).
# Fora do Root não interfere. As regras ficam em comum.sh. Funciona sem jq.

ENTRADA=$(cat)
# shellcheck source=comum.sh
source "${BASH_SOURCE[0]%/*}/comum.sh"

ARQ=$(caminho_da_entrada "$ENTRADA")
[ -n "$ARQ" ] || exit 0
REL=$(relativo_a_raiz "$ARQ")
fora_do_root "$REL" && exit 0

if NO_PROJETO=$(dentro_do_projeto "$REL"); then
  if eh_sensivel "$NO_PROJETO"; then
    negar_ferramenta "Arquivo sensível não vai em $PASTA_PROJETO/ ($NO_PROJETO). O arquivo real fica em $PASTA_PRIVADO/parametros/ (o usuário guarda) e o sistema lê pelo padrão parametro.json de .claude/rules/parametros.md. Para documentar as chaves, use parametro.exemplo.json com valores vazios."
  fi
  if eh_documentacao "$NO_PROJETO"; then
    negar_ferramenta "Documentação não vai em $PASTA_PROJETO/ ($NO_PROJETO): $PASTA_PROJETO/ só leva código para o GitHub. O quadro fica em $PASTA_PRIVADO/QUADRO.md e os documentos em $PASTA_PRIVADO/docs/, fora do git. Os únicos .md permitidos em $PASTA_PROJETO/ são o README.md e as notas de versão (CHANGELOG.md, release_X.Y.Z.md) da raiz dele."
  fi
  BRANCH=$(branch_do_projeto)
  [ -n "$BRANCH" ] || exit 0   # sem repositório ou sem commit: o projeto ainda está começando
  carregar_comandos
  PRINCIPAL="${BRANCH_PRINCIPAL:-main}"
  if [[ $BRANCH == "$PRINCIPAL" || $BRANCH =~ $RE_BRANCH_CICLO || $BRANCH =~ $RE_BRANCH_RELEASE ]]; then
    if ! eh_doc_do_projeto "$NO_PROJETO" && ! merge_em_andamento; then
      negar_ferramenta "Código só muda em branch de etapa (ciclo-NN-etapa-EE) ou de ciclo curto (curto-NNN). A branch atual é $BRANCH, que só recebe merges e, direto, o README, as notas de versão e a configuração do git. Gerente não escreve código: abra a etapa com /construtor-proxima-etapa ou use /construtor-ciclo-curto."
    fi
  fi
  exit 0
fi

if NO_PRIVADO=$(dentro_de "$PASTA_PRIVADO" "$REL"); then
  if casa_sem_caixa "$NO_PRIVADO" '^parametros(/|$)'; then
    negar_ferramenta "$PASTA_PRIVADO/parametros/ é do usuário: o Claude não lê nem grava nessa pasta."
  fi
  if eh_quadro "$NO_PRIVADO"; then
    BRANCH=$(branch_do_projeto)
    SESSAO=$(sessao_da_entrada "$ENTRADA")
    if [[ $BRANCH =~ $RE_BRANCH_TRABALHO ]] && [ -n "$SESSAO" ] && [ -e "$(marca_de_edicao "$SESSAO")" ]; then
      negar_ferramenta "O QUADRO.md é do gerente, e esta sessão editou código em $PASTA_PROJETO/ (branch $BRANCH). Sessão de etapa: registre no arquivo da etapa; o gerente leva para o quadro no /construtor-proxima-etapa. Sessão de ciclo curto: atualize o quadro depois do merge na principal."
    fi
  fi
  exit 0
fi

dentro_de ".claude" "$REL" >/dev/null && exit 0
casa_sem_caixa "$REL" '^claude(\.local)?\.md$' && exit 0

negar_ferramenta "No Root só ficam o kit (CLAUDE.md, .claude/), $PASTA_PROJETO/ (código), $PASTA_PRIVADO/ (quadro e documentos) e conversor/. Não crie nada fora disso ($REL): código vai em $PASTA_PROJETO/ e documento em $PASTA_PRIVADO/docs/."
