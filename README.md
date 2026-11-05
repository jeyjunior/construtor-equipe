# Construtor Equipe

Kit para o [Claude Code](https://claude.com/claude-code) que conduz um projeto de software com **um gerente e uma sessão separada para cada etapa**.

Uma sessão gerente planeja o projeto com você, abre cada etapa numa sessão vinculada, confere a entrega e mantém o estado do projeto em arquivos. Cada etapa começa com contexto limpo, a partir dos documentos e não de uma conversa longa. Hooks e regras impedem que documentação ou segredos vazem para o repositório.

> Projeto pequeno, ou prefere tudo numa sessão só? Veja o **[Construtor Solo](https://github.com/jeyjunior/construtor-solo)**.

> **Experimental:** esta edição ainda não foi validada de ponta a ponta num projeto real. Feedback e issues são bem-vindos.

---

## Por que um gerente?

Numa sessão única, a conversa cresce a cada etapa, o contexto é compactado e detalhes se perdem. Aqui cada papel tem um limite claro:

| | Gerente | Sessão de etapa (`etapa-NN`) |
|---|---|---|
| Onde roda | a sessão principal, aberta por você no Root | uma sessão vinculada, aberta pelo gerente |
| Modelo | o que você escolher no app (use Opus) | Opus 5.5, esforço `medium`, contexto limpo |
| O que faz | planeja, abre etapas, confere, registra o estado | executa **uma** etapa: perguntas, plano, código, evidências |
| Escreve código | nunca | sim, só em `Projeto/` |
| Grava `estado.md` e `metricas.md` | sim, é o único | nunca |
| Memória | descartável: um gerente novo continua lendo `estado.md` | parte só dos documentos |

Leituras pesadas (diff, build, conferência, análise de referências) vão para subagentes, que devolvem só a conclusão. Assim o contexto do gerente fica leve. Os subagentes são do tipo `general-purpose` e só leem; a única exceção é o que escreve os testes, se você ligar essa opção. Como o kit não define modelo para eles, usam o padrão do app (em geral, o mesmo da sessão que os chamou).

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
    ├── roadmap.md          as etapas e o status de cada uma (o único lugar do status)
    ├── metricas.md         uma linha por etapa: correções, bloqueios, compactações, custo
    ├── padroes-observados.md   gerado no fim do projeto
    ├── etapas/             um arquivo por etapa (plano, execução, fechamento, revisão)
    ├── decisoes/           uma decisão técnica por arquivo
    └── sensivel/           segredo.json, chaves e certificados (o Claude não lê nem grava)
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
   - **Roadmap:** etapas pequenas, cada uma cabendo numa sessão, com critérios de aceite verificáveis.
2. **`/iniciar-etapa`**: confere se a próxima etapa pode começar e abre a sessão vinculada `etapa-NN`, com contexto limpo e na mesma pasta, para carregar o kit.
3. **`/progresso`** (depois de cada etapa): um subagente confere a entrega e o gerente revisa com você. O resultado é um destes:
   - **Aprovada:** a etapa fica marcada como revisada.
   - **Correção:** os itens voltam para a sessão da etapa.
   - **Bloqueada ou decisão pendente:** o que falta é resolvido com você e a etapa volta para a sessão dela, com o plano ajustado.
   - **Problema maior:** vira uma etapa nova.

   No fim, `metricas.md` e `estado.md` são atualizados.
4. **`/encerrar-projeto`** (no fim): fecha as métricas e grava `padroes-observados.md`, com o que funcionou, o que travou e o que repetir ou evitar no próximo projeto.

**Na sessão de cada etapa:**

- **`/etapa`**: apresenta a etapa, faz as perguntas e mostra o plano. Executa depois do seu ok, cria os testes (se o projeto tiver) e fecha marcando o status no roadmap, com a evidência de cada critério de aceite.
- **`depurar`** (automática): em caso de bug ou erro, o Claude é obrigado a achar a causa antes de mexer no código.

```
você ──► gerente: /iniciar-projeto ──► /iniciar-etapa ──► etapa-01: /etapa ──┐
               ▲                                                             │
               └──────────── /progresso ◄──── fechamento ◄───────────────────┘
                     (aprova → /iniciar-etapa da próxima │ correção → volta para etapa-01)
```

### Segredos: padrão `segredo.json`

Todas as chaves de API e senhas de banco ficam num único `Projeto_Documento/sensivel/segredo.json`, agrupadas por serviço. O sistema encontra esse arquivo pela variável de ambiente `SEGREDO_JSON`. Em `Projeto/` vai só o `segredo.exemplo.json`, com valores vazios. Os detalhes estão em `.claude/rules/segredos.md`.

### Travas

| Trava | O que faz |
|---|---|
| `hooks/proteger-estrutura.sh` | Nega ao Claude criar documentação ou arquivo sensível em `Projeto/` e criar qualquer coisa solta no Root. |
| `git-hooks/pre-commit` | Recusa o commit (de qualquer pessoa) que tenha documentação, arquivo sensível ou segredo. |
| `hooks/bloquear-segredos.sh` | Nega edições que escrevem chaves, tokens ou senhas literais no código. |
| `hooks/bloquear-comandos.sh` | Bloqueia comandos destrutivos. |
| `hooks/verificar-ambiente.sh` | Ao abrir a sessão, avisa se a estrutura está fora do padrão ou se falta alguma ferramenta. |
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

**Tem um projeto existente?** Coloque o código (incluindo o `.git` dele) dentro de `Projeto/`. O `/iniciar-projeto` faz o mapeamento e propõe mover para `Projeto_Documento/` o que for documentação ou sensível.

## Uso

1. No app Claude desktop, abra uma sessão Code na pasta `meu-projeto/` (o Root). Essa é o gerente. Use o modelo Opus: o app só deixa a sessão de etapa usar um modelo igual ou mais barato que o do gerente.
2. Rode `/iniciar-projeto` e responda às fases. Ele pergunta se pode criar o git em `Projeto/` e ligar a trava de commit:
   ```bash
   git -C Projeto config core.hooksPath ../.claude/git-hooks
   ```
3. Rode `/iniciar-etapa`. Ele abre a sessão `etapa-01`, onde você responde às perguntas, aprova o plano e acompanha a execução.
4. Quando a etapa terminar, volte ao gerente e rode `/progresso`.
5. Repita os passos 3 e 4 até o fim do roadmap e rode `/encerrar-projeto`.
6. Quando a etapa 1 criar o esqueleto do projeto, preencha `.claude/comandos.conf` (build, testes, formatação, execução) para ligar o build e a formatação automáticos.

Se o contexto do gerente ficar pesado, feche e abra outro: ele continua lendo `Projeto_Documento/estado.md`.

## Personalização

- **`.claude/comandos.conf`**: os comandos de build, testes, formatação e execução da sua stack. Os exemplos são de .NET.
- **`.claude/modelos/convencoes/`**: modelos de convenção de código (`dotnet.md`, `banco-relacional.md`). No `/iniciar-projeto`, o Claude parte deles para criar `.claude/rules/<stack>.md`.
- **`.claude/modelos/documentos.md`**: os modelos de estado, objetivo, arquitetura, roadmap, etapa, decisão e métricas.
- **`.claude/hooks/padroes-segredos.txt`**: as expressões regulares de segredo usadas pelo hook e pelo pre-commit.
- **Modelo das sessões de etapa**: definido em `.claude/skills/iniciar-etapa/SKILL.md`.

## Regras que o Claude segue

- Não implementa nada fora da etapa em andamento. Uma ideia nova vai para "Fora do escopo e ideias" do roadmap.
- Não diz que algo está pronto sem rodar o comando que prova e citar a evidência.
- Testes automatizados seguem a sua escolha no `/iniciar-projeto`: com "não", o Claude não os cria.
- Não faz commit nem push sem você pedir.
- Entre duas interpretações, pergunta.
