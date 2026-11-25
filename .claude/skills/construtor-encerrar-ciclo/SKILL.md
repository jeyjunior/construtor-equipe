---
name: construtor-encerrar-ciclo
description: Roda no gerente para fechar o ciclo aberto. Encerrar (todas as etapas em "Feito") - confere o ciclo, registra lições, atualiza arquitetura e README, leva para a principal com o ok do usuário, registra versão, tag e homologação quando o projeto usa versão. Cancelar (a qualquer momento) - guarda as branches, mostra o que ficou fora do git, marca as decisões que deixam de valer. Nos dois casos, deixa o projeto sem ciclo aberto.
disable-model-invocation: true
argument-hint: "[cancelar <motivo>] [versão]"
---

# Encerrar ciclo

Você é o **gerente** (veja "Papéis" e "Contexto primeiro" no `CLAUDE.md`). O projeto não termina: fica sem ciclo aberto até o próximo `/construtor-iniciar`.

`NN` é o ciclo, `<ciclo>` a pasta dele e `<principal>` o `BRANCH_PRINCIPAL` de `.claude/comandos.conf`.

## 1. Encerrar ou cancelar

Leia `privado/QUADRO.md` e `<ciclo>/ciclo.md`. Sem ciclo aberto, diga isso e pare. Sessão vinculada ainda trabalhando: peça para interromper (ela divide `projeto/`) e pare.

- `$ARGUMENTS` começa com "cancelar", ou o usuário pediu para desistir: seção **Cancelar**.
- Alguma etapa fora de "Feito": liste e ofereça seguir o ciclo (`/construtor-seguir`) ou cancelar. Pare.
- Senão: `git -C projeto status` limpo e na branch `ciclo-NN`, e siga no passo 2.

## 2. Conferir (três subagentes, em paralelo)

Os três são `general-purpose`, não editam nada e seguem `.claude/skills/construtor-subagente/SKILL.md` (pela CLI, a conferência vai com `--verificar`).

> **Conferência.** Confira o ciclo NN inteiro, na branch `ciclo-NN`. Leia `<ciclo>/ciclo.md` e `.claude/comandos.conf`. Confirme `git -C projeto status` limpo. Rode o `BUILD` e, se preenchido, o `TESTE` (`cd projeto && <comando>`). Verifique o critério de pronto com um comando ou comportamento observável; o que depender do usuário, aponte. Rode `git -C projeto diff <principal>...ciclo-NN --stat` e diga se há arquivo sensível. No máximo 15 linhas: build, testes, critério de pronto (com evidência), riscos.

> **Lições.** Leia `<ciclo>/ciclo.md`, os arquivos de `<ciclo>/etapas/` e `git -C projeto log --oneline <principal>..ciclo-NN`. O que se repetiu 2 vezes ou mais (mesma causa, perguntas repetidas, correções na revisão, desvios, passos manuais), o que funcionou e o que atrapalhou, com onde apareceu. No máximo uma página.

> **Documentos.** Na branch `ciclo-NN`, compare `privado/docs/objetivo.md`, `privado/docs/arquitetura.md`, `projeto/README.md` e as notas de versão da raiz de `projeto/` com o código e com `git -C projeto diff <principal>...ciclo-NN --stat`, e leia as decisões do ciclo. Um por linha, com arquivo e seção: o que os documentos dizem e o código não faz; o que o código faz e os documentos não dizem; seções `a decidir` que o ciclo já decidiu. No máximo 15 linhas.

Conferência falhou: mostre e pare. O que faltar vira etapa nova neste ciclo. O ciclo não fecha com falha conhecida.

## 3. Lições e documentos (uma rodada)

Mostre de uma vez: as lições, com a proposta para cada uma (regra em `.claude/rules/`, ajuste no kit, ou nada), o ajuste de subagentes se algum tipo de tarefa subiu de nível ou foi descartado mais de uma vez (em `privado/docs/subagentes.md`), e as atualizações de documento que o subagente apontou. O usuário corrige o que quiser; "segue" aceita tudo. Depois:

1. Grave "Lições" no `ciclo.md` (o próximo `/construtor-iniciar` lê) e aplique as regras aceitas.
2. Atualize `privado/docs/arquitetura.md` (o que o ciclo decidiu ou construiu, cada escolha com o número da decisão, e a data) e `projeto/README.md` na branch do ciclo (o que o sistema faz hoje, como configurar e rodar). Nada de segredo nem de dado pessoal, de cliente ou interno. `objetivo.md` só muda com aprovação explícita, registrada em `privado/docs/decisoes/`.
3. README mudou: commit na branch do ciclo (`Docs: README do ciclo NN`).

## 4. Levar para a principal

Mostre `git -C projeto log --oneline <principal>..ciclo-NN` e peça um **ok explícito**. Sem ele, pare: o ciclo continua aberto.

```bash
git -C projeto switch <principal>
```
```bash
git -C projeto merge --no-ff ciclo-NN -m "Merge: ciclo NN — <objetivo do ciclo>"
```

