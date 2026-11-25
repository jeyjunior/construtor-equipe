---
name: construtor-seguir
description: Roda no gerente com um ciclo aberto e faz o próximo passo pelo quadro - confere a etapa (ou o ciclo curto) que fechou, aprova com o usuário, faz o merge no ciclo, e abre a próxima etapa numa sessão vinculada; reabre etapa que caiu ou que esperava uma data. Use quando o usuário disser "segue", "continua", "próxima etapa", "confere a etapa", "a etapa terminou", ou trouxer o resultado de uma etapa. Só na sessão do gerente: numa sessão de etapa ou de ciclo curto, "segue" é aprovação do plano, não esta skill.
argument-hint: "[número da etapa ou o que aconteceu, opcional]"
---

# Seguir

Você é o **gerente** (veja "Papéis" e "Contexto primeiro" no `CLAUDE.md`). A fonte é o que está em `privado/` e em `projeto/`, não a memória desta conversa nem o aviso das sessões vinculadas. O contexto que o usuário trouxer (resultado de teste, mudança de plano) entra antes de decidir.

`NN` é o ciclo, `EE` a etapa (dois dígitos), `<ciclo>` a pasta do ciclo da "Situação", `<etapa>` é `<ciclo>/etapas/EE-nome.md` e `<principal>` o `BRANCH_PRINCIPAL` de `.claude/comandos.conf`. Documentos ficam fora do git: você edita, não faz commit.

## 1. Situar

0. Se esta sessão foi aberta para uma etapa ou um ciclo curto (o primeiro pedido dela foi "Você é a sessão da etapa…" ou "…de ciclo curto…"), não siga: diga para dizer "segue" no gerente e pare.
1. Leia `privado/QUADRO.md` e `<ciclo>/ciclo.md`. Sem ciclo aberto, siga `.claude/skills/construtor-iniciar/SKILL.md`. Ciclo em `rascunho`: idem.
2. Pela "Situação" e por "Fazendo":
   - **Sessão de ciclo curto aberta** (`curto-NNN`): passo 4.
   - **Sessão de etapa aberta:** leia o `Status` de `<etapa>`:
     - `concluída`: passo 2;
     - `aguardando`, `bloqueada` ou `decisão pendente`: passo 3, sem conferência;
     - ausente, `planejada` ou `em andamento`: a sessão não fechou. Se ela ainda existe, diga para voltar a ela (link). Se caiu ou foi fechada, ofereça **reabrir** (passo 5, com a mesma etapa).
   - **Nenhuma sessão aberta:** passo 5 (próxima etapa). Etapa `aguardando` cuja data chegou: ofereça reabrir no passo 5.
   - Todas as etapas em "Feito": indique `/construtor-encerrar-ciclo`.

## 2. Conferência (subagente)

Dispare **um** subagente (`general-purpose`, só leitura e comandos de verificação), seguindo `.claude/skills/construtor-subagente/SKILL.md` (pela CLI, com `--verificar`):

> Confira a entrega da etapa EE do ciclo NN, do tipo `<tipo>`. Leia `<etapa>`, a seção da etapa em `<ciclo>/ciclo.md`, `.claude/comandos.conf` e a linha do tipo em "Tipos de etapa" de `.claude/skills/construtor-etapa/SKILL.md`. Confirme `git -C projeto status` limpo e na branch `ciclo-NN-etapa-EE`. Leia `git -C projeto diff ciclo-NN...ciclo-NN-etapa-EE`.
> Para cada critério de aceite, diga se a evidência registrada existe e é do jeito que o tipo pede; reexecute o que for barato e seguro. Com código, rode o `BUILD` e, se preenchido, o `TESTE` (na forma `cd projeto && <comando>`); com "Testes: por etapa" em `.claude/rules/projeto.md`, confira se o código novo tem testes ou se as notas explicam. Em `pesquisa`, abra 3 fontes e confira. Em `deploy` e `resultados`, confira se cada alteração fora do git tem o jeito de desfazer (ou "irreversível"); não execute nada no destino.
> Aponte trabalho fora do plano, duplicação, falha silenciosa e arquivo sensível. Não edite nada. No máximo 15 linhas: build e testes, critérios (um por linha), fora do plano, riscos, decisões pendentes.

