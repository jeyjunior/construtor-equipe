---
name: progresso
description: Roda no gerente depois que uma sessão de etapa termina. Um subagente confere a entrega; o gerente revisa com o usuário, decide (aprovar, corrigir, decidir) e atualiza estado.md e metricas.md.
disable-model-invocation: true
---

# Progresso

Você é o **gerente**. Não confie na memória desta conversa nem nos avisos das sessões vinculadas: a fonte é o que está em `Projeto_Documento/` e em `Projeto/`. Você não edita `Projeto/`.

## 1. Situar

1. Leia `Projeto_Documento/estado.md` e ache a etapa atual e o arquivo `Projeto_Documento/etapas/NN-*.md`.
2. Leia o "Status final" do arquivo da etapa. Sem status final, a sessão da etapa não fechou: diga ao usuário para voltar a ela (link da sessão) e pare.

## 2. Conferência (subagente)

O trabalho pesado não passa pelo seu contexto. Dispare **um** subagente (tipo `general-purpose`, só leitura e comandos de verificação, sem editar nada) com esta tarefa:

> Confira a entrega da etapa NN. Leia `Projeto_Documento/etapas/NN-*.md` e `.claude/comandos.conf`. Rode o `BUILD` dentro de `Projeto/`. Leia `git -C Projeto status` e `git -C Projeto diff` (e arquivos novos). Para cada critério de aceite, diga se a evidência registrada existe e se bate com o código; reexecute o que for barato. Confira se há documentação ou arquivo sensível em `Projeto/`. Aponte código fora do plano, duplicação e falha silenciosa. Não edite nada. Responda em no máximo 15 linhas: build (ok/falhou + trecho), critérios (ok/faltando, um por linha), fora do plano, riscos, decisões pendentes.

## 3. Revisão com o usuário

1. Mostre o veredito do subagente e o "Status final" da etapa.
2. Pergunte se o usuário já testou, se ficou como esperado e se há algo a ajustar.
3. Decida com ele, uma das saídas:
   - **Aprovada:** marque `revisada` no roadmap e no arquivo da etapa; registre a conversa na seção "Revisão" do arquivo da etapa.
   - **Correção:** liste os itens e grave-os na seção "Revisão" como pendentes. O usuário volta à sessão da etapa (link) ou, se ele pedir, você envia os itens a ela por mensagem. A etapa volta a `em andamento`. Depois, rode `/progresso` de novo.
   - **Decisão pendente:** discuta, registre em `Projeto_Documento/decisoes/` e ajuste roadmap ou etapa com o ok.
   - **Problema maior:** vira etapa nova ou item em "Fora do escopo e ideias" do roadmap, com o ok.

## 4. Registrar (sempre, nesta ordem)

1. Acrescente a linha da etapa em `Projeto_Documento/metricas.md` (modelo em `.claude/modelos/documentos.md`). Rodada de correção conta a cada `/progresso` que não aprovou.
2. Atualize `Projeto_Documento/estado.md`: etapa, status, decisões pendentes, próximo passo. Este é o último passo: um gerente novo tem que conseguir continuar só com ele.

## 5. Saúde do gerente

Confira o tamanho do seu contexto (ferramenta de uso de sessão). Se passou de 60% ou se esta conversa já foi compactada, recomende ao usuário abrir um gerente novo no Root: `estado.md` tem tudo o que ele precisa.

Encerre indicando o próximo passo: `/iniciar-etapa`, voltar à sessão da etapa, ou `/encerrar-projeto` se todas as etapas estiverem `revisadas`.
