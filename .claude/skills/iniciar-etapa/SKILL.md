---
name: iniciar-etapa
description: Roda no gerente. Confere se a próxima etapa do ciclo pode começar e abre uma sessão vinculada só para ela, que executa o fluxo da skill etapa.
disable-model-invocation: true
argument-hint: "[número da etapa, opcional]"
---

# Iniciar etapa

Você é o **gerente** (veja "Papéis" no `CLAUDE.md`). Esta skill não executa a etapa: ela abre uma sessão vinculada que executa.

`<ciclo>` é a pasta do ciclo atual em `estado.md`, `NN` é o número do ciclo e `EE` é o número da etapa, com dois dígitos.

## 1. Situar

1. Leia `Projeto_Documento/estado.md`. Se ele não existir, indique `/iniciar-projeto` e pare. Se disser `sem ciclo aberto`, indique `/novo-ciclo` num gerente novo e pare.
2. Leia `<ciclo>/ciclo.md` e `<ciclo>/roadmap.md`. Se não estiverem `aprovado`, indique o comando que abriu o ciclo (`/iniciar-projeto` ou `/novo-ciclo`) e pare.
3. Descubra a etapa: a informada em `$ARGUMENTS` ou, senão, a primeira `pendente` do roadmap do ciclo. Se todas estiverem `revisada`, indique `/encerrar-ciclo` e pare.
4. **Trava de sequência.** A etapa anterior do ciclo precisa estar `revisada`. A etapa 1 não tem anterior. Se não estiver, diga em que status ela está e indique `/progresso` (ou voltar à sessão dela). Pare.
5. **Uma sessão por vez.** Se `estado.md` aponta uma sessão de etapa ou de correção aberta, ou se existe sessão vinculada ainda trabalhando, pare e avise: duas sessões escrevendo em `Projeto/` se sobrescrevem.
6. **Decisões pendentes.** Se `estado.md` lista decisões pendentes que afetam esta etapa, resolva com o usuário antes, registre em `Projeto_Documento/decisoes/` e atualize `estado.md`. A sessão da etapa só sabe o que estiver escrito.

## 2. Abrir a sessão da etapa

Mostre ao usuário qual etapa vai abrir e peça o ok. Com o ok, abra **uma** sessão vinculada:

- `initiation: "user_asked"` (o usuário acabou de dar o ok; sem isso, o app só mostra uma sugestão em vez de abrir a sessão);
- contexto `fresh` (nunca `fork`: a etapa parte dos documentos, não desta conversa);
- `use_worktree: false` (mesma pasta Root, para carregar `CLAUDE.md`, skills e hooks do kit);
- modelo Opus (`claude-opus-5-5`), esforço `medium`;
- nome `ciclo-NN-etapa-EE`, título `Ciclo NN, etapa EE — <nome da etapa>`;
- `prompt` mínimo, sem repassar contexto que deveria estar nos documentos:
  > Você é a sessão da etapa EE do ciclo NN deste projeto. Leia `.claude/skills/etapa/SKILL.md` e siga esse fluxo para a etapa EE.
- `background` com este texto (o app exige pelo menos 80 caracteres):
  > Este projeto segue o kit Construtor Equipe. Os documentos em `Projeto_Documento/` são a fonte da verdade: o que não está escrito lá não existe. O gerente é outra sessão; esta cuida só da etapa EE do ciclo NN e, ao fechar, marca o status dela no roadmap do ciclo.

Se sentir vontade de explicar algo no `prompt` ou no `background`, é sinal de que falta isso nos documentos: grave lá primeiro.

## 3. Registrar

1. Atualize `Projeto_Documento/estado.md`: etapa atual, sessão `ciclo-NN-etapa-EE`, data de início. O status da etapa fica só no roadmap do ciclo.
2. Diga ao usuário, com o link da sessão, que a etapa continua lá (perguntas, plano e execução) e que, quando ela terminar, ele volta aqui e roda `/progresso`.
