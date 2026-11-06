---
name: etapa
description: Roda na sessão vinculada aberta pelo /iniciar-etapa. Conduz uma única etapa do ciclo em ordem fixa (apresentação, perguntas, execução, fechamento com commit e status no roadmap do ciclo), lendo e atualizando Projeto_Documento/.
disable-model-invocation: true
argument-hint: "[número da etapa]"
---

# Etapa

Você é a **sessão desta etapa**, aberta pelo gerente (outra sessão; veja "Papéis" no `CLAUDE.md`). Você cuida só desta etapa, conversa direto com o usuário e, ao terminar, marca no roadmap do ciclo como ela fechou.

`<ciclo>` é a pasta do ciclo atual em `estado.md`, `NN` é o número do ciclo e `EE` é o número da etapa, com dois dígitos.

Valem as regras do `CLAUDE.md` (estrutura de pastas, papéis e "Como trabalhamos"). Siga os passos **na ordem**, sem pular nenhum. Regras desta skill, do começo ao fim:

- **Pare e espere o "ok" do usuário** ao fim dos passos 2 e 3. Não emende um passo no outro na mesma resposta.
- **Decisão que o plano não cobre:**
  - dentro do escopo da etapa: pergunte ao usuário aqui e registre a resposta em `Projeto_Documento/decisoes/`;
  - que muda objetivo, arquitetura ou outras etapas do roadmap: não decida. Feche com status `decisão pendente` (passo 5) para o usuário levar ao gerente.
- **Tudo o que importa vai para o arquivo da etapa.** O gerente não lê esta conversa: o que não estiver em `Projeto_Documento/` não chega a ele.
- O status da etapa fica só na tabela do roadmap do ciclo. Use os modelos de `.claude/modelos/documentos.md`.
- **Git:** você trabalha só na branch `ciclo-NN-etapa-EE` e faz commit só no fechamento. Merge e push são do gerente.

## 1. Situar

1. Leia `Projeto_Documento/estado.md`, `<ciclo>/ciclo.md`, `<ciclo>/roadmap.md` e `.claude/comandos.conf`. Se `Projeto_Documento/referencias.md` citar esta etapa em "Onde pesa no projeto novo", leia a seção da referência. A etapa é a de `$ARGUMENTS` ou a indicada no `estado.md`.
2. A etapa anterior do ciclo precisa estar `revisada` (a etapa 1 não tem anterior). Se não estiver, diga que o gerente ainda não liberou (`/progresso`) e pare.
3. Se a etapa está `planejada` ou `em andamento` e a branch `ciclo-NN-etapa-EE` já existe, vá para ela e traga o que entrou no ciclo, como uma correção de bug antigo. Se der conflito, resolva aqui e faça o commit.
   ```bash
   git -C Projeto switch ciclo-NN-etapa-EE
   ```
   ```bash
   git -C Projeto merge ciclo-NN
   ```
   Se a seção "Revisão" do arquivo da etapa pedir para levar a principal ao ciclo por causa de um conflito, faça isso antes: `git -C Projeto switch ciclo-NN`, `git -C Projeto merge <principal>` (`BRANCH_PRINCIPAL` de `.claude/comandos.conf`), resolva o conflito, faça o commit e volte para a branch da etapa. Só depois rode os dois comandos acima.
4. Pelo status desta etapa no roadmap do ciclo:
   - `pendente`: vá ao passo 2;
   - `planejada`: se a seção "Revisão" do arquivo da etapa trouxer mudanças no plano, ajuste o plano a elas; depois retome no passo 3.3 (revisar e mostrar o plano);
   - `em andamento` com correções pendentes na seção "Revisão": faça só as correções, depois vá ao passo 5;
   - `em andamento`: continue no passo 4, a partir do primeiro item não marcado;
   - `concluída`, `bloqueada` ou `decisão pendente`: a etapa já fechou. Diga ao usuário para rodar `/progresso` no gerente e pare;
   - `revisada`: a etapa já foi aprovada. Pare.

## 2. Apresentação

1. Mostre, a partir do roadmap do ciclo: objetivo, entregáveis, critérios de aceite e o que fica fora.
2. Diga em poucas linhas como pretende fazer.
3. Pergunte se confirma. Mudança na etapa em si (entregáveis, critérios) é decisão do gerente: feche com `decisão pendente`.

## 3. Perguntas e plano

1. Antes de perguntar, confira para você mesmo o que a etapa precisa saber: escopo, dados (entidades, formatos, unicidade), comportamento em erro e quando algo externo falha, números (volume, tempo, limite, sempre com unidade), nomes já usados no projeto, como saber que terminou. Pergunte só o que estiver faltando ou ambíguo **e** mudar a implementação. O que já está nos documentos ou no código não vira pergunta. Siga a regra de perguntas do `CLAUDE.md`.
2. Crie `<ciclo>/etapas/EE-nome.md` com as respostas, os padrões a seguir (arquivos existentes a imitar) e o plano em checklist, cada item com os arquivos de `Projeto/` que vai tocar. Marque a etapa como `planejada` no roadmap do ciclo.
3. Revise o plano antes de mostrar: nada "a definir", nenhuma contradição com os documentos, nada que exija adivinhar, cada critério de aceite verificável por um comando ou comportamento observável.
4. Mostre o plano. Com o ok, marque a etapa como `em andamento` e, se a branch ainda não existe, crie-a a partir da branch do ciclo. Se `git -C Projeto status` mostrar algo não commitado, mostre e pare antes de trocar de branch.
   ```bash
   git -C Projeto switch ciclo-NN
   ```
   ```bash
   git -C Projeto switch -c ciclo-NN-etapa-EE
   ```

