---
name: construtor-iniciar
description: Entrada do gerente. Descobre onde o projeto está (conversão, projeto novo, ciclo em andamento, sem ciclo aberto) e segue pelo caminho certo. Para trabalho novo, absorve o contexto que o usuário der, pergunta numa rodada só o que falta (com padrão sugerido), planeja objetivo, decisões e etapas e abre o ciclo com um ok. Use quando o usuário quiser começar um projeto, um ciclo ou um trabalho novo. Não escreve código.
argument-hint: "[o que você quer, com todo o contexto que tiver]"
---

# Iniciar

Esta sessão é o **gerente** (veja "Papéis" e "Contexto primeiro" no `CLAUDE.md`).

- Não escreva código nem rode geradores (`dotnet new`, `npm init`): é trabalho de etapa.
- Não invente respostas: o que o usuário não souber e não tiver padrão razoável vira incógnita (pesquisa) ou "Em aberto".
- Modelos em `.claude/modelos/documentos.md`. Documentos curtos, em português.
- Enquanto o planejamento não fecha, `ciclo.md` (e, em projeto novo, `objetivo.md`) fica com `Status: rascunho`: é assim que a retomada sabe onde parou.

`NN` é o número do ciclo com dois dígitos, `<ciclo>` é `privado/docs/ciclos/NN-nome` e `<principal>` é o `BRANCH_PRINCIPAL` de `.claude/comandos.conf`.

## 1. Onde o projeto está

Siga o primeiro caso que valer:

1. **Há um projeto em `conversor/`** (liste só o primeiro nível) **e não existe `privado/QUADRO.md`:** siga `.claude/skills/construtor-converter/SKILL.md` (se o usuário já pediu a conversão; senão, pergunte numa linha).
2. **Não existe `privado/QUADRO.md`:** projeto novo. Crie as pastas que faltarem (`projeto/`, `privado/docs/`, `privado/parametros/`) e vá ao passo 2. Se houver `privado/docs/objetivo.md` em `rascunho`, retome de onde parou.
3. **Há um `privado/docs/ciclos/*/ciclo.md` em `rascunho`:** um planejamento parou no meio. `01-conversao`: siga o converter, que retoma. Senão, mostre de onde parou e siga dali com o mesmo número (padrão), ou descarte se o usuário pedir (`Status: cancelado (AAAA-MM-DD)` e o motivo; o número não volta).
4. **O quadro mostra um ciclo aberto:** mostre a "Situação" e siga `.claude/skills/construtor-proxima-etapa/SKILL.md`. Pedido novo trazido agora vai para o Backlog.
5. **O quadro mostra "nenhum aberto":**
   1. Se esta conversa já encerrou outro ciclo, peça uma sessão nova no Root: cada ciclo tem o seu gerente.
   2. `git -C projeto status`: algo não commitado, mostre e pare.
   3. `git -C projeto log --first-parent --oneline -15 <principal>`: commits fora do kit (fora de `Merge:` e `Docs:`) desde o último ciclo? Dispare um subagente só leitura (`.claude/skills/construtor-subagente/SKILL.md`) para comparar `objetivo.md` e `arquitetura.md` com o código, em até 10 linhas, e corrija os documentos junto com o plano do passo 3.
   4. Junte o pedido (`$ARGUMENTS` e o que o usuário escrever), o Backlog e as "Lições" do último `ciclo.md`.
   5. Classifique e diga qual é: **ciclo curto** (cabe numa sessão, sem decisão de projeto, pesquisa nem alteração fora do git: siga `.claude/skills/construtor-ciclo-curto/SKILL.md` nesta sessão) ou **ciclo** (passo 2). Na dúvida, ciclo curto se couber numa sessão.

## 2. Entender (uma rodada)

Monte o briefing a partir do que já existe: o pedido, o contexto que o usuário deu, `objetivo.md`, `arquitetura.md`, as decisões e o Backlog. Os campos:

- o que deve existir no fim, para quem e por quê;
- limite de custo e o que o usuário já tem (contas, máquinas, serviços);
- o que fica de fora;
- critério de pronto: comportamento observável ou número com unidade;
- o que entra: testes automatizados, publicação (deploy ou pacote), medição de resultados;
- tecnologia e caminhos que o usuário já escolheu (viram decisão).

