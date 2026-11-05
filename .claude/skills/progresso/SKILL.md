---
name: progresso
description: Roda no gerente depois que uma sessão de etapa termina. Um subagente confere a entrega; o gerente revisa com o usuário, decide (aprovar, corrigir, decidir) e atualiza estado.md e metricas.md.
disable-model-invocation: true
---

# Progresso

Você é o **gerente** (veja "Papéis" no `CLAUDE.md`). Não confie na memória desta conversa nem nos avisos das sessões vinculadas: a fonte é o que está em `Projeto_Documento/` e em `Projeto/`.

## 1. Situar

1. Leia `Projeto_Documento/estado.md` e ache a etapa atual e o arquivo `Projeto_Documento/etapas/NN-*.md`.
2. Veja o status da etapa na tabela do roadmap. Se for `pendente`, `planejada` ou `em andamento`, a sessão da etapa não fechou: diga ao usuário para voltar a ela (link da sessão) e pare.

## 2. Conferência (subagente)

O trabalho pesado não passa pelo seu contexto. Dispare **um** subagente (tipo `general-purpose`, só leitura e comandos de verificação, sem editar nada) com esta tarefa:

> Confira a entrega da etapa NN. Leia `Projeto_Documento/etapas/NN-*.md` e `.claude/comandos.conf`. Rode o `BUILD` e, se estiver preenchido, o `TESTE` dentro de `Projeto/`. Leia `git -C Projeto status` e `git -C Projeto diff` (e arquivos novos). Para cada critério de aceite, diga se a evidência registrada existe e se bate com o código; reexecute o que for barato. Se a linha "Testes" do `CLAUDE.md` for `por etapa`, confira se o código novo tem testes ou se "Notas da execução" explica por que não tem. Confira se há documentação ou arquivo sensível em `Projeto/`. Aponte código fora do plano, duplicação e falha silenciosa. Não edite nada. Responda em no máximo 15 linhas: build (ok/falhou + trecho), testes (ok/falhou/não se aplica + trecho), critérios (ok/faltando, um por linha), fora do plano, riscos, decisões pendentes.

## 3. Revisão com o usuário

1. Mostre o veredito do subagente, o status da etapa no roadmap e a seção "Fechamento" do arquivo da etapa.
2. Pergunte se o usuário já testou, se ficou como esperado e se há algo a ajustar.
3. Decida com ele, uma das saídas:
   - **Aprovada:** marque `revisada` no roadmap e registre a conversa na seção "Revisão" do arquivo da etapa.
   - **Correção:** liste os itens e grave-os na seção "Revisão" como pendentes. Volte a etapa para `em andamento` no roadmap. O usuário volta à sessão da etapa (link) ou, se ele pedir, você envia os itens a ela por mensagem. Depois, rode `/progresso` de novo.
   - **Bloqueada ou decisão pendente:** resolva com o usuário o que falta ou a decisão. Registre a decisão em `Projeto_Documento/decisoes/` e ajuste o roadmap com o ok. Grave na seção "Revisão" o que muda no plano e volte a etapa para `planejada` no roadmap: a sessão da etapa ajusta o plano, mostra de novo e pede o ok. O usuário volta à sessão da etapa (link) ou você envia por mensagem, se ele pedir. Se não der para resolver agora, a etapa fica como está e o motivo vai para "Decisões pendentes" do `estado.md`.
   - **Problema maior:** vira etapa nova ou item em "Fora do escopo e ideias" do roadmap, com o ok. A etapa atual segue por uma das saídas acima.

## 4. Registrar (sempre, nesta ordem)

1. Atualize a linha da etapa em `Projeto_Documento/metricas.md` (uma linha por etapa; crie se não existir, no modelo de `.claude/modelos/documentos.md`):
   - rodadas de correção: some 1 a cada saída **Correção**;
   - bloqueios por decisão: some 1 a cada saída **Bloqueada ou decisão pendente**;
   - compactou: o da etapa está no "Fechamento" dela; o seu, você sabe;
   - custo: pergunte ao usuário (painel de uso do app). Se ele não souber, `—`.
2. Atualize `Projeto_Documento/estado.md`: etapa atual, sessão da etapa (`nenhuma aberta` quando aprovada), decisões pendentes, próximo passo. Este é o último passo: um gerente novo tem que conseguir continuar só com ele.

## 5. Saúde do gerente

Confira o tamanho do seu contexto (ferramenta de uso de sessão). Se passou de 60% ou se esta conversa já foi compactada, recomende ao usuário abrir um gerente novo no Root: `estado.md` tem tudo o que ele precisa.

Encerre indicando o próximo passo: `/iniciar-etapa`, voltar à sessão da etapa, ou `/encerrar-projeto` se todas as etapas estiverem `revisadas`.
