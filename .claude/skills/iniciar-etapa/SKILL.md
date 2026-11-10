---
name: iniciar-etapa
description: Roda no gerente. Confere se a próxima etapa do ciclo pode começar, resolve as decisões que ela precisa, marca no quadro e abre uma sessão vinculada só para ela, que executa o fluxo da skill etapa.
disable-model-invocation: true
argument-hint: "[número da etapa, opcional]"
---

# Iniciar etapa

Você é o **gerente** (veja "Papéis" no `CLAUDE.md`). Esta skill não executa a etapa: ela abre uma sessão vinculada que executa.

`NN` é o número do ciclo, `EE` é o da etapa, com dois dígitos, e `<ciclo>` é a pasta do ciclo indicada na "Situação" do quadro.

## 1. Situar

1. Leia `privado/QUADRO.md`. Sem quadro ou com "nenhum aberto", indique `/iniciar` e pare.
2. Leia `<ciclo>/ciclo.md`. Se não estiver `aprovado`, indique `/iniciar` e pare.
3. Descubra a etapa: a de `$ARGUMENTS` ou a primeira do ciclo que está em "A fazer". Se todas estão em "Feito", indique `/encerrar-ciclo` e pare.
4. **Sequência.** A etapa anterior do ciclo precisa estar em "Feito". Se não estiver, diga onde ela está e indique `/progresso`. Pare.
5. **Uma sessão por vez.** Se a "Situação" aponta uma sessão aberta, ou há item em "Fazendo", pare e avise: duas sessões escrevendo em `projeto/` se sobrescrevem.
6. Rode `git -C projeto status`. A pasta tem de estar limpa e na branch `ciclo-NN`. Se não estiver, mostre e pare.
7. **Decisões desta etapa.** Veja em "Decidir depois" do `ciclo.md` e em "Decisões pendentes" do quadro o que esta etapa precisa. Resolva agora com o usuário, com base nas pesquisas e provas já feitas, e grave em `privado/docs/decisoes/`. A sessão da etapa só sabe o que estiver escrito.

## 2. Registrar e abrir

Mostre ao usuário qual etapa vai abrir e peça o ok. Com o ok:

1. No quadro, leve o item de "A fazer" para "Fazendo", com a sessão e a data, e atualize a "Situação".
2. Abra **uma** sessão vinculada (ferramenta de iniciar sessão do app, `start_session`):
   - `initiation: "user_asked"` (o usuário acabou de dar o ok; sem isso, o app só mostra uma sugestão);
   - `context: "fresh"` (nunca `fork`: a etapa parte dos documentos, não desta conversa);
   - `use_worktree: false` (mesma pasta Root, para carregar `CLAUDE.md`, skills e hooks do kit);
   - `model` e `effort`: os valores de `MODELO_ETAPA` e `ESFORCO_ETAPA` de `.claude/comandos.conf`; se estiverem vazios, não passe esses campos;
   - `name`: `ciclo-NN-etapa-EE`; `title`: `Ciclo NN, etapa EE — <nome da etapa>`;
   - `prompt` mínimo, sem repassar contexto que deveria estar nos documentos:
     > Você é a sessão da etapa EE do ciclo NN deste projeto. Leia `.claude/skills/etapa/SKILL.md` e siga esse fluxo para a etapa EE.
   - `background` (o app exige pelo menos 80 caracteres):
     > Este projeto segue o kit Construtor Equipe. Os documentos em `privado/` são a fonte da verdade: o que não está escrito lá não existe. O gerente é outra sessão; esta cuida só da etapa EE do ciclo NN e, ao fechar, registra no arquivo da etapa como ela terminou.

   Se sentir vontade de explicar algo no `prompt` ou no `background`, é sinal de que falta isso nos documentos: grave lá primeiro.
3. Diga ao usuário, com o link da sessão, que a etapa continua lá (perguntas, plano e execução) e que, quando ela terminar, ele volta aqui e roda `/progresso`.
