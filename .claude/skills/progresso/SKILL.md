---
name: progresso
description: Roda no gerente depois que uma sessão de etapa ou de correção termina. Um subagente confere a entrega; o gerente revisa com o usuário, decide (aprovar, corrigir, decidir), faz o merge do que foi aprovado e atualiza estado.md e metricas.md.
disable-model-invocation: true
---

# Progresso

Você é o **gerente** (veja "Papéis" no `CLAUDE.md`). Não confie na memória desta conversa nem nos avisos das sessões vinculadas: a fonte é o que está em `Projeto_Documento/` e em `Projeto/`.

`<ciclo>` é a pasta do ciclo atual em `estado.md`, `NN` é o número do ciclo, `EE` é o da etapa, `CC` é o da correção e `<principal>` é o `BRANCH_PRINCIPAL` de `.claude/comandos.conf`.

## 1. Situar

1. Leia `Projeto_Documento/estado.md`, ache o ciclo, a etapa atual e, se houver, a correção em andamento. Leia `<ciclo>/roadmap.md`.
2. **Com correção em andamento**, veja o status dela na tabela "Correções":
   - `pendente` ou `em andamento`: a sessão da correção não fechou. Diga ao usuário para voltar a ela (link da sessão) e pare;
   - `concluída`: siga no passo 2, conferindo a correção;
   - `decisão pendente`: vá ao passo 3, saída **Correção não se confirmou**.
3. **Sem correção em andamento**, veja o status da etapa na tabela:
   - `pendente`, `planejada` ou `em andamento`: a sessão da etapa não fechou. Diga ao usuário para voltar a ela (link da sessão) e pare;
   - `bloqueada` com `Bug antigo (caso 3)` no "Fechamento": vá ao passo 3, saída **Abrir correção**. Não há entrega para conferir;
   - os demais: siga no passo 2.

## 2. Conferência (subagente)

O trabalho pesado não passa pelo seu contexto. Dispare **um** subagente (tipo `general-purpose`, só leitura e comandos de verificação, sem editar nada) com esta tarefa:

> Confira a entrega da etapa EE do ciclo NN. Leia `<ciclo>/etapas/EE-*.md` e `.claude/comandos.conf`. Confirme que `git -C Projeto status` está limpo e na branch `ciclo-NN-etapa-EE`. Rode o `BUILD` e, se estiver preenchido, o `TESTE` dentro de `Projeto/`. Leia `git -C Projeto diff ciclo-NN...ciclo-NN-etapa-EE`. Para cada critério de aceite, diga se a evidência registrada existe e se bate com o código; reexecute o que for barato. Se a linha "Testes" do `CLAUDE.md` for `por etapa`, confira se o código novo tem testes ou se "Notas da execução" explica por que não tem. Confira se há documentação ou arquivo sensível em `Projeto/`. Aponte código fora do plano, duplicação e falha silenciosa. Não edite nada. Responda em no máximo 15 linhas: build (ok/falhou + trecho), testes (ok/falhou/não se aplica + trecho), critérios (ok/faltando, um por linha), fora do plano, riscos, decisões pendentes.

Para uma correção, a tarefa é a mesma, com estas trocas: arquivo `<ciclo>/correcoes/CC-*.md`, branch `ciclo-NN-correcao-CC`, diff `<principal>...ciclo-NN-correcao-CC`, e no lugar dos critérios de aceite, a reprodução do bug antes e depois.

## 3. Revisão com o usuário

1. Mostre o veredito do subagente, o status no roadmap do ciclo e a seção "Fechamento" do arquivo. Nas saídas sem conferência, mostre só o "Fechamento".
2. Pergunte se o usuário já testou, se ficou como esperado e se há algo a ajustar.
3. Decida com ele, uma das saídas:

### Etapa

- **Aprovada:** registre a conversa na seção "Revisão" do arquivo da etapa e faça o merge na branch do ciclo. A principal não recebe nada aqui.
  ```bash
  git -C Projeto switch ciclo-NN
  ```
  ```bash
  git -C Projeto merge --no-ff ciclo-NN-etapa-EE -m "Merge: etapa EE — <nome da etapa>"
  ```
  ```bash
  git -C Projeto push -u origin ciclo-NN
  ```
  O push pede confirmação; sem remoto, diga isso e siga. Com o merge feito, marque `revisada` no roadmap do ciclo. Se der conflito, rode `git -C Projeto merge --abort` e trate como **Correção**: a sessão da etapa traz a branch do ciclo e resolve.
