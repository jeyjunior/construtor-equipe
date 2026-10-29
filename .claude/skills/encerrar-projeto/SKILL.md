---
name: encerrar-projeto
description: Roda no gerente quando todas as etapas estão revisadas. Fecha as métricas e registra os padrões observados no projeto em Projeto_Documento/padroes-observados.md, para análise entre projetos.
disable-model-invocation: true
---

# Encerrar projeto

Você é o **gerente**. Esta skill não mexe em `Projeto/`.

## 1. Conferir

Leia `Projeto_Documento/estado.md` e o roadmap. Se alguma etapa não está `revisada`, liste quais e pare.

## 2. Levantamento (subagente)

Dispare **um** subagente (tipo `general-purpose`, só leitura) com esta tarefa:

> Leia `Projeto_Documento/` inteiro (menos `sensivel/`): roadmap, `etapas/`, `decisoes/`, `metricas.md`, `arquitetura.md`, e `git -C Projeto log --stat`. Procure o que se repetiu ao longo do projeto: problemas e bugs com a mesma causa, perguntas feitas em várias etapas, decisões parecidas, estruturas de código repetidas, correções pedidas no `/progresso`, desvios do plano, comandos e passos manuais repetidos. Só conta o que apareceu 2 vezes ou mais, com onde apareceu. Não edite nada. Devolva no formato da seção "padroes-observados.md" de `.claude/modelos/documentos.md`.

## 3. Revisão com o usuário

1. Mostre o rascunho. Pergunte o que ele percebeu e o subagente não pegou.
2. Para cada padrão, defina com ele o candidato: skill, regra (`.claude/rules/`), modelo, hook, convenção ou nada.
3. Com o ok, grave `Projeto_Documento/padroes-observados.md`.

## 4. Fechar

1. Acrescente o resumo final em `Projeto_Documento/metricas.md` (totais e médias).
2. Atualize `Projeto_Documento/estado.md` com `Status: projeto encerrado (AAAA-MM-DD)`.
3. Lembre o usuário de que `padroes-observados.md` segue o mesmo formato em todo projeto, para ser comparado com os de outros projetos.
