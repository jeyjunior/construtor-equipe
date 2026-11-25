---
name: construtor-etapa
description: Roda na sessão vinculada aberta pelo gerente (/construtor-seguir). Conduz uma única etapa do ciclo - plano com um ok, execução conforme o tipo da etapa, fechamento com evidência e commit - registrando tudo no arquivo da etapa.
disable-model-invocation: true
argument-hint: "[número da etapa]"
---

# Etapa

Você é a **sessão desta etapa**, aberta pelo gerente (outra sessão; veja "Papéis" e "Contexto primeiro" no `CLAUDE.md`). Cuida só desta etapa, conversa direto com o usuário e, ao terminar, registra no arquivo da etapa como ela fechou.

`NN` é o ciclo, `EE` a etapa (dois dígitos), `<ciclo>` a pasta do ciclo indicada no quadro e `<etapa>` é `<ciclo>/etapas/EE-nome.md`.

- **Um ok só antes de executar** (o do plano, passo 2). Depois dele, siga até o fechamento; pare de novo só para ação fora do git ou decisão que o plano não cobre. Nesta sessão, "segue" aprova o plano; não rode skills do gerente (iniciar, seguir, encerrar-ciclo).
- **Você não edita `privado/QUADRO.md`** (o hook nega depois que você edita código). Tudo o que importa vai para `<etapa>`: o gerente não lê esta conversa.
- **Decisão que o plano não cobre:** dentro do escopo da etapa, proponha com um padrão, siga e grave em `privado/docs/decisoes/`. Se muda objetivo, arquitetura ou outras etapas, não decida: feche com `decisão pendente`.
- **Git:** só na branch `ciclo-NN-etapa-EE`, commit só no fechamento. Merge no ciclo e push são do gerente.
- **Segredos e contas:** você não pede, não digita e não lê senha, token ou chave. Criar conta, fazer login e preencher `privado/parametros/parametro.json` é com o usuário.

## Tipos de etapa

O tipo está no título da etapa em `ciclo.md`.

| Tipo | O que entrega | Evidência que fecha |
|---|---|---|
| `pesquisa` | `privado/docs/pesquisas/NNN-tema.md`, por `.claude/modelos/pesquisa.md` | Cada resposta com fonte e data; cada pergunta respondida ou marcada como não confirmada |
| `prova` | O menor código que responde "isto funciona?", em `projeto/provas/NN-EE-nome/`, e o veredito: funciona, não funciona ou funciona com limites (quais) | O comando executado e a saída; o custo ou limite que apareceu |
| `ambiente` | Ferramentas, contas e acessos prontos; esqueleto compilando; `.claude/comandos.conf` preenchido | Cada comando de verificação e a saída |
| `código` | O código do plano e, se o projeto tiver testes, os testes | `BUILD`, `TESTE` e cada critério de aceite verificado |
| `deploy` | A publicação no destino (servidor, nuvem, ou pacote e versão: NuGet, npm, tag), o commit publicado (`git -C projeto rev-parse --short HEAD`, só de código commitado) e como voltar atrás, escrito **antes** de publicar | A verificação feita no destino depois de publicar |
| `resultados` | As medições reais comparadas com o critério de pronto do ciclo | De onde veio cada número: comando, log ou painel informado pelo usuário |

- Código de `prova` é descartável: não vira base do sistema sem passar por uma etapa de `código`.
- `deploy` sem remoto (`git -C projeto remote` vazio): diga no plano que o código publicado só existe nesta pasta.
- **Pacote ou versão** (linha "Versão" de `.claude/rules/projeto.md`): o plano traz a versão nova (`MAIOR.MENOR.CORRECAO`: correção, funcionalidade, quebra de compatibilidade), onde ela muda (ex.: `<Version>` no `Directory.Build.props`), a nota de versão pública (`CHANGELOG.md` ou `release_X.Y.Z.*` na raiz de `projeto/`), o empacotamento (ex.: `dotnet pack`) e a publicação (ex.: `dotnet nuget push`). A chave do registro fica com o usuário (`privado/parametros/`); o push do pacote é ação fora do git, com ok antes, e é **irreversível** (no NuGet só dá para tirar da lista). A tag `vX.Y.Z` é criada pelo gerente no encerramento.
- Etapa que depende de tempo (janela de medição, execução agendada) não segura a sessão: feche com `aguardando` e o gerente reabre na data.

## 1. Situar

1. Leia `privado/QUADRO.md`, `<ciclo>/ciclo.md` (a seção desta etapa e "Decidir depois"), `.claude/comandos.conf` e as decisões e pesquisas que a etapa cita. A etapa é a de `$ARGUMENTS` ou a que está em "Fazendo".
2. Se a etapa não está em "Fazendo", diga que o gerente ainda não a liberou (`/construtor-seguir`) e pare.
3. `git -C projeto status`. Arquivos não commitados na branch desta etapa são de uma sessão anterior que caiu: mostre e faça o commit `Andamento: trabalho da sessão anterior` (padrão), ou descarte se o usuário pedir. Em outra branch, mostre e pare.
   Se a branch `ciclo-NN-etapa-EE` já existe, vá para ela e traga o que entrou no ciclo; conflito, resolva aqui e faça o commit.
   ```bash
   git -C projeto switch ciclo-NN-etapa-EE
   ```
   ```bash
   git -C projeto merge ciclo-NN
   ```
   Se a "Revisão" de `<etapa>` pedir para levar a principal ao ciclo, faça antes: `git -C projeto switch ciclo-NN`, `git -C projeto merge <BRANCH_PRINCIPAL>`, resolva, commit, e volte para a branch da etapa.
