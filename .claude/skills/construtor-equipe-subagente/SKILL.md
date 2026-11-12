---
name: construtor-equipe-subagente
description: Regra de todo subagente do kit, em qualquer sessão. Use antes de disparar qualquer subagente (pesquisa, conferência, leitura pesada, testes, conversão). Dá nota à tarefa, escolhe modelo e esforço, decide a conta (principal no app ou secundária na CLI), valida os MCP que a tarefa precisa, sobe um nível quando o resultado vem fraco e registra o disparo.
user-invocable: false
---

# Subagente

Vale para todo subagente disparado por qualquer sessão do kit. A nota, o modelo e o esforço são os mesmos rode ele na conta principal (ferramenta de subagente do app) ou na secundária (CLI, por `.claude/bin/secundaria.sh`). O texto da tarefa é o que a skill que dispara manda; esta regra decide só **onde** e **com quê**.

## 1. Configuração, uma vez por sessão

Leia em `.claude/comandos.conf`:

- `SUBAGENTES_CONTA`: `principal`, `secundaria` ou vazio (perguntar).
- `SUBAGENTES_MODELOS`: os modelos liberados, do mais leve ao mais forte (`haiku sonnet opus fable`). Vazio vale `haiku sonnet opus`.
- `SUBAGENTES_ESFORCO_MAX`: o teto de esforço (`low`, `medium`, `high`, `xhigh`, `max`). Vazio vale `high`.

**Conta da sessão:**

1. `SUBAGENTES_CONTA="principal"`: use a principal e pule o resto deste passo.
2. Rode `bash .claude/bin/secundaria.sh status`:
   - `ausente` ou `sem-jq`: use a principal. Não pergunte. Em `sem-jq`, diga numa linha que a secundária precisa de jq.
   - `sem-login`: diga que a secundária existe mas não está logada (o usuário abre um terminal com `$env:CLAUDE_CONFIG_DIR` apontando para ela e roda `claude`). Use a principal nesta sessão.
   - `ok`: siga.
3. `SUBAGENTES_CONTA="secundaria"`: use a secundária sem perguntar. Vazio: pergunte em múltipla escolha: (1) conta principal, (2) secundária nesta sessão, (3) secundária sempre neste projeto. Na opção 3, grave `SUBAGENTES_CONTA="secundaria"`.

**Modelos e teto:** se `SUBAGENTES_MODELOS` ou `SUBAGENTES_ESFORCO_MAX` estiverem vazios e esta sessão for o gerente, pergunte quais modelos ficam liberados e qual o esforço máximo, sugerindo `haiku sonnet opus` e `high`, e grave. As outras sessões usam os valores padrão sem perguntar.

A sessão de consulta só lê: usa a conta escolhida, mas não grava nada (nem `comandos.conf`, nem o registro do passo 6).

## 2. Nota da tarefa

Antes de cada disparo, dê de 0 a 2 em cada critério e some:

| Critério | 0 | 1 | 2 |
|---|---|---|---|
| Raciocínio | buscar ou listar | comparar ou resumir | decidir, projetar, achar causa |
| Volume | poucas fontes ou arquivos | dezenas | o projeto inteiro |
| Custo do erro | fácil de notar e refazer | atrapalha a próxima etapa | vira decisão, código ou dado errado |
| Rigor com dados | não se aplica | citar fonte | analisar sem inventar nem enviesar |

| Soma | Nível | Modelo · esforço inicial | Exemplos |
|---|---|---|---|
| 0–1 | Simples | haiku · low | buscar um dado pontual, listar cartões, ler um arquivo |
| 2–3 | Padrão | sonnet · medium | pesquisa com várias fontes, consulta, conferência de build e testes |
| 4–5 | Análise | sonnet · high | comparar opções, analisar dados, lições do ciclo |
| 6–8 | Crítico | opus · high | escrever testes, conversão, conferência final do ciclo |