## 4. Execução

1. Siga o checklist, marcando cada item ao terminar.
2. Rode o `BUILD` ao longo do trabalho, não só no final. Erro ou comportamento inesperado: siga a skill `depurar`, sem tentativas no escuro. Ela define o que fazer conforme a origem do bug (casos 1, 2 e 3).
3. Registre em "Notas da execução" qualquer desvio, problema ou escolha feita no caminho.
4. Registre em "Alterações fora do git" tudo o que mudar fora de `Projeto/`: banco, servidor, serviços externos. Um cancelamento só desfaz o que está no git.
5. Leitura ou pesquisa ampla (muitos arquivos, documentação externa): use um subagente e traga só a conclusão, para manter esta sessão leve.
6. **Testes**, só se a linha "Testes" do `CLAUDE.md` for `por etapa`. Com o checklist pronto:
   1. Escritos por subagente: dispare **um** (tipo `general-purpose`) com a tarefa abaixo. Escritos pela sessão da etapa: faça você mesmo, com as mesmas regras.

      > Escreva os testes da etapa EE do ciclo NN. Leia os critérios de aceite em `<ciclo>/roadmap.md`, `<ciclo>/etapas/EE-*.md`, as convenções em `.claude/rules/` e `.claude/comandos.conf`. Veja o código da etapa com `git -C Projeto diff ciclo-NN` e os arquivos novos. Teste o que os critérios pedem e as regras de negócio, sem banco nem rede reais. Crie ou altere só arquivos de teste, nunca o código do sistema. Se o código parecer errado ou não der para testá-lo sem mudá-lo, não corrija: relate. Rode o `TESTE` dentro de `Projeto/`. Responda em no máximo 10 linhas: testes criados, resultado, falhas e o que não foi possível testar.
   2. Teste falhou: siga a skill `depurar` e corrija o código. Só altere um teste se ele entendeu o critério errado, e registre o motivo em "Notas da execução".
   3. Etapa sem lógica a testar: registre o motivo em "Notas da execução" e siga.

## 5. Fechamento

**Bug antigo que atrapalha mesmo sem o ciclo (caso 3), com o ok do usuário para corrigir agora:** pule os itens 1, 3 e 4. O status é `bloqueada`, e o "Fechamento" traz `Bug antigo (caso 3)`, a causa, os passos para reproduzir e a evidência.

1. Revise o próprio diff da etapa (`git -C Projeto diff ciclo-NN` e arquivos novos) e corrija o que achar, dentro do escopo:
   - código que não precisava existir: abstração sem segundo uso, wrapper que só repassa, configuração para algo que não varia;
   - duplicação: algo que já existia no projeto e foi reescrito;
   - falha silenciosa: erro capturado sem log, `|| true` ou valor padrão escondendo falha real.
2. Confira `git -C Projeto status`: nenhum arquivo de documentação (`.md` além do `README.md`, pasta `docs/`) e nenhum arquivo sensível (`.env`, `segredo.json`, chave, certificado). Se houver, mova para `Projeto_Documento/` antes de seguir.
3. Verifique cada critério de aceite agora (build, execução, chamada real e o `TESTE`, se estiver preenchido) e registre a evidência: comando executado e trecho da saída. Critério sem evidência fresca não passou.
4. Se comandos ou convenções mudaram, atualize `.claude/comandos.conf` ou o arquivo de convenções em `.claude/rules/` e mostre a alteração.
5. Preencha a seção "Fechamento" do arquivo da etapa (substitua a anterior, se houver). Escolha o status:
   - `concluída`: todos os critérios de aceite têm evidência;
   - `bloqueada`: falta algo que não depende de você. Escreva no "Fechamento" o que falta e por quê;
   - `decisão pendente`: precisa de uma decisão do gerente. Escreva no "Fechamento" a decisão e as opções.
6. Faça o commit de tudo na branch `ciclo-NN-etapa-EE` e mostre a mensagem. Use `<Tipo>: <descrição>`, com `Adicao`, `Correcao` ou `Refatoracao`; se a etapa não está `concluída`, use `Andamento: <descrição>`, para nada se perder quando outra sessão usar a pasta. Se a trava recusar o commit, corrija o que ela apontar antes de seguir.
7. Com o commit feito, marque o status no roadmap do ciclo.
8. Mostre um resumo curto do que foi feito e do que a revisão do diff corrigiu.
9. Comece esta última resposta pelo status (ex.: `Etapa 03: concluída`), para o usuário ver de cara como a etapa fechou. Termine dizendo a ele para voltar ao gerente e rodar `/progresso`. Não comece outra etapa, não faça merge nem push.
