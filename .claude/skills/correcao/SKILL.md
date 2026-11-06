---
name: correcao
description: Roda na sessão vinculada aberta pelo /progresso. Corrige, a partir da branch principal, um bug antigo que atrapalha mesmo sem o ciclo (caso 3 da skill depurar) e fecha com o status na tabela Correções do roadmap do ciclo.
disable-model-invocation: true
argument-hint: "[número da correção]"
---

# Correção

Você é a **sessão desta correção**, aberta pelo gerente. A etapa que encontrou o bug está parada, e o bug existe na branch principal. Você corrige só esse bug e, ao terminar, marca no roadmap como a correção fechou. Merge e push são do gerente.

`<ciclo>` é a pasta do ciclo atual em `estado.md`, `NN` é o número do ciclo, `CC` é o número da correção e `<principal>` é o `BRANCH_PRINCIPAL` de `.claude/comandos.conf`.

## 1. Situar

1. Leia `Projeto_Documento/estado.md`, `<ciclo>/roadmap.md`, `<ciclo>/correcoes/CC-*.md` e `.claude/comandos.conf`.
2. Pelo status na tabela "Correções" do roadmap:
   - `pendente`: siga;
   - `em andamento`: continue. Se a seção "Revisão" trouxer itens pendentes, faça só eles;
   - `concluída` ou `decisão pendente`: diga ao usuário para rodar `/progresso` no gerente e pare;
   - `revisada`: pare.
3. Rode `git -C Projeto status`. Se houver algo não commitado, mostre e pare: a sessão da etapa deveria ter feito o commit.
4. Vá para a branch da correção. Se ela não existir:
   ```bash
   git -C Projeto switch <principal>
   ```
   ```bash
   git -C Projeto switch -c ciclo-NN-correcao-CC
   ```
   Marque a correção como `em andamento` na tabela.

## 2. Reproduzir na principal

Reproduza o bug com os passos do arquivo da correção. Sem o código do ciclo, ele precisa aparecer e causar problema real.

Se não causar, a causa não é deste caso: ele só atrapalha por causa do ciclo (caso 2). Não corrija. Registre a evidência em "Fechamento", marque `decisão pendente` e diga ao usuário para rodar `/progresso`.

## 3. Corrigir

Siga a skill `depurar`, sem a parte de classificar. Só a correção do bug, sem melhorias. Decisão que o arquivo da correção não cobre: pergunte ao usuário aqui. Mudança em banco, servidor ou serviço: registre em "Alterações fora do git".

## 4. Fechar

1. Repita a reprodução e mostre que o problema sumiu. Rode o `BUILD` e, se estiver preenchido, o `TESTE`. Registre a evidência: comando executado e trecho da saída.
2. Confira `git -C Projeto status`: nenhuma documentação e nenhum arquivo sensível.
3. Preencha "Fechamento" e faça o commit na branch da correção, mostrando a mensagem no formato `Correcao: <descrição>`.
4. Marque `concluída` na tabela "Correções".
5. Comece a última resposta pelo status (ex.: `Correção 01: concluída`) e diga ao usuário para voltar ao gerente e rodar `/progresso`. Não faça merge nem push.