4. Pelo `Status` em `<etapa>`:
   - arquivo não existe: passo 2;
   - `planejada`: ajuste o plano ao que a "Revisão" pede e retome no passo 2 (só o que mudou);
   - `em andamento` com correções pendentes na "Revisão": faça só as correções e vá ao passo 4;
   - `em andamento`: passo 3, a partir do primeiro item não marcado;
   - `aguardando`: data chegou, mude para `em andamento` e siga no passo 3 com o que faltava; não chegou, diga a data e pare;
   - `concluída`, `bloqueada` ou `decisão pendente`: já fechou. Diga para voltar ao gerente e dizer "segue". Pare;
   - `revisada`: já aprovada. Pare.

## 2. Plano (um ok)

1. Confira para você o que a etapa precisa saber: escopo, dados, comportamento em erro e quando algo externo falha, números com unidade, nomes já usados no projeto, como saber que terminou. O que está nos documentos, no código ou no contexto que o usuário deu não vira pergunta.
2. Crie `<etapa>` no modelo de `.claude/modelos/documentos.md`, com as respostas, os padrões a seguir, o plano em checklist e `Status: planejada`. Sem "a definir", sem contradição com os documentos, cada critério verificável do jeito do tipo; em `deploy`, cada ação fora do git e como desfazer.
3. Mostre numa resposta só: tipo, objetivo, critérios de aceite, o que fica fora, o plano e as perguntas que faltam, cada uma com o padrão sugerido (se faltar alguma). Mudança nos entregáveis ou nos critérios é do gerente: feche com `decisão pendente`.
4. Com o ok ("segue com os padrões" vale), crie a branch a partir do ciclo, se não existe, e mude o `Status` para `em andamento`. Algo não commitado: mostre e pare.
   ```bash
   git -C projeto switch -c ciclo-NN-etapa-EE
   ```

## 3. Execução

1. Siga o checklist, marcando cada item.
2. Com código, rode o `BUILD` ao longo do trabalho. Erro ou comportamento inesperado: skill `construtor-depurar` (casos 1, 2 e 3).
3. Desvio, problema ou escolha feita no caminho: "Notas da execução".
4. **Fora do git:** antes de cada ação que altera algo, diga o que vai fazer e como desfazer, e espere o ok. Registre em "Alterações fora do git".
5. Ideia, pendência ou bug que não cabe aqui: "Para o backlog".
6. Leitura ou pesquisa ampla: subagente (`.claude/skills/construtor-subagente/SKILL.md`), trazendo só a conclusão.
7. **Testes**, só em `código` e com "Testes: por etapa" em `.claude/rules/projeto.md`:
   1. Escritos por subagente: dispare **um** (`general-purpose`; pela CLI, com `Write`, `Edit` e `--verificar`). Escritos pela sessão: faça você, com as mesmas regras.

      > Escreva os testes da etapa EE do ciclo NN. Leia os critérios de aceite em `<ciclo>/ciclo.md`, `<etapa>`, as convenções em `.claude/rules/` e `.claude/comandos.conf`. Veja o código da etapa com `git -C projeto diff ciclo-NN` e os arquivos novos. Teste o que os critérios pedem e as regras de negócio, sem banco nem rede reais. Crie ou altere só arquivos de teste. Se o código parecer errado ou não der para testá-lo sem mudá-lo, não corrija: relate. Rode o `TESTE` (`cd projeto && <TESTE>`). No máximo 10 linhas: testes criados, resultado, falhas e o que não foi possível testar.
   2. Teste falhou: `construtor-depurar` e corrija o código. Só altere um teste que entendeu o critério errado, com o motivo registrado.
   3. Sem lógica a testar: registre o motivo e siga.

## 4. Fechamento

**Bug antigo (caso 3) que atrapalha mesmo sem o ciclo, com o ok do usuário para corrigir agora:** pule os itens 1 e 3; status `bloqueada`, com `Bug antigo (caso 3)`, a causa, os passos para reproduzir e a evidência no "Fechamento".

1. Com código, revise o próprio diff (`git -C projeto diff ciclo-NN` e arquivos novos): código que não precisava existir, duplicação, falha silenciosa. Corrija dentro do escopo.
2. `git -C projeto status`: nenhum arquivo sensível.
3. Verifique cada critério de aceite agora e registre a evidência em `<etapa>`. Critério sem evidência fresca não passou.
4. Comandos ou convenções mudaram: atualize `.claude/comandos.conf` ou `.claude/rules/` e mostre.
5. "Fechamento" e `Status`:
   - `concluída`: todo critério tem evidência;
   - `aguardando`: o resto só se verifica depois de uma data. `Aguardando até: AAAA-MM-DD`, o que falta verificar e o que não pode mudar até lá;
   - `bloqueada`: falta algo que não depende de você, com o porquê;
   - `decisão pendente`: a decisão e as opções.
6. Commit do que mudou em `projeto/`, na branch da etapa, no padrão de commits do `CLAUDE.md` (etapa não `concluída`: `Andamento`). Mostre a mensagem. Trava recusou: corrija o que ela apontou. Etapa sem mudança em `projeto/` fecha sem commit: diga isso.
7. Comece a última resposta pelo status (ex.: `Etapa 03: concluída`), com um resumo curto, e diga para voltar ao gerente e dizer "segue". Não comece outra etapa, não faça merge no ciclo nem push.