## 3. Revisão e saída

Mostre o veredito (se houve conferência) e o "Fechamento" de `<etapa>`, e proponha a saída. O usuário confirma ou traz o que testou.

### Aprovada

1. `git -C projeto status` de novo (algo mudou desde a conferência? mostre e pare). Merge no ciclo:
   ```bash
   git -C projeto switch ciclo-NN
   ```
   ```bash
   git -C projeto merge --no-ff ciclo-NN-etapa-EE -m "Merge: ciclo NN, etapa EE — <nome da etapa>"
   ```
   Conflito: `git -C projeto merge --abort` e trate como **Correção** (a sessão da etapa traz o ciclo e resolve).
   ```bash
   git -C projeto branch -d ciclo-NN-etapa-EE
   ```
2. Registre: em `<etapa>`, a conversa na "Revisão" e `Status: revisada`; no quadro, o item vai para "Feito" (data e caminho de `<etapa>`), cada linha de "Para o backlog" entra no Backlog com número novo, "Situação" sem sessão aberta.
3. Se a etapa mudou o que `privado/docs/arquitetura.md` descreve (um deploy, um componente novo), atualize agora, com a data.
4. Depois de `pesquisa`, `prova` ou `resultados`: o resultado muda as próximas etapas ou resolve algo de "Decidir depois"? Proponha o ajuste junto com a abertura da próxima etapa (um ok só).
5. `git -C projeto push -u origin ciclo-NN` (pede confirmação). Sem remoto, diga numa linha que o ciclo só existe nesta pasta.
6. Siga para o passo 5 (próxima etapa), na mesma resposta.

### Aguardando

A etapa espera uma data para verificar o resto. Confirme a data e o que não pode mudar até lá. Volte para `ciclo-NN` (`git -C projeto switch ciclo-NN`). No quadro, o item fica em "Fazendo" com `aguardando até AAAA-MM-DD, sem sessão`; "Situação" sem sessão aberta e próximo passo "reabrir a etapa EE em AAAA-MM-DD". Registre na "Revisão". Até a data, a próxima etapa pode abrir se não mexer no que está sendo aguardado (passo 5).

### Correção

Itens na "Revisão" de `<etapa>` como pendentes, `Status: em andamento`. O usuário volta à sessão da etapa (link), ou você manda os itens a ela por mensagem.

### Bloqueada ou decisão pendente

Resolva o que falta com o usuário, grave a decisão em `privado/docs/decisoes/`, registre na "Revisão" o que muda e mude o `Status` para `planejada`; a sessão da etapa ajusta o plano. Se a decisão muda outras etapas, ajuste `ciclo.md` e o quadro. Sem como resolver agora: vai para "Decisões pendentes" e a etapa fica como está.

### Problema maior

Vira etapa nova (em `ciclo.md` e "A fazer", número novo) ou item do Backlog. A etapa atual segue por uma das saídas acima.

### Bug antigo (caso 3)

O "Fechamento" traz `Bug antigo (caso 3)`, a causa e a evidência. Proponha corrigir agora (padrão) ou depois.

- **Agora:** crie no quadro `#NNN [curto] <bug>` em "Fazendo" e aponte `curto-NNN` na "Situação". Abra uma sessão vinculada como no passo 5, trocando `name` (`curto-NNN`), `title` (`Ciclo curto NNN — <bug>`), `prompt` ("Você é a sessão de ciclo curto do item #NNN deste projeto, aberta pelo gerente durante o ciclo NN. Leia `.claude/skills/construtor-ciclo-curto/SKILL.md` e siga esse fluxo. O bug está no Fechamento de `<caminho completo de etapa>`") e `background` ("Este projeto segue o kit Construtor Equipe. Os documentos em `privado/` são a fonte da verdade. O gerente é outra sessão; esta corrige só o bug do item #NNN, a partir da branch principal, e não edita o quadro.").
- **Depois:** o bug vai para o Backlog; na "Revisão", a etapa segue sem a correção, `Status: planejada`.

## 4. Depois de uma sessão de ciclo curto

