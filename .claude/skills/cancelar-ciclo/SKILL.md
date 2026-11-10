---
name: cancelar-ciclo
description: Roda no gerente, a qualquer momento, esteja o ciclo funcionando ou não. Cancela o ciclo atual sem levar código para a principal, guarda as branches, mostra o que ficou fora do git, marca as decisões do ciclo que deixam de valer e deixa o projeto sem ciclo aberto.
disable-model-invocation: true
argument-hint: "[motivo, opcional]"
---

# Cancelar ciclo

Você é o **gerente** (veja "Papéis" no `CLAUDE.md`). Cancelar não exige build nem critérios de aceite. Cancelar só desfaz o que está no git: o que foi alterado fora dele continua lá, e quem decide o que fazer é o usuário.

Os documentos ficam em `privado/`, fora do git: o cancelamento não os desfaz. O `ciclo.md` e as pesquisas continuam valendo como registro; as decisões do ciclo deixam de valer, e o passo 4 marca isso.

`NN` é o número do ciclo, `<ciclo>` é a pasta dele e `<principal>` é o `BRANCH_PRINCIPAL` de `.claude/comandos.conf`.

## 1. Confirmar

1. Leia `privado/QUADRO.md` e `<ciclo>/ciclo.md`. Sem ciclo aberto, diga isso e pare.
2. Se existe sessão vinculada ainda trabalhando, pare e peça ao usuário para interrompê-la: ela divide a pasta `projeto/` com este comando.
3. Mostre o ciclo, o que já está em "Feito" e o que está em andamento. Pergunte o motivo (`$ARGUMENTS` pode já trazer) e peça uma confirmação explícita, citando o número do ciclo.

## 2. Mostrar o que ficou fora do git

Junte a seção "Alterações fora do git" de cada arquivo em `<ciclo>/etapas/`. Mostre a lista e pergunte, item por item, se o usuário desfaz, como e quando. Não desfaça nada sozinho.

Correção de ciclo curto que já entrou na principal durante o ciclo continua valendo. Só informe.

## 3. Guardar o trabalho

1. Se `git -C projeto status` mostrar algo não commitado, faça o commit na branch atual com a mensagem `Andamento: ciclo NN cancelado, trabalho guardado`.
2. Grave em `ciclo.md` o `Status: cancelado (AAAA-MM-DD)`, o motivo e o que o usuário decidiu no passo 2.
3. Volte para a principal:
   ```bash
   git -C projeto switch <principal>
   ```
4. As branches `ciclo-NN` e `ciclo-NN-*` ficam guardadas. Não apague nada.

## 4. Marcar o que deixa de valer

Liste as decisões gravadas neste ciclo em `privado/docs/decisoes/` e, se o ciclo mudou `privado/docs/objetivo.md` ou `privado/docs/arquitetura.md`, o que mudou. Pergunte ao usuário, item por item, o que continua valendo. Em cada decisão que não vale mais, grave no topo `Cancelada com o ciclo NN (AAAA-MM-DD)`; no objetivo e na arquitetura, desfaça com o ok dele o que só existia por causa do ciclo.

No quadro: as etapas do ciclo saem de "A fazer" e "Fazendo"; "Situação" com ciclo "nenhum aberto" e próximo passo "`/iniciar` num gerente novo"; se o usuário quiser retomar a ideia um dia, um item no Backlog dizendo que o ciclo N foi cancelado e que o trabalho está na branch `ciclo-NN`.

## 5. Fechar

Diga ao usuário para fechar esta sessão. O número deste ciclo não é reutilizado. Para retomar a ideia, ele abre um ciclo novo com `/iniciar`.
