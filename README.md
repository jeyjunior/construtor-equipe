# Construtor Equipe

Kit para o [Claude Code](https://claude.com/claude-code) que conduz um projeto de software com **um gerente e uma sessão separada para cada etapa**, em volta de **um quadro** que diz o que há para fazer, o que está sendo feito, o que foi feito e o que já foi homologado.

Você abre uma sessão, roda `/construtor-equipe-iniciar` e ela descobre onde o projeto está. Se for trabalho novo, o gerente faz um briefing curto, manda pesquisar o que ninguém sabe, decide com você só o necessário, divide o trabalho em etapas e abre cada uma numa sessão própria, com contexto limpo. Se for algo pequeno, resolve na mesma sessão, sem ciclo.

> **Experimental:** esta versão ainda não foi usada de ponta a ponta num projeto real. As travas e o conversor têm autoteste; o fluxo das skills, não.

---

## Como funciona

### Estrutura

```
meu-projeto/                ← o "Root": abra o Claude Code sempre aqui
├── CLAUDE.md               regras do kit e papéis (carregadas em toda sessão)
├── .claude/                skills, hooks, permissões e modelos do kit
├── projeto/                só código e README.md. É o ÚNICO repositório git e o que vai para o GitHub
├── privado/                fora de qualquer git
│   ├── QUADRO.md           backlog, a fazer, fazendo, feito, homologado
│   ├── docs/
│   │   ├── objetivo.md, arquitetura.md
│   │   ├── decisoes/       uma decisão por arquivo
│   │   ├── pesquisas/      uma pesquisa por arquivo, com fonte e data
│   │   └── ciclos/NN-nome/ ciclo.md (briefing, etapas, lições) e etapas/
│   ├── parametros/         parametro.json, chaves e certificados (o Claude não lê nem grava)
│   └── origem/             só depois de uma conversão: instruções e documentos antigos
└── conversor/              entrada da conversão. Nunca vai para o GitHub.
```

O que é **produto** fica em `projeto/` e pode ser público; o que é **processo** (quadro, briefing, pesquisas, decisões, lições) fica em `privado/` e nunca vai para o GitHub. **`privado/` não tem histórico nem backup:** um arquivo sobrescrito ou perdido não volta. Cuide você do backup dessa pasta.

### O quadro

`privado/QUADRO.md` é um arquivo só, com uma linha por item e o detalhe em `privado/docs/`:

| Lista | O que tem |
|---|---|
| Situação | ciclo aberto, sessão aberta, próximo passo, decisões pendentes |
| Backlog | ideias, pedidos e bugs que podem virar trabalho |
| A fazer | as etapas do ciclo aberto que ainda não começaram |
| Fazendo | a etapa com sessão aberta |
| Feito | aprovado por você e já na branch do ciclo ou na principal |
| Homologado | publicado ou validado, agrupado por versão |

Só o gerente edita o quadro. As versões antigas de "Homologado" vão para `privado/docs/historico.md`, para o quadro não crescer sem limite.

### Os dois caminhos

**Ciclo** — uma implementação com começo, meio e fim, e um gerente só dela:

1. **`/construtor-equipe-iniciar`**: briefing curto (o que, para quem, limite de custo, o que você já tem, o que fica de fora, o que entra: testes, deploy, resultados). Fecha com a lista do que não se sabe.
2. **Pesquisa**: subagentes respondem essa lista com fonte e data. O que a pesquisa não confirma vira etapa de `prova`.
3. **Decisões**: só o que a primeira etapa precisa. O resto fica anotado na etapa que vai precisar.
4. **Etapas**: só as necessárias, cada uma com um tipo.
5. **`/construtor-equipe-iniciar-etapa`**: abre a etapa numa sessão vinculada, com contexto limpo. Lá, o `/construtor-equipe-etapa` faz perguntas, mostra o plano, executa e fecha com evidência.
6. **`/construtor-equipe-progresso`**: um subagente confere a entrega e você decide: aprovar, corrigir ou resolver uma pendência. Depois de pesquisa, prova ou resultados, o gerente pergunta se o plano muda.
7. **`/construtor-equipe-encerrar-ciclo`**: confere o ciclo, registra as lições, atualiza a arquitetura e o README do projeto, leva para a principal com o seu ok e pergunta pela homologação. A sessão do gerente termina aqui.

**Ciclo curto** — algo que cabe numa sessão e não pede decisão de projeto: `/construtor-equipe-ciclo-curto` (ou `/construtor-equipe-iniciar`, que oferece esse caminho). Faz, prova, atualiza os documentos que a mudança afeta, leva para a principal com o seu ok e registra direto em "Feito".

**Consulta** — não é um caminho de trabalho: `/construtor-equipe-consultar`, numa sessão à parte, responde sobre a situação, o que foi feito e por quê, ou conversa sobre ideias, sem alterar nada e sem ocupar o gerente. Funciona com ciclo aberto. O que surgir dali você leva ao gerente.

### Tipos de etapa

| Tipo | O que entrega | O que fecha |
|---|---|---|
| `pesquisa` | um arquivo em `privado/docs/pesquisas/` | cada resposta com fonte e data |
| `prova` | o menor código que responde "funciona?" | o comando executado e a saída |
| `ambiente` | ferramentas, contas, esqueleto compilando | cada comando de verificação |
| `código` | o código do plano e os testes, se houver | build, testes e critérios de aceite |
| `deploy` | a publicação e como voltar atrás | a verificação no destino |
| `resultados` | medições comparadas com o critério de pronto | de onde veio cada número |

### Papéis e branches

```
main ────────────────┬───────────────────────────────► merge no /construtor-equipe-encerrar-ciclo
  │                  └ curto-014 ──┘
  └─ ciclo-02 ──────┬───────────────────┬───────────┘
                    └ ciclo-02-etapa-01 └ ciclo-02-etapa-02
```

| | Gerente | Sessão de etapa | Sessão de ciclo curto |
|---|---|---|---|
| Quem abre | você, no Root | o gerente | você, ou o gerente para um bug antigo |
| Branch | principal e `ciclo-NN` | `ciclo-NN-etapa-EE` | `curto-NNN` |
| Escreve código | não (o hook nega) | sim | sim |
| Edita o quadro | sim | não (o hook nega) | só depois do merge na principal |
| Merge | etapa no ciclo; ciclo na principal, com o seu ok | não | na principal, com o seu ok |

A regra é aplicada pela branch atual de `projeto/`: na principal e na branch do ciclo não se edita código (só o `README.md`); nas branches de etapa e de ciclo curto não se edita o quadro.

### Travas

| Trava | O que faz |
|---|---|
| `hooks/proteger-estrutura.sh` | Nega documentação e arquivo sensível em `projeto/`, qualquer coisa solta no Root e as edições que não cabem ao papel da branch atual. |
| `git-hooks/pre-commit` | Recusa commit (de qualquer pessoa) com documentação, arquivo sensível ou segredo, e código direto na principal. |
| `projeto/.gitignore` | Ignora `.md` (menos o `README.md` da raiz), `docs/`, `.env` e chaves. |
| `hooks/bloquear-segredos.sh` | Nega edições que escrevem chaves, tokens ou senhas literais. |
| `hooks/bloquear-comandos.sh` | Bloqueia comandos destrutivos. |
| `hooks/verificar-ambiente.sh` | Ao abrir a sessão, avisa se a estrutura está fora do padrão, se falta ferramenta ou se há projeto em `conversor/`. |
| `hooks/formatar.sh` e `verificar-build.sh` | Formatam o arquivo depois de cada edição e compilam ao fim de cada resposta, só na sessão que editou código. |
| `settings.json` | Nega leitura de `privado/parametros/`, `.env` e `parametro.json`, e pede confirmação para `git push`, `git init` e `reset --hard`. |

Limites conhecidos: o bloqueio de segredos olha edições e commits, não arquivos gravados por comando de shell (esses só são pegos no commit); e as listas de padrões pegam o óbvio, não tudo.

---

## Requisitos

- **App Claude desktop, aba Code**: as etapas rodam em sessões vinculadas, que só existem no app.
- `git`
- `bash`: no Windows, o Git Bash que vem com o Git for Windows
- [`jq`](https://jqlang.org): recomendado. Sem ele, os bloqueios funcionam em modo menos preciso e o kit avisa.

## Instalação

O kit é uma **pasta modelo**: copie para um projeto novo e apague este `README.md`. O único repositório git deve ser `projeto/`; se você clonou o kit, apague também o `.git` do Root.

## Uso

1. No app Claude desktop, abra uma sessão Code no Root. Essa é o gerente.
2. Rode `/construtor-equipe-iniciar` e responda ao briefing. Ele pergunta antes de criar o git em `projeto/` e de ligar a trava de commit.
3. Rode `/construtor-equipe-iniciar-etapa`. Na sessão que abrir, responda às perguntas e aprove o plano.
4. Quando a etapa terminar, volte ao gerente e rode `/construtor-equipe-progresso`.
5. Repita 3 e 4 até o fim das etapas e rode `/construtor-equipe-encerrar-ciclo`.
6. Para o próximo trabalho, abra uma sessão nova no Root e rode `/construtor-equipe-iniciar` de novo.

Se o contexto do gerente ficar pesado no meio de um ciclo, feche e abra outro: ele continua pelo quadro.

## Trazer um projeto que já existe

Serve para projeto sem kit, sem documentação ou sem git.

1. Faça uma cópia nova do kit.
2. Copie a pasta inteira do projeto, com o `.git`, para `conversor/`. O original fica intacto. Um projeto por vez, numa pasta própria.
3. Abra uma sessão no Root e rode `/construtor-equipe-iniciar`. O gerente vê o material e pergunta se pode trazer.

A conversão para se houver código sem commit ou sem push, renomeia as instruções antigas para não serem carregadas, traz o código com o histórico, guarda os documentos e o que é antigo em `privado/origem/` (em `projeto/` só fica código), monta os documentos e o quadro a partir do que o código faz e passa as regras antigas pela sua aprovação. Chaves não vêm: você copia para `privado/parametros/`. Nada é alterado no servidor nem no banco.

Limites: um repositório por conversão; submódulos não são copiados.

## Atualizar o kit num projeto

Troque `CLAUDE.md` e as pastas `.claude/skills/`, `.claude/hooks/`, `.claude/git-hooks/`, `.claude/bin/` e `.claude/modelos/` pelas da versão nova. Mantenha `.claude/comandos.conf`, `.claude/rules/` e `.claude/settings.json`, que são do projeto; confira à mão se a versão nova mudou algo nesses três.

## Personalização

- **`.claude/comandos.conf`**: a branch principal, os comandos de build, testes, formatação e execução, e o modelo das sessões de etapa.
- **`.claude/rules/`**: os dados do projeto (`projeto.md`, criado pelo `/construtor-equipe-iniciar`), as convenções de código e o padrão de parâmetros.
- **`.claude/modelos/`**: os modelos dos documentos e de convenções por tecnologia.
- **`.claude/hooks/padroes-segredos.txt`**: as expressões regulares de segredo.

## Testes do kit

```bash
bash .claude/bin/testar-hooks.sh
```

```bash
bash .claude/bin/testar-converter.sh
```