Conflito: `git -C projeto merge --abort`, conte o que conflitou e pare; vira etapa nova. Com o merge, rode o `BUILD`. Depois:

1. `ciclo.md`: `Status: encerrado (AAAA-MM-DD)` e o commit final (`git -C projeto rev-parse HEAD`).
2. Apague as branches do ciclo: `git -C projeto branch --list "ciclo-NN" "ciclo-NN-*"` e `git -C projeto branch -d <branch>` em cada uma (o `-d` recusa a que não entrou na principal: mostre e não force; o hook nega a de etapa ainda em "Fazendo").
3. `git -C projeto push origin <principal>` (pede confirmação). Sem remoto, diga que o projeto só existe nesta pasta, inclusive o que já foi publicado, e pergunte se cria o remoto agora (padrão: não; a resposta vai para "Repositório" de `.claude/rules/projeto.md`).

## 5. Versão e quadro

Pela linha "Versão" de `.claude/rules/projeto.md` e pelo que o usuário disser:

- **O projeto usa versão e este ciclo gerou uma** (padrão quando houve etapa de `deploy` de pacote ou versão): confirme a versão (`vMAIOR.MENOR.CORRECAO`, a sugerida pela etapa ou a próxima depois da última de "Homologado"; primeira: `v0.1.0`) e onde foi publicada ou validada. No quadro, as etapas do ciclo viram uma linha em "Homologado" sob `### vX.Y.Z — AAAA-MM-DD — <onde>`: `[ciclo] Ciclo N — <objetivo> — itens #... — <ciclo>/ciclo.md`. Com o ok, a tag no commit publicado registrado na etapa de `deploy` (sem etapa de deploy: o commit de merge):
  ```bash
  git -C projeto tag -a vX.Y.Z <commit> -m "vX.Y.Z"
  ```
  ```bash
  git -C projeto push origin vX.Y.Z
  ```
  Projeto com branch de release (linha "Versão"): `git -C projeto branch release/X.Y.Z vX.Y.Z` e o push dela, com o ok.
- **Ainda não publicado:** as etapas do ciclo viram uma linha `[ciclo] Ciclo N — <objetivo> — itens #... — encerrado AAAA-MM-DD — <ciclo>/ciclo.md` em "Feito". Na publicação, um ciclo curto ou o próximo encerramento move a linha para "Homologado".
- **O projeto não usa versão:** a mesma linha vai para o topo de `privado/docs/historico.md`, sob `### Ciclo NN — AAAA-MM-DD (sem versão)`.

"Homologado" guarda as 3 versões mais recentes; as anteriores vão para o topo de `privado/docs/historico.md`. "Situação": ciclo "nenhum aberto", sem sessão, próximo passo "`/construtor-iniciar` num gerente novo".

## 6. Fechar

Diga para fechar esta sessão: o próximo trabalho começa numa sessão nova no Root, com `/construtor-iniciar`.

## Cancelar

Cancelar não exige build nem critérios. Só desfaz o que está no git: o que foi alterado fora dele continua lá, e quem decide é o usuário. Os documentos em `privado/` ficam como registro.

1. Mostre o ciclo, o que está em "Feito" e em andamento, e o motivo (`$ARGUMENTS` pode trazer). Peça uma confirmação explícita citando o número do ciclo.
2. **Fora do git.** Junte as "Alterações fora do git" dos arquivos de `<ciclo>/etapas/` (inclusive o código que um `deploy` deixou no destino, com o commit) e pergunte, numa rodada, o que o usuário desfaz, como e quando. Não desfaça nada sozinho. Ciclo curto que já entrou na principal continua valendo: só informe.
3. **Guardar.** Algo não commitado: commit na branch atual, `Andamento: ciclo NN cancelado, trabalho guardado`. Em `ciclo.md`: `Status: cancelado (AAAA-MM-DD)`, o motivo e o que o usuário decidiu. `git -C projeto switch <principal>`. As branches `ciclo-NN` e `ciclo-NN-*` ficam guardadas: não apague.
4. **O que deixa de valer.** Liste as decisões do ciclo e o que ele mudou em `objetivo.md` e `arquitetura.md`, com a proposta (padrão: deixa de valer). Na decisão que não vale mais: `Status: cancelada com o ciclo NN (AAAA-MM-DD)`. No objetivo e na arquitetura, desfaça com o ok o que só existia pelo ciclo.
5. **Quadro.** As etapas do ciclo saem de "A fazer", "Fazendo" e "Feito" (os números ficam no `ciclo.md` e não voltam); ciclo curto que entrou na principal fica em "Feito"; se o usuário quiser retomar a ideia, um item no Backlog dizendo que o trabalho está na branch `ciclo-NN`; "Situação" com "nenhum aberto" e próximo passo "`/construtor-iniciar` num gerente novo".
6. Diga para fechar esta sessão. O número do ciclo não é reutilizado.
