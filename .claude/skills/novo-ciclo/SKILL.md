---
name: novo-ciclo
description: Roda num gerente novo, com o projeto sem ciclo aberto. Compara documentos e código, define o objetivo do ciclo, tira as dúvidas, vê o impacto nos documentos, cria as etapas e abre a branch do ciclo. Não escreve código.
disable-model-invocation: true
argument-hint: "[o que o ciclo deve fazer, opcional]"
---

# Novo ciclo

Esta sessão é o **gerente** deste ciclo (veja "Papéis" no `CLAUDE.md`). Todo trabalho depois do ciclo 1 começa aqui: bug, melhoria ou funcionalidade, simples ou complexo. A estrutura é sempre a mesma; num ciclo pequeno há menos a perguntar, não menos passos.

Nunca avance de passo sem um "ok" explícito do usuário. Não escreva código nem rode geradores. Use os modelos de `.claude/modelos/documentos.md`.

Neste fluxo, `NN` é o número do ciclo com dois dígitos, `<ciclo>` é a pasta `Projeto_Documento/ciclos/NN-nome` e `<principal>` é o `BRANCH_PRINCIPAL` de `.claude/comandos.conf`.

## 1. Conferir se pode abrir

1. **Gerente novo.** Se esta conversa já fez qualquer outra coisa antes deste comando, pare e peça ao usuário para abrir uma sessão nova no Root e rodar `/novo-ciclo` lá.
2. Leia `Projeto_Documento/estado.md`:
   - arquivo ausente: indique `/iniciar-projeto` e pare;
   - `ciclo N em andamento`: pare. Um ciclo só começa depois que o anterior fecha: indique `/encerrar-ciclo` ou `/cancelar-ciclo`;
   - `sem ciclo aberto`: siga.
3. **Retomada.** Se a pasta mais recente em `Projeto_Documento/ciclos/` tem `ciclo.md` com `Status: rascunho`, retome do primeiro passo que ainda não foi registrado nela e diga ao usuário de onde está retomando.
4. Rode `git -C Projeto status`. Se houver algo não commitado, mostre e pare: a branch do ciclo não pode nascer com trabalho alheio.

## 2. Comparar documentos e código

Dispare **um** subagente (tipo `general-purpose`, só leitura):

> Compare a documentação com o código. Leia `Projeto_Documento/objetivo.md`, `arquitetura.md`, `.claude/comandos.conf` e o `Último commit da principal` em `estado.md`. Rode `git -C Projeto log --oneline <último commit>..<principal>` e olhe em `Projeto/` o que os documentos descrevem. Não edite nada. Responda em no máximo 15 linhas: commits fora do fluxo do kit, o que os documentos dizem e o código não faz, o que o código faz e os documentos não dizem, comandos que não funcionam mais.

Mostre o resultado. Com o ok, corrija os documentos antes de planejar (para `objetivo.md`, vale a regra de aprovação do `CLAUDE.md`). Sem diferenças, diga isso e siga.

## 3. Definir o que entra

1. Mostre o que está como `avaliar` em `Projeto_Documento/ideias.md` e pergunte o que entra, da lista ou novo (`$ARGUMENTS` pode já trazer).
2. Um ciclo tem **um** objetivo. Se vierem dois objetivos independentes, proponha dois ciclos e deixe um em `ideias.md`.
3. O número é o maior em `Projeto_Documento/ciclos/` mais 1, contando os cancelados: número de ciclo não é reutilizado.
4. Crie `<ciclo>/ciclo.md` com `Status: rascunho`, o objetivo e o critério de pronto, que precisa ser verificável.
5. Marque os itens usados de `ideias.md` como `virou ciclo N`.

## 4. Tirar as dúvidas

Pergunte só sobre o que é novo, usando o roteiro: escopo; dados; números com unidade; casos de erro; o que fica de fora; como saber que está pronto. Siga a regra de perguntas do `CLAUDE.md`. Grave as respostas em "Respostas" de `ciclo.md`.

## 5. Ver o impacto

Veja se o ciclo muda objetivo, arquitetura, convenções ou a escolha de testes. Para cada mudança:

1. Mostre o texto novo e peça aprovação.
2. Com o ok, atualize o documento e registre a decisão em `Projeto_Documento/decisoes/`.
3. Liste em "Mudanças nos documentos" de `ciclo.md` o documento, o texto anterior e o novo. O `/cancelar-ciclo` usa essa lista.

Sem mudanças, escreva `nenhuma` nessa seção.

## 6. Criar as etapas

1. Proponha etapas no mesmo padrão do `/iniciar-projeto`: pequenas, cada uma cabendo numa sessão, com entregáveis e critérios de aceite verificáveis. A numeração recomeça em 1 em cada ciclo.
2. Se o projeto tiver testes, toda etapa com lógica a testar traz o critério "testes passam".
3. Ajuste até o usuário aprovar. Grave `<ciclo>/roadmap.md` com `Status: aprovado (AAAA-MM-DD)` e todas as etapas como `pendente`.

## 7. Abrir o ciclo

Com o ok do usuário:

1. Crie a branch a partir da principal:
   ```bash
   git -C Projeto switch <principal>
   ```
   ```bash
   git -C Projeto switch -c ciclo-NN
   ```
2. Em `ciclo.md`, grave a branch, o commit inicial (`git -C Projeto rev-parse HEAD`) e `Status: aprovado (AAAA-MM-DD)`.
3. Crie `<ciclo>/metricas.md` no modelo.
4. Atualize `Projeto_Documento/estado.md`: `ciclo N em andamento`, ciclo atual, próximo passo `/iniciar-etapa`. Este é o último passo.
5. Encerre indicando `/iniciar-etapa`. Não comece a etapa.
