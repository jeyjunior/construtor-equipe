---
name: construtor-equipe-progresso
description: Roda no gerente depois que uma sessão de etapa (ou uma sessão de ciclo curto aberta por ele) termina. Um subagente confere a entrega conforme o tipo da etapa; o gerente revisa com o usuário, decide (aprovar, corrigir, decidir), faz o merge do que foi aprovado e atualiza o quadro.
disable-model-invocation: true
---

# Progresso

Você é o **gerente** (veja "Papéis" no `CLAUDE.md`). Não confie na memória desta conversa nem nos avisos das sessões vinculadas: a fonte é o que está em `privado/` (quadro e documentos) e em `projeto/` (código).

`NN` é o número do ciclo, `EE` é o da etapa, `<ciclo>` é a pasta do ciclo, `<etapa>` é `<ciclo>/etapas/EE-nome.md` e `<principal>` é o `BRANCH_PRINCIPAL` de `.claude/comandos.conf`.

Os documentos ficam fora do git: você edita, não faz commit. No git, você só faz merge e push. O quadro só é editado com `projeto/` na branch do ciclo ou na principal (o hook nega nas outras).

## 1. Situar

1. Leia `privado/QUADRO.md` e veja na "Situação" qual sessão está aberta. Rode `git -C projeto status`: a pasta tem de estar limpa. Se não estiver, a sessão não fechou: diga ao usuário para voltar a ela (link) e pare.
2. **Sessão de ciclo curto aberta** (`curto-NNN`): vá ao passo 3, "Depois de uma sessão de ciclo curto".
3. **Sessão de etapa aberta:** leia `<etapa>` e veja o `Status`:
   - arquivo ausente, `planejada` ou `em andamento`: a sessão não fechou. Diga ao usuário para voltar a ela (link) e pare;
   - `bloqueada` com `Bug antigo (caso 3)` no "Fechamento": vá ao passo 3, "Bug antigo". Não há entrega para conferir;
   - `bloqueada` ou `decisão pendente`: vá ao passo 3, sem conferência;
   - `concluída`: siga no passo 2.

## 2. Conferência (subagente)

O trabalho pesado não passa pelo seu contexto. Dispare **um** subagente (tipo `general-purpose`, só leitura e comandos de verificação) com esta tarefa:

> Confira a entrega da etapa EE do ciclo NN, do tipo `<tipo>`. Leia `<etapa>`, a seção da etapa em `<ciclo>/ciclo.md`, `.claude/comandos.conf` e a linha do tipo na tabela "Tipos de etapa" de `.claude/skills/construtor-equipe-etapa/SKILL.md`. Confirme que `git -C projeto status` está limpo e na branch `ciclo-NN-etapa-EE`. Leia `git -C projeto diff ciclo-NN...ciclo-NN-etapa-EE`.
> Para cada critério de aceite, diga se a evidência registrada existe e se é do jeito que o tipo pede; reexecute o que for barato e seguro. Em etapa com código, rode o `BUILD` e, se estiver preenchido, o `TESTE`, dentro de `projeto/`; se a linha "Testes" de `.claude/rules/projeto.md` for `por etapa`, confira se o código novo tem testes ou se as notas explicam por que não tem. Em `pesquisa`, abra 3 fontes e confira se dizem o que o texto diz. Em `deploy` e `resultados`, confira se cada alteração fora do git tem o jeito de desfazer registrado; não execute nada no destino.
> Aponte trabalho fora do plano, duplicação, falha silenciosa e arquivo sensível. Não edite nada. Responda em no máximo 15 linhas: build e testes (ok, falhou ou não se aplica, com trecho), critérios (ok ou faltando, um por linha), fora do plano, riscos, decisões pendentes.

## 3. Revisão com o usuário

1. Mostre o veredito do subagente e o "Fechamento" de `<etapa>`. Nas saídas sem conferência, mostre só o "Fechamento".
2. Pergunte se o usuário já testou, se ficou como esperado e se há algo a ajustar.
3. Decida com ele uma das saídas.

### Aprovada

1. Faça o merge na branch do ciclo. A principal não recebe nada aqui.
   ```bash
   git -C projeto switch ciclo-NN
   ```
   ```bash
   git -C projeto merge --no-ff ciclo-NN-etapa-EE -m "Merge: ciclo NN, etapa EE — <nome da etapa>"
   ```
   Conflito: rode `git -C projeto merge --abort` e trate como **Correção** (a sessão da etapa traz a branch do ciclo e resolve).
2. Registre:
   - em `<etapa>`: a conversa na "Revisão" e `Status: revisada`;
   - no quadro: o item vai de "Fazendo" para "Feito", com a data e o caminho de `<etapa>`; cada linha de "Para o backlog" entra no Backlog com um número novo; a "Situação" fica sem sessão aberta.
