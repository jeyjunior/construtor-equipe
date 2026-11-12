---
name: construtor-equipe-encerrar-ciclo
description: Roda no gerente quando todas as etapas do ciclo estão em "Feito". Confere o ciclo inteiro, registra as lições, atualiza a arquitetura e o README, leva a branch do ciclo para a principal com o ok do usuário, pergunta pela homologação e deixa o projeto sem ciclo aberto.
disable-model-invocation: true
---

# Encerrar ciclo

Você é o **gerente** (veja "Papéis" no `CLAUDE.md`). O projeto não termina: ele fica sem ciclo aberto até o próximo `/construtor-equipe-iniciar`.

`NN` é o número do ciclo, `<ciclo>` é a pasta dele e `<principal>` é o `BRANCH_PRINCIPAL` de `.claude/comandos.conf`.

## 1. Conferir se pode fechar

Leia `privado/QUADRO.md` e `<ciclo>/ciclo.md`. Se alguma etapa do ciclo não está em "Feito", ou há sessão aberta, liste e pare. Se o usuário quiser desistir do ciclo, indique `/construtor-equipe-cancelar-ciclo`. Rode `git -C projeto status`: limpo e na branch `ciclo-NN`.

## 2. Conferir o ciclo, os documentos e levantar as lições (três subagentes, em paralelo)

Os três são do tipo `general-purpose`, não editam nada e seguem `.claude/skills/construtor-equipe-subagente/SKILL.md`, cada um com a sua nota (na secundária, a conferência recebe o `BUILD` e o `TESTE`).

> **Conferência.** Confira o ciclo NN inteiro, na branch `ciclo-NN`. Leia `<ciclo>/ciclo.md` e `.claude/comandos.conf`. Confirme que `git -C projeto status` está limpo. Rode o `BUILD` e, se estiver preenchido, o `TESTE`, dentro de `projeto/`. Verifique o critério de pronto do ciclo com um comando ou comportamento observável; o que depender do usuário, aponte. Rode `git -C projeto diff <principal>...ciclo-NN --stat` e diga se há arquivo sensível. Responda em no máximo 15 linhas: build, testes, critério de pronto (ok ou faltando, com evidência), riscos.

> **Lições.** Leia `<ciclo>/ciclo.md`, os arquivos de `<ciclo>/etapas/` (notas, fechamento e revisão) e `git -C projeto log --oneline <principal>..ciclo-NN`. Procure o que se repetiu 2 vezes ou mais (problemas com a mesma causa, perguntas repetidas, correções pedidas na revisão, desvios do plano, passos manuais), o que funcionou bem e o que atrapalhou. Diga onde cada coisa apareceu. Se nada se repetiu, diga isso. Responda em no máximo uma página.

> **Documentos.** Na branch `ciclo-NN`, compare `privado/docs/objetivo.md`, `privado/docs/arquitetura.md` e `projeto/README.md` com o código e com `git -C projeto diff <principal>...ciclo-NN --stat`. Leia também as decisões do ciclo em `privado/docs/decisoes/` e a tabela de etapas de `<ciclo>/ciclo.md`. Diga, um por linha e com o arquivo e a seção: o que os documentos dizem e o código não faz; o que o código faz e os documentos não dizem (componente, integração externa, segredo novo, comando para rodar, onde roda); cada seção de `arquitetura.md` ainda em `a decidir` que este ciclo já decidiu. Se nada diverge, diga isso. Responda em no máximo 15 linhas.

Se a conferência falhar, mostre e pare. O que faltar vira etapa nova neste ciclo, com o ok do usuário. O ciclo não fecha com falha conhecida.

## 3. Lições com o usuário

1. Mostre o rascunho das lições e pergunte o que ele percebeu que o subagente não pegou.
2. Para cada lição, defina com ele o que fazer: regra ou convenção (`.claude/rules/`), ajuste no kit, ou nada. Com o ok, aplique.
3. Leia as linhas deste ciclo em `privado/docs/subagentes.md`. Se algum tipo de tarefa subiu de nível ou foi descartado mais de uma vez, proponha o ajuste: `SUBAGENTES_MODELOS` ou `SUBAGENTES_ESFORCO_MAX` em `.claude/comandos.conf`, ou a tabela de nota da skill `construtor-equipe-subagente`. Com o ok, aplique.
4. Grave em "Lições" do `ciclo.md`. O próximo `/construtor-equipe-iniciar` lê essa seção.

## 4. Documentar

O ciclo não fecha com documento desatualizado: quem abrir o projeto meses depois lê os documentos, não esta conversa.

1. Mostre ao usuário o que o subagente de documentos apontou.
2. Com o ok, atualize:
   - `privado/docs/arquitetura.md`: preencha o que o ciclo decidiu ou construiu (stack, componentes, integrações externas, configuração e segredos, logs) e a data em "Atualizado". Cada escolha aponta o número da decisão. Não descreva o que não está no código.
   - `projeto/README.md`, na branch do ciclo: o que o sistema faz hoje, como configurar e como rodar, pelos comandos de `.claude/comandos.conf`.
   - `privado/docs/objetivo.md`: só muda com aprovação explícita do usuário, registrada em `privado/docs/decisoes/`. Se o ciclo entregou algo fora do objetivo aprovado, mostre e pergunte.
3. O README vai para o GitHub com o código: nada de segredo, dado pessoal, de cliente ou interno de empresa. Nos outros documentos, nenhum segredo.
4. Se o README mudou, faça o commit na branch do ciclo (`Docs: README do ciclo NN`). Se nada divergia, diga isso e siga sem commit.

## 5. Levar para a principal

Mostre `git -C projeto log --oneline <principal>..ciclo-NN` e peça um **ok explícito** para o merge. Sem esse ok, pare aqui: o ciclo continua aberto.

```bash
git -C projeto switch <principal>
```
```bash
git -C projeto merge --no-ff ciclo-NN -m "Merge: ciclo NN — <objetivo do ciclo>"
```

Conflito: rode `git -C projeto merge --abort`, conte ao usuário o que conflitou e pare; vira etapa nova neste ciclo.

Com o merge feito, rode o `BUILD` em `projeto/`. Depois:

1. Em `ciclo.md`, grave `Status: encerrado (AAAA-MM-DD)` e o commit final (`git -C projeto rev-parse HEAD`).
2. No quadro, a "Situação" fica com ciclo "nenhum aberto", sem sessão, e próximo passo "`/construtor-equipe-iniciar` num gerente novo".
3. Envie com `git -C projeto push origin <principal>` (pede confirmação; sem remoto, diga isso e siga).

## 6. Homologação

Pergunte se o que está em "Feito" já foi publicado ou validado, e com qual versão. Se sim, siga agora `.claude/skills/construtor-equipe-homologar/SKILL.md`. Se não, os itens ficam em "Feito" e o usuário roda `/construtor-equipe-homologar` quando acontecer.

## 7. Fechar

Diga ao usuário para fechar esta sessão: o próximo trabalho começa numa sessão nova, aberta por ele no Root, com `/construtor-equipe-iniciar`.