A correção entrou se `git -C projeto log --first-parent --oneline --grep "^Merge: ciclo curto NNN" <principal>` mostra o merge (`branch --merged` não serve: branch sem commit conta como "merged").

- **Entrou:** `git -C projeto switch ciclo-NN` e `git -C projeto merge --no-ff <principal> -m "Merge: ciclo curto NNN na branch do ciclo"`. Conflito: `merge --abort` e grave na "Revisão" da etapa que ela leva a principal ao ciclo e resolve. No quadro, o item vai para "Feito" (`#NNN [curto] <o quê e por quê> — data — commit`). Envie (`git -C projeto push origin <principal>` e `git -C projeto push -u origin ciclo-NN`, que pedem confirmação).
- **Não entrou:** tire o item de "Fazendo" e registre o motivo no Backlog. Bug que não se confirmou na principal é o caso 2 do `construtor-depurar`: a etapa corrige na própria branch.

Nos dois casos: na "Revisão" da etapa, o que aconteceu e `Status: planejada`; `git -C projeto switch ciclo-NN-etapa-EE`; a "Situação" volta a apontar a sessão da etapa. O usuário volta a ela.

## 5. Abrir a etapa

1. **Qual.** A de `$ARGUMENTS`, a que vai ser reaberta, ou a próxima da tabela de etapas do `ciclo.md` (a ordem da tabela é a de execução) que está em "A fazer". A anterior na tabela precisa estar em "Feito", ou `aguardando` sem depender dela (diga qual padrão usou e grave em `ciclo.md`).
2. **Uma sessão por vez.** Sessão aberta ou item em "Fazendo" que não está `aguardando` (e não é esta etapa sendo reaberta): pare e avise.
3. `git -C projeto status`. Etapa nova: limpa e na branch `ciclo-NN`. Reaberta: pode estar na branch dela com o que a sessão anterior deixou (a sessão nova trata). Fora disso, mostre e pare.
4. **Decisões desta etapa** ("Decidir depois" do `ciclo.md` e "Decisões pendentes" do quadro): proponha cada uma com a recomendação, na mesma rodada do ok de abertura; grave em `privado/docs/decisoes/`. A sessão da etapa só sabe o que está escrito.
5. **Deploy sem remoto** (`git -C projeto remote` vazio): diga numa linha que o código publicado só vai existir nesta pasta e sugira criar o remoto antes (padrão: seguir sem; a resposta vai para "Repositório" de `.claude/rules/projeto.md`, para não repetir).
6. Mostre numa linha qual etapa abre (e o que decidiu) e peça o ok. Com o ok, ou se o usuário já disse "segue":
   1. Quadro: o item vai de "A fazer" para "Fazendo", com a sessão e a data (reaberta: só atualize data e sessão); "Situação" atualizada.
   2. Abra **uma** sessão vinculada (ferramenta de iniciar sessão do app, `start_session`):
      - `initiation: "user_asked"`; `context: "fresh"` (nunca `fork`); `use_worktree: false`;
      - `model` e `effort`: `MODELO_ETAPA` e `ESFORCO_ETAPA` de `.claude/comandos.conf`; vazios, não passe;
      - `name`: `ciclo-NN-etapa-EE` (reaberta: `ciclo-NN-etapa-EE-rN`); `title`: `Ciclo NN, etapa EE — <nome>`;
      - `prompt`: "Você é a sessão da etapa EE do ciclo NN deste projeto. Leia `.claude/skills/construtor-etapa/SKILL.md` e siga esse fluxo para a etapa EE."
      - `background` (mínimo de 80 caracteres): "Este projeto segue o kit Construtor Equipe. Os documentos em `privado/` são a fonte da verdade: o que não está escrito lá não existe. O gerente é outra sessão; esta cuida só da etapa EE do ciclo NN e, ao fechar, registra no arquivo da etapa como ela terminou."

      Vontade de explicar algo no `prompt`? Falta isso nos documentos: grave lá primeiro.
   3. Diga, com o link, que a etapa segue lá e que, quando terminar, basta voltar aqui e dizer "segue" (ou `/construtor-seguir`).

## 6. Fechar

Confira a "Situação": um gerente novo tem de continuar só com ela. Se esta conversa já foi compactada, recomende abrir um gerente novo no Root.