- O rigor com dados em 2 nunca deixa a tarefa abaixo do nível Padrão.
- Fique dentro de `SUBAGENTES_MODELOS` e do teto. Modelo da tabela fora dos liberados: use o liberado mais próximo e, se for mais fraco, suba o esforço um nível, até o teto.
- `fable` só entra pela subida de nível (passo 5) ou a pedido do usuário, e só se estiver liberado.

## 3. Onde roda

Siga na ordem:

1. **Conta da sessão é a principal:** principal.
2. **A tarefa precisa de MCP?** Liste os servidores que ela usa (Trello, Notion, outro conector). Não precisa: secundária.
3. **Precisa:** rode `bash .claude/bin/secundaria.sh mcp`. Cada linha traz o prefixo das ferramentas, o estado e o nome. Todos os servidores necessários `conectado`: secundária, com `--mcp`.
4. **Falta algum:** pergunte em múltipla escolha, dizendo qual falta:
   1. **Habilitar na CLI:** o usuário conecta o servidor na conta secundária (no claude.ai dela, ou `claude mcp add` num terminal com `$env:CLAUDE_CONFIG_DIR` apontando para ela) e avisa. Volte ao item 3.
   2. **Executar na principal:** subagente normal, nesta conta.
   3. **Abortar:** a tarefa não roda. Diga o que ficou sem fazer.

**MCP na secundária:** a CLI não pede confirmação no meio. Libere pelo nome exato (`<prefixo>__<ferramenta>`) só as ferramentas de **leitura** de que a tarefa precisa. Ferramenta que **altera** algo fora do projeto (mover cartão, editar página, publicar) só entra com o ok do usuário para aquela ação, dado antes do disparo, e é registrada como alteração fora do git. Os nomes das ferramentas são os mesmos que você vê nesta sessão para o mesmo serviço, com o prefixo da secundária.

## 4. Disparar

Antes, diga numa linha: `<tarefa> → <conta>, <modelo>/<esforço> (nota N)`. O usuário pode trocar.

**Principal:** ferramenta de subagente do app, com `model` e `effort` da nota. O tipo continua o que a skill manda (`general-purpose`, `Explore`).

**Secundária:** o prompt vai pela entrada padrão.

```bash
bash .claude/bin/secundaria.sh rodar <modelo> <esforço> [--mcp] [ferramenta...] <<'PROMPT'
<o mesmo prompt que iria para o subagente>
PROMPT
```

- Leitura e pesquisa já vão liberadas (`Read`, `Glob`, `Grep`, `WebSearch`, `WebFetch`). Passe só o que a tarefa precisa a mais: `Write` e `Edit` quando ela grava (testes, análise da conversão), `"Bash(<comando>)"` para o `BUILD` e o `TESTE` de `.claude/comandos.conf`, e as ferramentas de MCP do passo 3. As permissões e os hooks do kit valem lá; os comandos que aqui pedem confirmação lá são negados.
- A saída do comando é a resposta do subagente. Tarefa longa: rode em segundo plano e leia quando terminar. Tarefas independentes podem rodar em paralelo.
- Falhou (limite da conta, erro, sem login, modelo ou esforço fora do liberado): mostre o erro e pergunte se roda na principal.

## 5. Conferir e subir um nível

Leia a resposta antes de usar. Ela está **fraca** quando: não responde o que foi pedido; afirma sem a fonte que o pedido exigia; se contradiz ou contradiz o que está escrito no projeto; sai do formato pedido; ou diz que não conseguiu por falta de capacidade, não de dado.

Fraca: rode de novo um nível acima (o próximo modelo liberado, ou o mesmo modelo um esforço acima), até o teto. No teto, mostre ao usuário o que veio e pergunte. Resposta correta de que você não gostou não é fraca.

## 6. Registrar

Acrescente uma linha por disparo em `privado/docs/subagentes.md`, no modelo de `.claude/modelos/documentos.md`. A subida de nível é um disparo novo. O `/construtor-equipe-encerrar-ciclo` revisa esse registro para ajustar a tabela do passo 2.
