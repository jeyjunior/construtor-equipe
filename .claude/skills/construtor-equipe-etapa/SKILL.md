---
name: construtor-equipe-etapa
description: Roda na sessão vinculada aberta pelo /construtor-equipe-iniciar-etapa. Conduz uma única etapa do ciclo em ordem fixa (apresentação, perguntas e plano, execução conforme o tipo da etapa, fechamento com evidência e commit), registrando tudo no arquivo da etapa.
disable-model-invocation: true
argument-hint: "[número da etapa]"
---

# Etapa

Você é a **sessão desta etapa**, aberta pelo gerente (outra sessão; veja "Papéis" no `CLAUDE.md`). Você cuida só desta etapa, conversa direto com o usuário e, ao terminar, registra no arquivo da etapa como ela fechou.

`NN` é o número do ciclo, `EE` é o da etapa, com dois dígitos, `<ciclo>` é a pasta do ciclo indicada no quadro e `<etapa>` é `<ciclo>/etapas/EE-nome.md`.

Siga os passos **na ordem**. Regras do começo ao fim:

- **Pare e espere o "ok" do usuário** ao fim dos passos 2 e 3. Não emende um passo no outro na mesma resposta.
- **Você não edita `privado/QUADRO.md`** (o hook nega). Os documentos ficam em `privado/`, fora do git: em `projeto/` só entra código. Tudo o que importa vai para `<etapa>`: o gerente não lê esta conversa.
- **Decisão que o plano não cobre:** dentro do escopo da etapa, pergunte ao usuário e grave em `privado/docs/decisoes/`. Se muda objetivo, arquitetura ou outras etapas, não decida: feche com `decisão pendente`.
- **Git:** você trabalha só na branch `ciclo-NN-etapa-EE` e faz commit só no fechamento. Merge e push são do gerente.
- **Segredos e contas:** você não pede, não digita e não lê senha, token ou chave. Criar conta, fazer login e preencher `privado/parametros/parametro.json` é com o usuário.

## Tipos de etapa

O tipo está no título da etapa em `ciclo.md`. Ele define o que a etapa entrega e que evidência a fecha.

| Tipo | O que entrega | Evidência que fecha |
|---|---|---|
| `pesquisa` | `privado/docs/pesquisas/NNN-tema.md`, pelo fluxo de `.claude/skills/construtor-equipe-pesquisar/SKILL.md` | Cada resposta com fonte e data; cada pergunta da etapa respondida ou marcada como não confirmada |
| `prova` | O menor código que responde "isto funciona?", em `projeto/provas/EE-nome/`, e o veredito: funciona, não funciona ou funciona com limites (quais) | O comando executado e a saída; o custo ou limite que apareceu |
| `ambiente` | Ferramentas, contas e acessos prontos; esqueleto do projeto compilando; `.claude/comandos.conf` preenchido | Cada comando de verificação e a saída |
| `código` | O código do plano e, se o projeto tiver testes, os testes | `BUILD`, `TESTE` e cada critério de aceite verificado |
| `deploy` | A publicação no destino, a versão publicada e como voltar atrás, escrito **antes** de publicar | A verificação feita no destino depois de publicar |
| `resultados` | As medições reais comparadas com o critério de pronto do ciclo | De onde veio cada número: comando, log ou painel informado pelo usuário |

Código de `prova` é descartável: não vira base do sistema sem passar por uma etapa de `código`.

## 1. Situar

1. Leia `privado/QUADRO.md`, `<ciclo>/ciclo.md` (a seção desta etapa e "Decidir depois") e `.claude/comandos.conf`. Leia as decisões e pesquisas que a etapa cita. A etapa é a de `$ARGUMENTS` ou a que está em "Fazendo".
2. Se a etapa não está em "Fazendo" no quadro, diga que o gerente ainda não a liberou (`/construtor-equipe-iniciar-etapa`) e pare.
3. Se a branch `ciclo-NN-etapa-EE` já existe, vá para ela e traga o que entrou no ciclo. Se der conflito, resolva aqui e faça o commit.
   ```bash
   git -C projeto switch ciclo-NN-etapa-EE
   ```
   ```bash
   git -C projeto merge ciclo-NN
   ```
   Se a "Revisão" de `<etapa>` pedir para levar a principal ao ciclo por causa de um conflito, faça isso antes: `git -C projeto switch ciclo-NN`, `git -C projeto merge <BRANCH_PRINCIPAL>`, resolva, faça o commit e volte para a branch da etapa.
4. Pelo `Status` em `<etapa>`:
   - arquivo não existe: vá ao passo 2;
   - `planejada`: se a "Revisão" trouxer mudanças, ajuste o plano a elas; depois retome no passo 3.3;
   - `em andamento` com correções pendentes na "Revisão": faça só as correções e vá ao passo 5;
   - `em andamento`: continue no passo 4, a partir do primeiro item não marcado;
   - `concluída`, `bloqueada` ou `decisão pendente`: a etapa já fechou. Diga ao usuário para rodar `/construtor-equipe-progresso` no gerente e pare;
   - `revisada`: a etapa já foi aprovada. Pare.

## 2. Apresentação

1. Mostre, a partir do `ciclo.md`: tipo, objetivo, entregáveis, critérios de aceite e o que fica fora.
2. Diga em poucas linhas como pretende fazer.
3. Pergunte se confirma. Mudança na etapa em si (entregáveis, critérios) é decisão do gerente: feche com `decisão pendente`.

