# Construtor Equipe

Kit para o [Claude Code](https://claude.com/claude-code) que conduz um projeto com **um gerente e uma sessão separada para cada etapa**, em volta de **um quadro** (backlog, a fazer, fazendo, feito, homologado).

Você abre uma sessão no Root e diz o que quer, com todo o contexto que tiver: `/construtor-iniciar quero X, use .NET e JJCore, sem custo`. O gerente absorve o que você disse, mostra o que entendeu, pergunta **numa rodada só** o que falta (cada pergunta com um padrão sugerido; "ok com os padrões" aceita todos), planeja e abre as etapas. Pergunta que não bloqueia vira pendência no quadro.

> **Estado:** v3 (3.0.0). Base: a v2 usada no Bot Loteria e no Benchmark Crypto, revista por três refatorações e duas análises. As travas, o conversor e o instalador têm autoteste; o fluxo das skills, não.

## Estrutura

```
meu-projeto/                ← o "Root": abra o Claude Code sempre aqui
├── CLAUDE.md, .claude/     o kit (regras, skills, hooks, permissões, modelos)
├── projeto/                código, README.md e notas de versão. ÚNICO repositório git, o que vai para o GitHub
├── privado/                fora de qualquer git: QUADRO.md, docs/, parametros/ (o Claude não lê), origem/
└── conversor/              entrada da conversão de um projeto existente
```

Produto fica em `projeto/` e pode ser público; processo (quadro, briefing, pesquisas, decisões, lições) fica em `privado/`. **`privado/` não tem histórico nem backup**: cuide você do backup.

## Comandos

| Onde | Comando | O que faz |
|---|---|---|
| Gerente | `/construtor-iniciar [contexto]` | Entrada única: conversão, projeto novo, ciclo novo ou ciclo curto. Um ok no plano inteiro. |
| Gerente | `/construtor-proxima-etapa` | Confere a etapa que fechou (subagente), aprova com você, faz o merge no ciclo e abre a próxima. Reabre etapa que caiu ou que esperava uma data. |
| Gerente | `/construtor-encerrar-ciclo` | Fecha o ciclo: conferência, lições, documentos, merge na principal com o seu ok, versão e tag. `cancelar <motivo>` cancela. |
| Qualquer | `/construtor-ciclo-curto [o quê]` | Trabalho pequeno numa sessão, direto para "Feito". |
| Etapa | `/construtor-etapa` | Roda sozinha na sessão aberta pelo gerente: plano com um ok, execução, fechamento com evidência. |

Por etapa, você dá **um** comando no gerente (`/construtor-proxima-etapa`); na sessão da etapa, aprova o plano. Perguntas sobre o projeto: qualquer sessão no Root, só lendo.

## Ciclo

1. **Iniciar:** briefing absorvido do seu contexto, pesquisa só do que ninguém sabe (escolha sua não é pesquisada), decisões só do que a primeira etapa precisa, etapas com tipo (`pesquisa`, `prova`, `ambiente`, `código`, `deploy`, `resultados`). Um ok. A primeira etapa abre em seguida.
2. **Etapa:** sessão vinculada, contexto limpo, branch `ciclo-NN-etapa-EE`. Etapa que depende de tempo (7 dias de medição) fecha como `aguardando` e é reaberta na data, sem segurar a pasta.
3. **Seguir:** conferência por subagente, sua decisão, merge no ciclo, branch da etapa apagada, próxima etapa.
4. **Encerrar:** merge na principal só com ok explícito; versão, tag e "Homologado" quando o projeto usa versão.

```
main ────────────────┬───────────────────────────────► merge no encerramento
  │                  └ curto-014 ──┘
  └─ ciclo-02 ──────┬───────────────────┬───────────┘
                    └ ciclo-02-etapa-01 └ ciclo-02-etapa-02
```

## Biblioteca ou projeto publicado

A linha "Versão" de `.claude/rules/projeto.md` diz onde fica a versão, onde ficam as notas (`CHANGELOG.md`, `release_X.Y.Z.*` na raiz de `projeto/`, permitidas pelas travas), como empacota e publica e se há branch `release/X.Y.Z`. Publicar um pacote é uma etapa de `deploy`: o plano traz a versão nova, a nota e o comando; o push do pacote pede o seu ok e é marcado como irreversível. A linha "Commits" adota o padrão do histórico (ex.: `feat:`/`fix:`).

## Subagentes

Leitura pesada vai para subagentes (`.claude/skills/construtor-subagente/SKILL.md`): nota da tarefa → modelo e esforço, dentro dos liberados. Rodam no app ou **pela CLI** (`claude -p`, com `.claude/bin/subagente-cli.sh`):

| `comandos.conf` | Valores | Vazio |
|---|---|---|
| `SUBAGENTES_VIA` | `app` ou `cli` | `app` |
| `SUBAGENTES_MODELOS` | `haiku sonnet opus fable` (os liberados) | `haiku sonnet opus` |
| `SUBAGENTES_ESFORCO_MAX` | `low` … `max` | `high` |

Pela CLI, o subagente usa o **login atual da CLI** (rode `claude` num terminal uma vez e faça login). Para outro login, crie uma pasta de configuração (`$env:CLAUDE_CONFIG_DIR = "$HOME\.claude-cli2"; claude`, login, `/exit`) e defina a variável `CONSTRUTOR_CLI_CONFIG` com esse caminho. O script entrega à CLI as suas regras globais, o `CLAUDE.md` e as rules do projeto e as travas do kit; o que aqui pede confirmação lá é negado. Já vão liberados a leitura, a pesquisa e o git de leitura (`git -C projeto status|diff|log|show...`); `--verificar` libera o `BUILD` e o `TESTE` exatos (o subagente roda `cd projeto && <comando>`). A CLI nega caminho absoluto no `git -C` e `cd` antes de git: as instruções pedem a forma relativa. Para conferir: `bash .claude/bin/subagente-cli.sh regras | instrucoes | ferramentas --verificar`.

## Travas

| Trava | O que faz |
|---|---|
| `hooks/proteger-estrutura.sh` | Nega documentação e arquivo sensível em `projeto/`, coisa solta no Root, código na principal e na branch do ciclo, e o quadro à sessão que editou código numa branch de trabalho. |
| `git-hooks/pre-commit` | Recusa commit com documentação, arquivo sensível, segredo, ou código direto na principal. Aceita `git rm --cached` de sensível. |
| `hooks/bloquear-segredos.sh` | Nega edições que escrevem chaves, tokens ou senhas literais. |
| `hooks/bloquear-comandos.sh` | Bloqueia comandos destrutivos, os que desligam a trava de commit (`--no-verify`, `-n`, `core.hooksPath`; texto entre aspas não conta), leitura de `privado/parametros/` e `git branch -d` de etapa em "Fazendo". |
| `hooks/verificar-ambiente.sh` | Ao abrir a sessão, avisa de estrutura fora do padrão, ferramenta faltando ou projeto em `conversor/`. |
| `hooks/formatar.sh`, `verificar-build.sh` | Formatam depois de cada edição e compilam ao fim da resposta, só na sessão que editou código. |
| `settings.json` | Nega ler segredos; pede confirmação para `git push`, `init`, `reset --hard` e `remote add`, no Bash e no PowerShell. |

Sensível em `projeto/`: `.env`, `parametro.json`, chaves e certificados, `*.connection`, `.pgpass`, `.my.cnf`, `*.ppk`, `*.kdbx`. Limites: o bloqueio de segredos olha edições e commits, não arquivos gravados por shell (pegos no commit); o de comandos olha o texto do comando, não o que um script roda por dentro.

## Requisitos

App Claude desktop (aba Code: as etapas são sessões vinculadas), `git`, `bash` (no Windows, o Git Bash) e [`jq`](https://jqlang.org) (recomendado; sem ele os bloqueios ficam menos precisos e o subagente pela CLI não roda).

## Instalação

No Windows, dê dois cliques em `instalar.cmd` (abre no Git Bash). Em qualquer sistema: `bash instalar.sh`.

O script pergunta onde fica o Root e o nome da pasta, e segue pelo que encontrar:

| A pasta | O que ele faz |
|---|---|
| Não existe ou está vazia | Cria o Root com o kit. Pergunta se há um projeto existente para trazer: se houver, copia para `conversor/` (sem `bin`, `obj`, `.vs`, `node_modules` e outras pastas geradas; o original não muda). |
| Já tem o kit | Atualiza o kit (veja abaixo). |
| Tem outra coisa | Para sem mexer. Para trazer esse projeto, use um Root novo e informe a pasta como o projeto existente. |

Depois, abra o Claude Code no Root e diga o que quer: `/construtor-iniciar <contexto>`. Com projeto em `conversor/`, o iniciar faz a conversão: para se houver código sem commit ou sem push, detecta e grava a branch principal (`main`, `master`...), traz o código com o histórico, guarda os documentos em `privado/origem/`, monta documentos e quadro a partir do código e passa as regras antigas pela sua aprovação numa rodada. Chaves e arquivos de conexão não vêm: você copia para `privado/parametros/`. Nada é alterado no servidor, no banco nem no registro de pacotes. Um repositório por conversão; submódulos não são copiados.

Sem perguntas: `bash instalar.sh <root> [projeto-existente]`.

## Atualizar o kit num projeto

Feche as sessões do Claude Code do projeto e rode o instalador apontando para o Root dele. O script:

1. Guarda o kit atual em `privado/kit-anterior/<data>/`.
2. Troca o que é do kit: `CLAUDE.md`, as skills `construtor-*` e as `construtor-equipe-*` da v2 (as que saíram do kit são apagadas; skills suas ficam, desde que o nome não comece com `construtor-`), `hooks/`, `git-hooks/`, `bin/`, `modelos/`, `rules/parametros.md` e `VERSAO`.
3. Mantém o que é do projeto: o `comandos.conf` vai para o modelo novo com os seus valores (`SUBAGENTES_CONTA` da v2 vira `SUBAGENTES_VIA`); o `settings.json` recebe as permissões e hooks do kit novo e mantém as suas regras e chaves; `settings.local.json` e as outras `rules/` ficam; em `rules/projeto.md` entram as linhas "Commits" e "Versão" que faltarem.
4. Liga a trava de commit, se estiver desligada, e mostra o que fica com você: as linhas novas do `projeto/.gitignore` (commit `Docs:` na principal) e as branches que já entraram no ciclo ou na principal (pergunta se apaga; o padrão é não).
5. Roda os autotestes do kit.

Não toca no quadro, em `privado/docs/` nem no código; o `privado/parametros/parametro.json` só é criado, com a estrutura base, se não existir. Rodar de novo não muda nada. Precisa do `jq`.

Da v2: os comandos perdem o `equipe` do nome (`/construtor-equipe-iniciar` vira `/construtor-iniciar`, e assim por diante), e seis skills deixam de existir como comando:

| Skill da v2 | Na v3 |
|---|---|
| `iniciar-etapa` | `/construtor-proxima-etapa` abre a próxima etapa |
| `progresso` | `/construtor-proxima-etapa` confere a etapa que fechou, faz o merge no ciclo e atualiza o quadro |
| `homologar` | `/construtor-encerrar-ciclo` registra versão, tag e "Homologado"; sem ciclo aberto, o `/construtor-ciclo-curto` faz o mesmo quando você publica o que está em "Feito" |
| `cancelar-ciclo` | `/construtor-encerrar-ciclo cancelar <motivo>` |
| `pesquisar` | subagentes de pesquisa no planejamento do `/construtor-iniciar`, ou etapa do tipo `pesquisa` |
| `consultar` | qualquer sessão aberta no Root só para perguntar |

Etapa presa em "Fazendo" esperando uma data passa a `aguardando`. No arquivo dela, `Status: aguardando` com `Aguardando até: AAAA-MM-DD` no "Fechamento"; no quadro, `aguardando até AAAA-MM-DD, sem sessão`. Se os subagentes rodavam pela CLI noutro login (`~/.claude-secundaria`), o script mostra como definir `CONSTRUTOR_CLI_CONFIG`.

## Testes do kit

```bash
bash .claude/bin/testar-hooks.sh
```

```bash
bash .claude/bin/testar-converter.sh
```

Rodam em pasta temporária, também dentro de um projeto real (usam um `projeto/` próprio, não o seu). Na pasta do kit, `bash testar-instalar.sh` testa o instalador.