Mostre a tabela dos campos com a origem de cada um: **dito** (por ele), **padrão** (sugerido por você, com o valor) ou **falta**. Pergunte numa rodada só o que falta e muda o trabalho, cada pergunta com o padrão sugerido. "Ok com os padrões" aceita todos. O que não bloqueia o planejamento vai para "Decidir depois" do `ciclo.md` ou para "Decisões pendentes" do quadro.

Grave o rascunho: em projeto novo, `privado/docs/objetivo.md`; sempre, `<ciclo>/ciclo.md` com "Objetivo", "Critério de pronto" e "Briefing" (com a origem: dito ou padrão). O número do ciclo é o maior já usado em `privado/docs/ciclos/` mais 1, contando os cancelados. Um ciclo tem **um** objetivo: dois objetivos independentes viram dois ciclos, e um vai para o Backlog.

## 3. Planejar

1. **Incógnitas.** Liste só o que muda o desenho e ninguém sabe (é possível? é pago? quais os limites?). Escolha do usuário não é incógnita. Para cada uma, dispare subagentes de pesquisa (`.claude/modelos/pesquisa.md`), em paralelo; o resultado vai para `privado/docs/pesquisas/`. O que a pesquisa não confirmar vira etapa de `prova`. Sem incógnitas, diga numa linha e siga.
2. **Decisões.** Só o que a primeira etapa precisa ou o que é caro mudar depois. Proponha cada uma com a recomendação; o resto vai para "Decidir depois", ligado à etapa que vai precisar.
3. **Etapas.** Cada uma com tipo (tabela em `.claude/skills/construtor-etapa/SKILL.md`), objetivo, entregáveis, critérios de aceite verificáveis do jeito do tipo e o que fica fora. Só as necessárias; cada uma cabe numa sessão. A primeira de `ambiente` ou `código` deixa o esqueleto compilando e preenche `.claude/comandos.conf`. Com testes, toda etapa de `código` com lógica traz "testes passam". `deploy` e `resultados` só se o briefing disse que entram. A ordem da tabela é a de execução.
4. **Mostre o plano inteiro de uma vez** (objetivo, critério de pronto, decisões, etapas, o que ficou pendente) e peça **um ok**. Ajuste o que o usuário pedir e mostre só o que mudou.

Com o ok:

- grave as decisões em `privado/docs/decisoes/NNN-titulo-curto.md` (citando a pesquisa, ou "escolha do usuário");
- projeto novo: `objetivo.md` para `aprovado (AAAA-MM-DD)`, `privado/docs/arquitetura.md` com o que já se sabe (o resto `a decidir`) e `.claude/rules/projeto.md` (com "Testes", "Commits" e "Versão" do modelo, padrão quando o usuário não disse);
- tecnologia decidida: `.claude/rules/<stack>.md` a partir de `.claude/modelos/convencoes/`, se houver; os padrões da stack em `projeto/.gitignore`; as permissões de build, formatação e testes em `.claude/settings.json`;
- ciclo que muda objetivo ou arquitetura de projeto existente: o texto novo fez parte do plano aprovado; grave a decisão.

## 4. Abrir o ciclo

1. **Git.** Projeto novo sem repositório (a criação fez parte do plano aprovado):
   ```bash
   git -C projeto init -b main
   ```
   ```bash
   git -C projeto config core.hooksPath ../.claude/git-hooks
   ```
   ```bash
   git -C projeto add .gitignore .gitattributes
   ```
   ```bash
   git -C projeto commit -m "Docs: início do projeto"
   ```
   Repositório que já existe: confira a branch principal e grave em `BRANCH_PRINCIPAL`.
2. `git -C projeto switch -c ciclo-NN` a partir da principal.
3. Quadro (em projeto novo, crie no modelo): cada etapa ganha um número `#NNN` novo (regra em "privado/QUADRO.md" do modelo) e entra em "A fazer"; o item do Backlog que originou o ciclo sai de lá e é citado no "Objetivo" do `ciclo.md`; "Situação" com próximo passo `/construtor-proxima-etapa`.
4. Em `ciclo.md`: tabela de etapas com os números, a branch, o commit inicial (`git -C projeto rev-parse HEAD`) e `Status: aprovado (AAAA-MM-DD)`.
5. Siga direto `.claude/skills/construtor-proxima-etapa/SKILL.md` para abrir a primeira etapa (o ok do plano já vale para abri-la).