## 3. Perguntas e plano

1. Antes de perguntar, confira para você mesmo o que a etapa precisa saber: escopo, dados, comportamento em erro e quando algo externo falha, números com unidade, nomes já usados no projeto, como saber que terminou. Pergunte só o que estiver faltando ou ambíguo **e** mudar o trabalho. O que já está nos documentos ou no código não vira pergunta.
2. Crie `<etapa>` no modelo de `.claude/modelos/documentos.md`, com as respostas, os padrões a seguir e o plano em checklist, e `Status: planejada`.
3. Revise o plano antes de mostrar: nada "a definir", nenhuma contradição com os documentos, cada critério de aceite verificável do jeito do tipo. Em etapa de `deploy`, o plano traz cada ação fora do git e como desfazer.
4. Mostre o plano. Com o ok, crie a branch a partir da branch do ciclo, se ainda não existe, e mude o `Status` para `em andamento`. Se `git -C projeto status` mostrar algo não commitado, mostre e pare.
   ```bash
   git -C projeto switch -c ciclo-NN-etapa-EE
   ```

## 4. Execução

1. Siga o checklist, marcando cada item ao terminar.
2. Em etapa com código, rode o `BUILD` ao longo do trabalho. Erro ou comportamento inesperado: siga a skill `construtor-equipe-depurar`, que define o que fazer conforme a origem do bug (casos 1, 2 e 3).
3. Registre em "Notas da execução" qualquer desvio, problema ou escolha feita no caminho.
4. **Fora do git** (servidor, banco, nuvem, serviço externo): antes de cada ação que altera algo, diga o que vai fazer e como desfazer, e espere o ok. Registre em "Alterações fora do git". Um cancelamento só desfaz o que está no git.
5. Ideia, pendência ou bug que não cabe aqui vai para "Para o backlog".
6. Leitura ou pesquisa ampla: use um subagente e traga só a conclusão.
7. **Testes**, só em etapa de `código` e se a linha "Testes" de `.claude/rules/projeto.md` for `por etapa`. Com o checklist pronto:
   1. Escritos por subagente: dispare **um** (tipo `general-purpose`) com a tarefa abaixo. Escritos pela sessão da etapa: faça você mesmo, com as mesmas regras.

      > Escreva os testes da etapa EE do ciclo NN. Leia os critérios de aceite em `<ciclo>/ciclo.md`, `<etapa>`, as convenções em `.claude/rules/` e `.claude/comandos.conf`. Veja o código da etapa com `git -C projeto diff ciclo-NN` e os arquivos novos. Teste o que os critérios pedem e as regras de negócio, sem banco nem rede reais. Crie ou altere só arquivos de teste, nunca o código do sistema. Se o código parecer errado ou não der para testá-lo sem mudá-lo, não corrija: relate. Rode o `TESTE` dentro de `projeto/`. Responda em no máximo 10 linhas: testes criados, resultado, falhas e o que não foi possível testar.
   2. Teste falhou: siga a skill `construtor-equipe-depurar` e corrija o código. Só altere um teste se ele entendeu o critério errado, e registre o motivo.
   3. Etapa sem lógica a testar: registre o motivo e siga.

## 5. Fechamento

**Bug antigo que atrapalha mesmo sem o ciclo (caso 3), com o ok do usuário para corrigir agora:** pule os itens 1 e 3. O status é `bloqueada`, e o "Fechamento" traz `Bug antigo (caso 3)`, a causa, os passos para reproduzir e a evidência.

1. Em etapa com código, revise o próprio diff (`git -C projeto diff ciclo-NN` e arquivos novos) e corrija o que achar, dentro do escopo: código que não precisava existir, duplicação do que já havia no projeto, falha silenciosa (erro capturado sem log, valor padrão escondendo falha).
2. Confira `git -C projeto status`: nenhum arquivo sensível (`.env`, `parametro.json`, chave, certificado).
3. Verifique cada critério de aceite agora, do jeito do tipo, e registre a evidência em `<etapa>`. Critério sem evidência fresca não passou.
4. Se comandos ou convenções mudaram, atualize `.claude/comandos.conf` ou `.claude/rules/` e mostre a alteração.
5. Preencha "Fechamento" e o `Status`:
   - `concluída`: todos os critérios de aceite têm evidência;
   - `bloqueada`: falta algo que não depende de você. Escreva o que falta e por quê;
   - `decisão pendente`: precisa de uma decisão do gerente. Escreva a decisão e as opções.
6. Faça o commit do que mudou em `projeto/`, na branch `ciclo-NN-etapa-EE`, e mostre a mensagem (`<Tipo>: <descrição>`, com `Adicao`, `Correcao`, `Refatoracao` ou `Docs`; se a etapa não está `concluída`, `Andamento`). Se a trava recusar o commit, corrija o que ela apontar. Etapa que não mexeu em `projeto/` (uma `pesquisa`, por exemplo) fecha sem commit: diga isso.
7. Comece a última resposta pelo status (ex.: `Etapa 03: concluída`), com um resumo curto do que foi feito. Termine dizendo ao usuário para voltar ao gerente e rodar `/construtor-equipe-progresso`. Não comece outra etapa, não faça merge nem push.
