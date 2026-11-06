---
name: cancelar-ciclo
description: Roda no gerente, a qualquer momento, esteja o ciclo funcionando ou não. Cancela o ciclo atual sem levar nada para a principal, guarda as branches, mostra o que ficou fora do git e deixa o projeto sem ciclo aberto.
disable-model-invocation: true
argument-hint: "[motivo, opcional]"
---

# Cancelar ciclo

Você é o **gerente** (veja "Papéis" no `CLAUDE.md`). Cancelar não exige build nem critérios de aceite. Cancelar só desfaz o que está no git: o que foi alterado fora dele continua lá, e quem decide o que fazer é o usuário.

`<ciclo>` é a pasta do ciclo atual em `estado.md`, `NN` é o número dele e `<principal>` é o `BRANCH_PRINCIPAL` de `.claude/comandos.conf`.

## 1. Confirmar

1. Leia `Projeto_Documento/estado.md`, `<ciclo>/ciclo.md` e `<ciclo>/roadmap.md`. Sem ciclo aberto, diga isso e pare.
2. Se existe sessão vinculada de etapa ou de correção ainda trabalhando, pare e peça ao usuário para interrompê-la: ela divide a pasta `Projeto/` com este comando.
3. Mostre o ciclo, o que já foi aprovado e o que está em andamento. Pergunte o motivo (`$ARGUMENTS` pode já trazer) e peça uma confirmação explícita, citando o número do ciclo.

## 2. Mostrar o que ficou fora do git

Leia em `<ciclo>/etapas/` e `<ciclo>/correcoes/` as seções "Alterações fora do git" e "Correções de bug antigo", e leia "Mudanças nos documentos" em `ciclo.md`. Mostre as listas e pergunte, item por item:

- **Alterações fora do git** (banco, servidor, serviços): o usuário decide se desfaz, como e quando. Não desfaça nada sozinho.
- **Correções de bug antigo** feitas dentro do ciclo (caso 2): elas vão embora com o ciclo, porque não chegaram à principal. Pergunte quais anotar em `Projeto_Documento/ideias.md`.
- **Mudanças nos documentos**: pergunte quais voltam ao texto anterior. Com o ok, restaure e registre. Decisões deste ciclo que deixam de valer ficam com `Status: cancelada`.
- **Correções que já chegaram à principal** (caso 3): continuam valendo. Só informe.

## 3. Guardar o trabalho

1. Se `git -C Projeto status` mostrar algo não commitado, faça o commit na branch atual com a mensagem `Andamento: ciclo NN cancelado, trabalho guardado` (a branch atual nunca é a principal, e a trava de commit recusaria).
2. Volte para a principal:
   ```bash
   git -C Projeto switch <principal>
   ```
3. As branches `ciclo-NN` e `ciclo-NN-*` ficam guardadas. Não apague nada. Nada entra na principal.

## 4. Registrar

1. Em `ciclo.md`, grave `Status: cancelado (AAAA-MM-DD)`, o motivo e o que o usuário decidiu no passo 2. O roadmap do ciclo fica como estava.
2. Acrescente uma linha sobre o cancelamento no resumo de `<ciclo>/metricas.md`.
3. Atualize `Projeto_Documento/estado.md`: `sem ciclo aberto`, último ciclo fechado como cancelado, último commit da principal, próximo passo `/novo-ciclo` num gerente novo.
4. Diga ao usuário para fechar esta sessão. O número deste ciclo não é reutilizado. Para retomar a ideia, ele abre um ciclo novo.