- **Correção:** liste os itens e grave-os na seção "Revisão" como pendentes. Volte a etapa para `em andamento` no roadmap do ciclo. O usuário volta à sessão da etapa (link) ou, se ele pedir, você envia os itens a ela por mensagem. Depois, rode `/progresso` de novo.
- **Bloqueada ou decisão pendente:** resolva com o usuário o que falta ou a decisão. Registre a decisão em `Projeto_Documento/decisoes/` e ajuste o roadmap do ciclo com o ok. Grave na seção "Revisão" o que muda no plano e volte a etapa para `planejada`: a sessão da etapa ajusta o plano, mostra de novo e pede o ok. O usuário volta à sessão da etapa (link) ou você envia por mensagem, se ele pedir. Se não der para resolver agora, a etapa fica como está e o motivo vai para "Decisões pendentes" do `estado.md`.
- **Problema maior:** vira etapa nova no roadmap do ciclo ou item em `Projeto_Documento/ideias.md`, com o ok. A etapa atual segue por uma das saídas acima.

### Bug antigo (caso 3)

- **Abrir correção:** mostre a causa e a evidência do "Fechamento" e confirme com o usuário se corrige agora.
  - Agora: crie `<ciclo>/correcoes/CC-nome.md` no modelo, com a causa e os passos para reproduzir, acrescente a linha `pendente` na tabela "Correções" do roadmap e abra **uma** sessão vinculada com os mesmos parâmetros do `/iniciar-etapa`, trocando: nome `ciclo-NN-correcao-CC`, título `Ciclo NN, correção CC — <nome>`, `prompt` "Você é a sessão da correção CC do ciclo NN deste projeto. Leia `.claude/skills/correcao/SKILL.md` e siga esse fluxo.", e `background` "Este projeto segue o kit Construtor Equipe. Os documentos em `Projeto_Documento/` são a fonte da verdade. O gerente é outra sessão; esta cuida só da correção CC e, ao fechar, marca o status dela no roadmap do ciclo."
  - Depois: registre em `Projeto_Documento/ideias.md`, grave em "Revisão" que a etapa segue sem a correção e volte a etapa para `planejada`.
- **Correção aprovada:** peça um **ok explícito** para o merge na principal. É a única exceção à regra de a principal só receber merge no fim do ciclo. Depois, leve a correção para a principal e daí para o ciclo:
  ```bash
  git -C Projeto switch <principal>
  ```
  ```bash
  git -C Projeto merge --no-ff ciclo-NN-correcao-CC -m "Merge: correção CC do ciclo NN — <nome>"
  ```
  ```bash
  git -C Projeto push origin <principal>
  ```
  ```bash
  git -C Projeto switch ciclo-NN
  ```
  ```bash
  git -C Projeto merge --no-ff <principal> -m "Merge: correção CC na branch do ciclo"
  ```
  ```bash
  git -C Projeto push -u origin ciclo-NN
  ```
  Se o merge na branch do ciclo der conflito, rode `git -C Projeto merge --abort` e grave em "Revisão" da etapa que ela precisa levar a principal ao ciclo e resolver o conflito: quem resolve é a sessão da etapa, porque o gerente não escreve código. Marque a correção como `revisada`, grave em "Revisão" da etapa que a correção entrou e volte a etapa para `planejada`.
- **Correção com ajustes:** grave os itens em "Revisão" do arquivo da correção e volte para `em andamento`. O usuário volta à sessão da correção.
- **Correção não se confirmou:** o bug não causa problema na principal, então é caso 2. Marque a correção como `revisada`, sem merge, registre o motivo, grave em "Revisão" da etapa que ela corrige o bug na própria branch e volte a etapa para `planejada`.

## 4. Registrar (sempre, nesta ordem)

1. Atualize a linha da etapa em `<ciclo>/metricas.md` (uma linha por etapa; crie se não existir, no modelo de `.claude/modelos/documentos.md`):
   - rodadas de correção: some 1 a cada saída **Correção**;
   - bloqueios por decisão: some 1 a cada saída **Bloqueada ou decisão pendente** e a cada **Abrir correção**;
   - compactou: o da etapa está no "Fechamento" dela; o seu, você sabe;
   - custo: pergunte ao usuário (painel de uso do app). Se ele não souber, `—`.
2. Atualize `Projeto_Documento/estado.md`: etapa atual, correção em andamento, sessão aberta (`nenhuma aberta` quando aprovada), decisões pendentes, próximo passo. Este é o último passo: um gerente novo tem que conseguir continuar só com ele.

## 5. Saúde do gerente

Confira o tamanho do seu contexto (ferramenta de uso de sessão). Se passou de 60% ou se esta conversa já foi compactada, recomende ao usuário abrir um gerente novo no Root: `estado.md` tem tudo o que ele precisa.

Encerre indicando o próximo passo: `/iniciar-etapa`, voltar à sessão da etapa ou da correção, ou `/encerrar-ciclo` se todas as etapas do ciclo estiverem `revisadas`.
