---
name: construtor-equipe-iniciar
description: Entrada única do gerente. Descobre onde o projeto está (conversão, projeto novo, ciclo em andamento, sem ciclo aberto) e segue pelo caminho certo. Para projeto ou ciclo novo, conduz o briefing, a pesquisa, as decisões necessárias e as etapas, e abre o ciclo. Não escreve código.
disable-model-invocation: true
argument-hint: "[o que você quer fazer, opcional]"
---

# Iniciar

Esta sessão é o **gerente** (veja "Papéis" no `CLAUDE.md`). Você descobre onde o projeto está e conduz o usuário a partir dali. Regras do começo ao fim:

- Não escreva código nem rode geradores (`dotnet new`, `npm init`). Isso é trabalho de etapa.
- Não invente respostas. O que o usuário não souber vira incógnita para a pesquisa ou fica "Em aberto".
- Peça o ok do usuário ao fim dos passos 2, 4 e 5. O passo 6 só roda com o ok do passo 5.
- Use os modelos de `.claude/modelos/documentos.md`. Documentos curtos, em português.
- Enquanto o briefing não fecha, o documento dele fica com `Status: rascunho`. É assim que a retomada sabe onde parou.

`NN` é o número do ciclo com dois dígitos, `<ciclo>` é `privado/docs/ciclos/NN-nome` e `<principal>` é o `BRANCH_PRINCIPAL` de `.claude/comandos.conf`.

## 1. Descobrir onde o projeto está

Uma vez por sessão, antes de tudo, siga "Configuração" de `.claude/skills/construtor-equipe-subagente/SKILL.md`: conta dos subagentes, modelos liberados e esforço máximo. Depois, siga o primeiro caso que valer:

1. **Há um projeto em `conversor/`** (liste só o primeiro nível) **e não existe `privado/QUADRO.md`:** pergunte se o usuário quer trazer esse projeto. Com o sim, siga `.claude/skills/construtor-equipe-converter/SKILL.md` e não continue aqui.
2. **Não existe `privado/QUADRO.md`:** projeto novo. Crie as pastas que faltarem (`projeto/`, `privado/docs/`, `privado/parametros/`) e vá ao passo 2. Se já houver `privado/docs/objetivo.md` em `rascunho`, retome de onde parou e diga isso.
3. **O quadro mostra um ciclo aberto:**
   - `<ciclo>/ciclo.md` em `rascunho`: retome o briefing do primeiro passo ainda não registrado e diga de onde está retomando;
   - senão: mostre a "Situação" do quadro e indique o próximo passo (`/construtor-equipe-iniciar-etapa`, `/construtor-equipe-progresso` ou `/construtor-equipe-encerrar-ciclo`). Não abra outro ciclo. Pedido novo vai para o Backlog.
4. **O quadro mostra "nenhum aberto":**
   1. Se esta conversa já fez outro trabalho antes (por exemplo, encerrou um ciclo), peça ao usuário uma sessão nova no Root: cada ciclo tem o seu gerente.
   2. Rode `git -C projeto status`. Algo não commitado: mostre e pare.
   3. Rode `git -C projeto log --first-parent --oneline -15 <principal>`. Se houver commits que não vieram do kit (fora de `Merge:` e `Docs:`), dispare um subagente (veja `.claude/skills/construtor-equipe-subagente/SKILL.md`), só leitura, para comparar `privado/docs/objetivo.md` e `privado/docs/arquitetura.md` com o código e devolver em até 10 linhas o que os documentos dizem e o código não faz, e o contrário. Corrija os documentos com o ok.
   4. Mostre o Backlog e as "Lições" do `ciclo.md` do último ciclo. Pergunte o que será feito (`$ARGUMENTS` pode já trazer).
   5. Classifique com o usuário:
      - **Ciclo curto:** cabe numa sessão, não pede decisão de projeto nem pesquisa e não altera nada fora do git. Siga `.claude/skills/construtor-equipe-ciclo-curto/SKILL.md` nesta sessão.
      - **Ciclo:** todo o resto. Vá ao passo 2.

## 2. Briefing

Um questionário curto, em no máximo duas rodadas. Pergunte só o que mudar o trabalho:

- o que deve existir no fim, para quem e por quê;
- limite de custo (só gratuito? até quanto por mês?) e o que o usuário já tem (contas, máquinas, serviços);
- o que fica de fora;
- como saber que está pronto, com um comportamento observável ou um número com unidade;
- o que entra neste ciclo: testes automatizados, publicação (deploy), medição de resultados.

Não pergunte tecnologia. Se o usuário já tiver uma preferência, registre como preferência, não como decisão.

