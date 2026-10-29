---
name: iniciar-etapa
description: Roda no gerente. Confere se a próxima etapa pode começar e abre uma sessão vinculada só para ela, que executa o fluxo da skill etapa.
disable-model-invocation: true
argument-hint: "[número da etapa, opcional]"
---

# Iniciar etapa

Você é o **gerente**. Esta skill não executa a etapa: ela abre uma sessão vinculada que executa. Você não escreve código nem mexe em `Projeto/`.

## 1. Situar

1. Leia `Projeto_Documento/estado.md` e `Projeto_Documento/roadmap.md`. Se não existirem ou não estiverem `aprovado`, indique `/iniciar-projeto` e pare.
2. Descubra a etapa: a informada em `$ARGUMENTS` ou, senão, a primeira `pendente` do roadmap.
3. **Trava de sequência.** A etapa anterior precisa estar `revisada`. Se estiver `em andamento`, `planejada` ou `concluída`, diga qual é e indique `/progresso` (ou voltar à sessão dela). Pare.
4. **Uma etapa por vez.** Se `estado.md` aponta uma sessão de etapa ativa, ou se existe sessão vinculada de etapa ainda trabalhando, pare e avise: duas sessões escrevendo em `Projeto/` se sobrescrevem.
5. **Decisões pendentes.** Se `estado.md` lista decisões pendentes que afetam esta etapa, resolva com o usuário antes, registre em `Projeto_Documento/decisoes/` e atualize `estado.md`. A sessão da etapa só sabe o que estiver escrito.

## 2. Abrir a sessão da etapa

Mostre ao usuário qual etapa vai abrir e peça o ok. Com o ok, abra **uma** sessão vinculada:

- contexto `fresh` (nunca `fork`: a etapa parte dos documentos, não desta conversa);
- `use_worktree: false` (mesma pasta Root, para carregar `CLAUDE.md`, skills e hooks do kit);
- modelo Opus (`claude-opus-5-5`), esforço `medium`;
- nome `etapa-NN`, título `Etapa NN — <nome da etapa>`;
- `prompt` mínimo, sem repassar contexto que deveria estar nos documentos:
  > Você é a sessão da etapa NN deste projeto. Leia `.claude/skills/etapa/SKILL.md` e siga esse fluxo para a etapa NN.
- `background`: uma frase dizendo que o projeto segue o kit, que os documentos em `Projeto_Documento/` são a fonte da verdade e que o gerente é outra sessão.

Se sentir vontade de explicar algo no `prompt` ou no `background`, é sinal de que falta isso nos documentos: grave lá primeiro.

## 3. Registrar

1. Atualize `Projeto_Documento/estado.md`: etapa atual, status `em andamento`, sessão `etapa-NN`, data de início.
2. Diga ao usuário, com o link da sessão, que a etapa continua lá (perguntas, plano e execução) e que, quando ela terminar, ele volta aqui e roda `/progresso`.
