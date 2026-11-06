# Construtor Equipe

Kit para o [Claude Code](https://claude.com/claude-code) que conduz um projeto de software com **um gerente e uma sessão separada para cada etapa**.

Uma sessão gerente planeja o trabalho com você, abre cada etapa numa sessão vinculada, confere a entrega e mantém o estado do projeto em arquivos. Cada etapa começa com contexto limpo, a partir dos documentos e não de uma conversa longa. Hooks e regras impedem que documentação ou segredos vazem para o repositório.

O projeto avança por **ciclos** e nunca é encerrado. Cada novo recurso, melhoria ou correção é um ciclo, com objetivo, etapas e branch próprios, e só entra na `main` quando o ciclo fecha.

Já tem um projeto, com ou sem kit? Veja [Trazer um projeto que já existe](#trazer-um-projeto-que-já-existe).

> Projeto pequeno, ou prefere tudo numa sessão só? Veja o **[Construtor Solo](https://github.com/jeyjunior/construtor-solo)**.

> **Experimental:** esta edição ainda não foi validada de ponta a ponta num projeto real. Feedback e issues são bem-vindos.

---

## Por que um gerente?

Numa sessão única, a conversa cresce a cada etapa, o contexto é compactado e detalhes se perdem. Aqui cada papel tem um limite claro:

| | Gerente | Sessão de etapa (`ciclo-NN-etapa-EE`) |
|---|---|---|
| Onde roda | a sessão principal, aberta por você no Root | uma sessão vinculada, aberta pelo gerente |
| Modelo | o que você escolher no app (use Opus) | Opus 5.5, esforço `medium`, contexto limpo |
| O que faz | planeja, abre etapas, confere, faz os merges, registra o estado | executa **uma** etapa: perguntas, plano, código, evidências, commit |
| Escreve código | nunca | sim, só em `Projeto/` |
| Grava `estado.md`, `ciclo.md` e `metricas.md` | sim, é o único | nunca |
| Memória | descartável: um gerente novo continua lendo `estado.md`, e cada ciclo começa com um gerente novo | parte só dos documentos |

Leituras pesadas (diff, build, conferência, análise de referências) vão para subagentes, que devolvem só a conclusão. Assim o contexto do gerente fica leve. Os subagentes são do tipo `general-purpose` e só leem; as exceções são o que escreve os testes, se você ligar essa opção, e os que gravam análises e rascunhos em `Projeto_Documento/` no `/converter`. Como o kit não define modelo para eles, usam o padrão do app (em geral, o mesmo da sessão que os chamou).

## Como funciona

### Estrutura fixa

```
meu-projeto/                ← o "Root": abra o Claude Code sempre aqui
├── CLAUDE.md               regras do kit e papéis (carregadas em toda sessão)
├── .claude/                skills, hooks, permissões e modelos do kit
├── Projeto/                o código. É o ÚNICO repositório git e o que vai para o GitHub
└── Projeto_Documento/      a documentação. Nunca entra em git nem vai para lugar nenhum
    ├── estado.md           onde o projeto está e qual é o próximo passo
    ├── objetivo.md, referencias.md, arquitetura.md
    ├── ideias.md           o que pode virar ciclo
    ├── decisoes/           uma decisão técnica por arquivo, com numeração única no projeto
    ├── ciclos/
    │   └── 02-nome/
    │       ├── ciclo.md    objetivo, critério de pronto, mudanças nos documentos, branch e commits
    │       ├── roadmap.md  as etapas e correções, com o status de cada uma (o único lugar do status)
    │       ├── metricas.md uma linha por etapa: correções, bloqueios, compactações, custo
    │       ├── padroes-observados.md   gerado no fim do ciclo
    │       ├── etapas/     um arquivo por etapa (plano, execução, fechamento, revisão)
    │       └── correcoes/  um arquivo por bug antigo corrigido a partir da main
    ├── origem/             só depois de uma conversão: documentos e regras antigas, sem alteração
    └── sensivel/           segredo.json, chaves e certificados (o Claude não lê nem grava)
conversor/                  entrada do /converter. Nunca vai para o GitHub.
```

A ideia é separar o que é **produto** (`Projeto/`, público) do que é **processo** (`Projeto_Documento/`, privado). Os documentos são a fonte da verdade entre as sessões: o que não está escrito lá não existe para a próxima sessão.

### O fluxo

**No gerente:**

1. **`/iniciar-projeto`** (uma vez), sem escrever código:
   - **Mapeamento:** só se já existir código em `Projeto/`.
   - **Objetivo:** o que o sistema precisa fazer e para quem.
   - **Perguntas:** tudo o que ficou ambíguo é perguntado, e nada é suposto.
   - **Referências:** opcionais. Outros projetos, pastas ou links analisados com `/buscar-referencia`.
   - **Ambiente e tecnologias:** 2 ou 3 opções com prós e contras por escolha. A decisão é sua.
   - **Testes automatizados:** você escolhe se o projeto terá testes. Se sim, eles são criados a cada etapa, por um subagente (padrão) ou pela própria sessão da etapa.
   - **Roadmap do ciclo 1:** etapas pequenas, cada uma cabendo numa sessão, com critérios de aceite verificáveis.
2. **`/iniciar-etapa`**: confere se a próxima etapa pode começar e abre a sessão vinculada `ciclo-NN-etapa-EE`, com contexto limpo e na mesma pasta, para carregar o kit.
3. **`/progresso`** (depois de cada etapa): um subagente confere a entrega e o gerente revisa com você. O resultado é um destes:
   - **Aprovada:** a etapa entra na branch do ciclo, e essa branch é enviada ao GitHub.
   - **Correção:** os itens voltam para a sessão da etapa.
   - **Bloqueada ou decisão pendente:** o que falta é resolvido com você e a etapa volta para a sessão dela, com o plano ajustado.
   - **Problema maior:** vira uma etapa nova.

   No fim, `metricas.md` e `estado.md` são atualizados.
4. **`/encerrar-ciclo`** (no fim do ciclo): confere o ciclo inteiro, grava `padroes-observados.md` e, com o seu ok, leva o ciclo para a `main`. O projeto fica sem ciclo aberto.
5. **`/novo-ciclo`** (quando houver trabalho novo, num gerente novo): compara documentos e código, define o objetivo, tira as dúvidas, vê o impacto nos documentos, cria as etapas e abre a branch do ciclo. Daí em diante, volta ao passo 2.
6. **`/cancelar-ciclo`** (a qualquer momento, esteja o ciclo funcionando ou não): nada entra na `main`, as branches ficam guardadas e você decide o que fazer com o que foi alterado fora do git.

Um ciclo só começa depois que o anterior fecha. Todo trabalho é um ciclo, simples ou complexo, com a estrutura inteira.

**Nas sessões vinculadas:**

- **`/etapa`**: apresenta a etapa, faz as perguntas e mostra o plano. Executa depois do seu ok, cria os testes (se o projeto tiver) e fecha com o commit e o status no roadmap do ciclo, com a evidência de cada critério de aceite.
- **`/correcao`**: corrige um bug antigo a partir da `main`, numa sessão aberta pelo `/progresso`.
- **`depurar`** (automática): em caso de bug ou erro, o Claude é obrigado a achar a causa antes de mexer no código.

```
você ──► gerente: /iniciar-projeto ou /novo-ciclo ──► /iniciar-etapa ──► ciclo-02-etapa-01: /etapa ──┐
               ▲                                                                                     │
               └──────────────────────── /progresso ◄──── fechamento ◄───────────────────────────────┘
                     (aprova → merge no ciclo e /iniciar-etapa da próxima │ correção → volta para a etapa)
                     (todas revisadas → /encerrar-ciclo → merge na main → gerente novo → /novo-ciclo)
```

### Branches

```
main ──────────────────────────────────────────────► merge no /encerrar-ciclo
  └─ ciclo-02 ──────┬───────────────────┬───────────┘
                    └ ciclo-02-etapa-01 └ ciclo-02-etapa-02
```

- A sessão da etapa faz o commit no fechamento, na branch dela.
- O gerente faz o merge na branch do ciclo e o push quando o `/progresso` aprova.
- A `main` só recebe o merge do ciclo, com o seu ok. A trava de commit recusa commit direto nela.

### Bugs encontrados durante um ciclo

| Situação | Onde corrige | Como chega à `main` |
|---|---|---|
| A causa está em código alterado neste ciclo | Na sessão atual, sem parar | No fim do ciclo |
| A causa é antiga, mas só atrapalha por causa do ciclo | Na branch da etapa atual, com o seu ok | No fim do ciclo |
| A causa é antiga e atrapalha mesmo sem o ciclo | Numa sessão de correção, a partir da `main`, com o seu ok | Logo depois da correção, e daí segue para a branch do ciclo |

O último caso é a única exceção à regra de a `main` só receber merge no fim do ciclo.

### Segredos: padrão `segredo.json`

Todas as chaves de API e senhas de banco ficam num único `Projeto_Documento/sensivel/segredo.json`, agrupadas por serviço. O sistema encontra esse arquivo pela variável de ambiente `SEGREDO_JSON`. Em `Projeto/` vai só o `segredo.exemplo.json`, com valores vazios. Os detalhes estão em `.claude/rules/segredos.md`.

### Travas

| Trava | O que faz |
|---|---|
| `hooks/proteger-estrutura.sh` | Nega ao Claude criar documentação ou arquivo sensível em `Projeto/` e criar qualquer coisa solta no Root. |
| `git-hooks/pre-commit` | Recusa o commit (de qualquer pessoa) que tenha documentação, arquivo sensível ou segredo, e o commit direto na branch principal. |
| `hooks/bloquear-segredos.sh` | Nega edições que escrevem chaves, tokens ou senhas literais no código. |
| `hooks/bloquear-comandos.sh` | Bloqueia comandos destrutivos. |
| `hooks/verificar-ambiente.sh` | Ao abrir a sessão, avisa se a estrutura está fora do padrão, se falta alguma ferramenta ou se há um projeto em `conversor/`. |
| `conversor/.gitignore` | Impede que o projeto colocado no conversor vá para o GitHub. |
| `hooks/formatar.sh` e `verificar-build.sh` | Formatam o arquivo depois de cada edição e compilam ao fim de cada resposta, se configurados. Só compila a sessão que editou código: o gerente nunca compila. |
| `settings.json` | Nega leitura de `sensivel/`, `.env` e `segredo.json` e pede confirmação para `git push`, `git init` e `reset --hard`. |
| `Projeto/.gitignore` | Ignora `.md` (menos o `README.md`), `docs/`, `.env` e chaves. |

---

## Requisitos

- **App Claude desktop, aba Code**: as etapas rodam em sessões vinculadas, que só existem no app.
- `git`
- `bash`: no Windows, o Git Bash que vem com o Git for Windows
- [`jq`](https://jqlang.org): sem ele, os bloqueios de comandos e de segredos ficam desligados (o kit avisa)

## Instalação

O kit é uma **pasta modelo**: você copia para um projeto novo e descarta o git do kit, porque o único repositório deve ser `Projeto/`.

```bash
git clone https://github.com/jeyjunior/construtor-equipe meu-projeto
```

```bash
cd meu-projeto && rm -rf .git README.md
```

Também dá para baixar o ZIP pelo GitHub (**Code → Download ZIP**) e apagar o `README.md`.

> Por que apagar o `.git` e o `README.md`? O kit trata o Root como área protegida: nada solto e nenhum git ali. Se ficarem, o `verificar-ambiente.sh` avisa ao abrir a sessão.

## Trazer um projeto que já existe

Serve para qualquer projeto com um único repositório, ou sem git: com uma versão antiga deste kit, sem kit ou sem documentação. Também é assim que você atualiza um projeto quando o kit evoluir: uma cópia nova do kit e a mesma conversão.

1. Faça uma cópia nova do kit.
2. Copie a pasta inteira do projeto, com o `.git`, para `conversor/`. O original fica intacto. Um projeto por vez, numa pasta própria.
3. Abra uma sessão no Root. O gerente vê o material e pergunta se pode analisar. Com o seu sim, roda o `/converter`:

| Passo | Quem faz | O que acontece |
|---|---|---|
| 1. Preparar | script | Para se houver código sem commit ou sem push. Renomeia as instruções antigas para não serem carregadas. |
| 2. Inventário | subagente | Mostra o que há e o que será copiado. Você escolhe a branch principal. |
| 3. Trazer e guardar | script | O código e o `.git` vão para `Projeto/`. Documentos e regras antigas vão para `Projeto_Documento/origem/`, sem alteração. Chaves não vêm. |
| 4. Entender | subagentes | Leem o código e os documentos que existirem. |
| 5. Documentação nova | subagente e você | Objetivo, arquitetura, comandos e pendências, com a sua aprovação. |
| 6. Regras novas | subagente e você | Nenhuma decisão antiga vale até você aprovar, uma por uma. |
| 7. Fora da pasta | subagente e você | Lista servidor, banco e variáveis. Você copia as chaves para `sensivel/`. |
| 8. Conferir | subagente novo | Confere commit, build e amostras dos documentos contra o código. |
| 9. Fechar | gerente | Com o seu ok, faz o merge do ciclo 1. O projeto fica sem ciclo aberto, pronto para o `/novo-ciclo`. |

Limites: um repositório por conversão; submódulos não são copiados; nada é alterado no servidor nem no banco. Depois, guarde a pasta original e não trabalhe mais nela, porque as duas apontam para o mesmo GitHub.

## Uso

Estes passos são para um projeto novo. Se você converteu um projeto, ele já está sem ciclo aberto: comece pelo passo 7.

1. No app Claude desktop, abra uma sessão Code na pasta `meu-projeto/` (o Root). Essa é o gerente. Use o modelo Opus: o app só deixa a sessão de etapa usar um modelo igual ou mais barato que o do gerente.
2. Rode `/iniciar-projeto` e responda às fases. Ele pergunta se pode criar o git em `Projeto/` e ligar a trava de commit:
   ```bash
   git -C Projeto config core.hooksPath ../.claude/git-hooks
   ```
3. Rode `/iniciar-etapa`. Ele abre a sessão `ciclo-01-etapa-01`, onde você responde às perguntas, aprova o plano e acompanha a execução.
4. Quando a etapa terminar, volte ao gerente e rode `/progresso`.
5. Repita os passos 3 e 4 até o fim do roadmap do ciclo e rode `/encerrar-ciclo`.
6. Quando a etapa 1 criar o esqueleto do projeto, preencha `.claude/comandos.conf` (build, testes, formatação, execução) para ligar o build e a formatação automáticos.
7. Para implementar algo novo, depois de qualquer tempo, abra uma sessão nova no Root, rode `/novo-ciclo` e volte ao passo 3.

Se o contexto do gerente ficar pesado no meio de um ciclo, feche e abra outro: ele continua lendo `Projeto_Documento/estado.md`.

## Personalização

- **`.claude/comandos.conf`**: a branch principal e os comandos de build, testes, formatação e execução da sua stack. Os exemplos são de .NET.
- **`.claude/modelos/convencoes/`**: modelos de convenção de código (`dotnet.md`, `banco-relacional.md`). No `/iniciar-projeto`, o Claude parte deles para criar `.claude/rules/<stack>.md`.
- **`.claude/modelos/documentos.md`**: os modelos de estado, objetivo, arquitetura, ideias, ciclo, roadmap, etapa, correção, decisão e métricas.
- **`.claude/hooks/padroes-segredos.txt`**: as expressões regulares de segredo usadas pelo hook e pelo pre-commit.
- **Modelo das sessões de etapa**: definido em `.claude/skills/iniciar-etapa/SKILL.md`.

## Regras que o Claude segue

- Não implementa nada fora da etapa em andamento. Uma ideia nova vai para `ideias.md`.
- Não diz que algo está pronto sem rodar o comando que prova e citar a evidência.
- Testes automatizados seguem a sua escolha no `/iniciar-projeto`: com "não", o Claude não os cria.
- Commit, merge e push só nos pontos fixos do fluxo. O merge na `main` sempre pede o seu ok, e fora desses pontos não faz nada sem você pedir.
- Entre duas interpretações, pergunta.