Grave o rascunho: em projeto novo, `privado/docs/objetivo.md`; em todo caso, `<ciclo>/ciclo.md` com "Objetivo", "Critério de pronto" e "Briefing". O número do ciclo é o maior já usado mais 1, contando os cancelados (confira também `git -C projeto branch --list "ciclo-*"`). Um ciclo tem **um** objetivo: dois objetivos independentes viram dois ciclos, e um deles vai para o Backlog.

Feche o passo com a lista **"O que não sabemos"**: cada incógnita que muda o desenho (é possível? é pago? quais os limites? que tecnologia serve?). Mostre e peça o ok.

## 3. Pesquisa

Para as incógnitas da lista, siga `.claude/skills/construtor-equipe-pesquisar/SKILL.md` (subagentes em paralelo, com fonte e data). O resultado fica em `privado/docs/pesquisas/`. Sem incógnitas, diga isso e siga.

Mostre, para cada incógnita: a resposta, as opções com custo e limites, a recomendação e **o que a pesquisa não confirma**.

## 4. Decidir o necessário

Para cada escolha em aberto, pergunte primeiro: precisa ser decidida agora?

- **Agora:** só o que a primeira etapa precisa, ou o que seria caro mudar depois. A decisão é do usuário. Grave em `privado/docs/decisoes/NNN-titulo-curto.md`, citando a pesquisa.
- **Depois:** vai para "Decidir depois" do `ciclo.md`, ligada à etapa que vai precisar dela e ao dado que falta.
- **Incerta mesmo depois da pesquisa:** vira uma etapa do tipo `prova` antes de construir.

Com o que foi decidido, e com o ok:

1. Projeto novo: mude `privado/docs/objetivo.md` para `aprovado (AAAA-MM-DD)`, crie `privado/docs/arquitetura.md` com o que já se sabe (o resto fica `a decidir`) e crie `.claude/rules/projeto.md`.
2. Tecnologia decidida: crie `.claude/rules/<stack>.md` a partir de `.claude/modelos/convencoes/`, se houver modelo; proponha os padrões da stack em `projeto/.gitignore` e as permissões de build, formatação e testes em `.claude/settings.json`.
3. Testes automatizados: se a tecnologia já permite decidir, pergunte se o projeto terá testes, com que ferramenta e quem os escreve (um subagente, que é o padrão, ou a sessão da etapa). Grave a decisão e a linha "Testes" de `.claude/rules/projeto.md`. Senão, a linha fica `a decidir`.
4. Se o ciclo muda objetivo ou arquitetura de um projeto existente, mostre o texto novo, peça aprovação e grave a decisão.

## 5. Etapas

Proponha as etapas do ciclo, cada uma com um **tipo** (`pesquisa`, `prova`, `ambiente`, `código`, `deploy`, `resultados`; veja a tabela em `.claude/skills/construtor-equipe-etapa/SKILL.md`):

- só as etapas de que este ciclo precisa. Uma correção pode ter uma única etapa de `código`;
- cada etapa cabe numa sessão, sem compactar o contexto, e tem entrega verificável;
- para cada uma: objetivo, entregáveis, critérios de aceite verificáveis do jeito do tipo, e o que fica fora;
- a primeira etapa de `ambiente` ou de `código` deixa o esqueleto compilando e preenche `.claude/comandos.conf`;
- se o projeto tem testes, toda etapa de `código` com lógica a testar traz o critério "testes passam";
- `deploy` e `resultados` só entram se o usuário disse no briefing que entram.

Ajuste até o usuário aprovar e grave em "Etapas" do `ciclo.md`.

## 6. Abrir o ciclo

1. **Git.**
   - Projeto novo sem repositório: pergunte se pode criar. Com o ok:
     ```bash
     git -C projeto init -b main
     ```
     ```bash
     git -C projeto config core.hooksPath ../.claude/git-hooks
     ```
     Faça o commit inicial na principal, só com a configuração do git:
     ```bash
     git -C projeto add .gitignore .gitattributes
     ```
     ```bash
     git -C projeto commit -m "Docs: início do projeto"
     ```
   - Repositório que já existe: confira o nome da branch principal e grave em `BRANCH_PRINCIPAL`.
2. Crie a branch do ciclo a partir da principal:
   ```bash
   git -C projeto switch -c ciclo-NN
   ```
3. Atualize o quadro (em projeto novo, crie `privado/QUADRO.md` no modelo): cada etapa ganha um número `#NNN` novo e entra em "A fazer"; o item do Backlog que originou o ciclo sai de lá e é citado no "Objetivo" do `ciclo.md`; preencha a "Situação" (próximo passo: `/construtor-equipe-iniciar-etapa`).
4. Em `ciclo.md`, grave a tabela de etapas com os números, a branch, o commit inicial (`git -C projeto rev-parse HEAD`) e `Status: aprovado (AAAA-MM-DD)`.
5. Encerre indicando `/construtor-equipe-iniciar-etapa`. Não comece a etapa.
