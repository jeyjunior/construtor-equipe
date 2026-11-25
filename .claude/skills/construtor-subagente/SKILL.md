---
name: construtor-subagente
description: Regra de todo subagente do kit, em qualquer sessão, e o jeito de pesquisar. Use antes de disparar qualquer subagente (pesquisa, conferência, leitura pesada, testes, conversão) e quando for preciso pesquisar algo com fonte e data. Dá nota à tarefa, escolhe modelo e esforço, decide onde roda (subagente do app ou subagente pela CLI), valida os MCP, sobe um nível quando o resultado vem fraco e registra.
user-invocable: false
---

# Subagente

Vale para todo subagente disparado por qualquer sessão do kit. O texto da tarefa é o que a skill que dispara manda; esta regra decide **onde** e **com quê**. A nota, o modelo e o esforço são os mesmos rode ele no app (ferramenta de subagente da sessão) ou **pela CLI** (`claude -p`, por `.claude/bin/subagente-cli.sh`, no login atual da CLI ou na configuração apontada por `CONSTRUTOR_CLI_CONFIG`).

## 1. Configuração

Em `.claude/comandos.conf`, sem perguntar (vazio vale o padrão):

- `SUBAGENTES_VIA`: `app` ou `cli`. Vazio: `app`.
- `SUBAGENTES_MODELOS`: os liberados, do mais leve ao mais forte (`haiku sonnet opus fable`). Vazio: `haiku sonnet opus`.
- `SUBAGENTES_ESFORCO_MAX`: `low`, `medium`, `high`, `xhigh` ou `max`. Vazio: `high`.

Com `cli`, uma vez por sessão, `bash .claude/bin/subagente-cli.sh status`:
- `ok`: segue pela CLI;
- `ausente` (sem `claude` no PATH, ou `CONSTRUTOR_CLI_CONFIG` aponta para pasta que não existe), `sem-jq` ou `sem-login`: diga numa linha o que falta (`sem-login`: rodar `claude` num terminal e fazer login, com `CLAUDE_CONFIG_DIR` igual a `CONSTRUTOR_CLI_CONFIG` se ela estiver definida) e use o app nesta sessão.

## 2. Nota da tarefa

De 0 a 2 em cada critério, somados:

| Critério | 0 | 1 | 2 |
|---|---|---|---|
| Raciocínio | buscar ou listar | comparar ou resumir | decidir, projetar, achar causa |
| Volume | poucas fontes ou arquivos | dezenas | o projeto inteiro |
| Custo do erro | fácil de notar e refazer | atrapalha a próxima etapa | vira decisão, código ou dado errado |
| Rigor com dados | não se aplica | citar fonte | analisar sem inventar nem enviesar |

| Soma | Modelo · esforço inicial | Exemplos |
|---|---|---|
| 0–1 | haiku · low | dado pontual, ler um arquivo |
| 2–3 | sonnet · medium | pesquisa com várias fontes, conferência de build e testes |
| 4–5 | sonnet · high | comparar opções, analisar dados, lições do ciclo |
| 6–8 | opus · high | escrever testes, conversão, conferência final do ciclo |

Rigor com dados em 2 nunca fica abaixo de sonnet · medium. Fique dentro dos liberados e do teto: modelo fora dos liberados, use o liberado mais próximo (mais fraco: suba o esforço um nível). `fable` só por subida de nível ou pedido do usuário.

## 3. Onde roda

1. `app`: no app.
2. `cli` e a tarefa não usa MCP: pela CLI.
3. `cli` e usa MCP: `bash .claude/bin/subagente-cli.sh mcp` (prefixo, estado, nome). Todos `conectado`: pela CLI, com `--mcp`. Falta algum: rode no app (padrão) e diga qual faltou; o usuário pode conectar na CLI e pedir de novo.

MCP pela CLI: a CLI não pede confirmação no meio. Libere pelo nome exato (`<prefixo>__<ferramenta>`) só as ferramentas de **leitura**. Ferramenta que altera algo fora do projeto só com o ok do usuário para aquela ação, antes do disparo, registrada como alteração fora do git.

## 4. Disparar

Nota 2 ou mais: diga numa linha `<tarefa> → <app|cli>, <modelo>/<esforço> (nota N)`. O usuário pode trocar.

**Tarefa com conta** (valor, data, fuso, capital, probabilidade, volume): o pedido exige a conta escrita, com as entradas e cada passo. Antes de usar, refaça a conta ou confira por programa.

**App:** ferramenta de subagente, com `model` e `effort` da nota e o tipo que a skill manda (`general-purpose`, `Explore`).

**Pela CLI:** o prompt vai pela entrada padrão.

```bash
bash .claude/bin/subagente-cli.sh rodar <modelo> <esforço> [--mcp] [--verificar] [ferramenta...] <<'PROMPT'
<o mesmo prompt que iria para o subagente>
PROMPT
```

- Já vão liberados: `Read`, `Glob`, `Grep`, `WebSearch`, `WebFetch` e o git de leitura na forma `git -C projeto status|diff|log|show|ls-files|rev-parse|branch --list|config --get`. Caminho absoluto no `-C` e `cd` antes de git são negados pela CLI: o prompt pede a forma relativa.
- `--verificar` libera o `BUILD` e o `TESTE` de `.claude/comandos.conf` exatamente como estão (o subagente roda `cd projeto && <comando>`). Use em conferência e testes.
- Passe a mais só o que a tarefa precisa: `Write` e `Edit` quando ela grava, ferramentas de MCP. O que aqui pede confirmação lá é negado (inclusive editar `objetivo.md`: o subagente devolve o texto e quem disparou grava).
- A saída do comando é a resposta. Tarefa longa: em segundo plano. Independentes: em paralelo.
- Falhou (limite, erro, sem login, fora do liberado): mostre o erro e rode no app.

## 5. Conferir e subir um nível

A resposta está **fraca** quando: não responde o pedido; afirma sem a fonte exigida; traz número sem a conta; contradiz a si mesma ou o projeto; sai do formato; ou diz que não conseguiu por capacidade, não por falta de dado. Fraca: de novo um nível acima (próximo modelo liberado ou um esforço acima), até o teto; no teto, mostre ao usuário. Resposta correta de que você não gostou não é fraca.

## 6. Registrar

Nota 2 ou mais, subida de nível ou resultado fraco: uma linha em `privado/docs/subagentes.md` (modelo em `.claude/modelos/documentos.md`). Sessão só de consulta não registra. O encerramento do ciclo revisa esse registro.

## Pesquisa

Antes de pesquisar, leia `.claude/modelos/pesquisa.md` (fluxo, prompt e formato).