3. **Replanejar com o que se aprendeu.** Depois de etapa de `pesquisa`, `prova` ou `resultados`, pergunte ao usuário se o resultado muda as próximas etapas ou resolve algum item de "Decidir depois". Com o ok, ajuste as etapas em `ciclo.md` e em "A fazer", e grave as decisões.
4. Envie a branch do ciclo:
   ```bash
   git -C projeto push -u origin ciclo-NN
   ```
   O push pede confirmação; sem remoto, diga isso e siga.

### Correção

Grave os itens na "Revisão" de `<etapa>` como pendentes, e mude o `Status` para `em andamento`. O usuário volta à sessão da etapa (link) ou, se ele pedir, você envia os itens a ela por mensagem. Depois, `/construtor-equipe-progresso` de novo.

### Bloqueada ou decisão pendente

Resolva com o usuário o que falta. Grave a decisão em `privado/docs/decisoes/` e, na "Revisão" de `<etapa>`, o que muda no plano; e mude o `Status` para `planejada`. A sessão da etapa ajusta o plano, mostra de novo e pede o ok. Se a decisão muda outras etapas, ajuste `ciclo.md` e o quadro (para editar o quadro, vá para a branch do ciclo, edite e volte para a branch da etapa).

Se não der para resolver agora, a etapa fica como está e o motivo vai para "Decisões pendentes" do quadro, editado na branch do ciclo.

### Problema maior

Vira etapa nova (em `ciclo.md` e em "A fazer", com número novo) ou item do Backlog, com o ok. A etapa atual segue por uma das saídas acima.

### Bug antigo (caso 3)

Mostre a causa e a evidência do "Fechamento" e confirme com o usuário se corrige agora.

- **Agora:** na branch do ciclo, crie no quadro um item novo em "Fazendo" (`#NNN [curto] <bug>`), e aponte a sessão `curto-NNN` na "Situação". Abra **uma** sessão vinculada com os mesmos parâmetros do `/construtor-equipe-iniciar-etapa`, trocando: `name` `curto-NNN`, `title` `Ciclo curto NNN — <bug>`, `prompt` "Você é a sessão de ciclo curto do item #NNN deste projeto, aberta pelo gerente durante o ciclo NN. Leia `.claude/skills/construtor-equipe-ciclo-curto/SKILL.md` e siga esse fluxo. O bug está descrito no Fechamento de `<etapa>`" (escreva o caminho completo do arquivo), e `background` "Este projeto segue o kit Construtor Equipe. Os documentos em `privado/` são a fonte da verdade. O gerente é outra sessão; esta corrige só o bug do item #NNN, a partir da branch principal, e não edita o quadro."
- **Depois:** o bug entra no Backlog (na branch do ciclo). Na "Revisão" de `<etapa>`, grave que a etapa segue sem a correção, e mude o `Status` para `planejada`.

### Depois de uma sessão de ciclo curto

Veja o que ela fez: `git -C projeto branch --merged <principal>` lista `curto-NNN` se a correção entrou na principal.

- **Entrou:** leve a principal para o ciclo.
  ```bash
  git -C projeto switch ciclo-NN
  ```
  ```bash
  git -C projeto merge --no-ff <principal> -m "Merge: ciclo curto NNN na branch do ciclo"
  ```
  Conflito: rode `git -C projeto merge --abort` e grave na "Revisão" de `<etapa>` que ela precisa levar a principal ao ciclo e resolver; quem resolve é a sessão da etapa. No quadro, o item vai para "Feito" (`#NNN [curto] <o quê e por quê> — data — commit`) e a "Situação" volta a apontar a sessão da etapa. Envie (`git -C projeto push origin <principal>` e `git -C projeto push -u origin ciclo-NN`, que pedem confirmação).
- **Não entrou** (o bug não se confirmou na principal, ou o usuário desistiu): tire o item de "Fazendo" e registre o motivo no Backlog. Se o bug não se confirmou, é o caso 2 da skill `construtor-equipe-depurar`: a etapa corrige na própria branch.

Nos dois casos, grave na "Revisão" de `<etapa>` o que aconteceu, mude o `Status` para `planejada` e vá para a branch da etapa (`git -C projeto switch ciclo-NN-etapa-EE`). O usuário volta à sessão da etapa.

## 4. Fechar

1. Confira a "Situação" do quadro: ciclo, sessão aberta, próximo passo, decisões pendentes. Um gerente novo tem de conseguir continuar só com ela.
2. Se o seu contexto passou de 60% ou esta conversa já foi compactada, recomende abrir um gerente novo no Root: o quadro tem o que ele precisa.
3. Indique o próximo passo: `/construtor-equipe-iniciar-etapa`, voltar à sessão da etapa, ou `/construtor-equipe-encerrar-ciclo` se todas as etapas do ciclo estão em "Feito".
