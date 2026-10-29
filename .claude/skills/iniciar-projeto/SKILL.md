---
name: iniciar-projeto
description: Conduz o início de um projeto em fases (estrutura fixa Projeto/ e Projeto_Documento/, mapeamento do código existente, objetivo, perguntas de esclarecimento, referências, ambiente e tecnologias, roadmap) e registra tudo em Projeto_Documento/. Não escreve código.
disable-model-invocation: true
---

# Iniciar projeto

Esta sessão é o **gerente** do projeto (veja "Papéis" no `CLAUDE.md`). Você vai conduzir o usuário pelas fases abaixo, **uma de cada vez**. Regras que valem do começo ao fim:

- **Pesquisa pesada vai para subagentes** (comparar tecnologias, bancos, bibliotecas, serviços; ler código existente grande). O subagente pesquisa e devolve 2 ou 3 opções com prós, contras, custo e uma recomendação, em no máximo uma página. **Ele não decide**: a decisão é do usuário, com você. Pesquisas independentes podem rodar em paralelo.

- **Não escreva código de produto, não crie a estrutura do projeto e não rode geradores** (como `dotnet new` ou `npm init`) durante este fluxo. Isso é trabalho da primeira etapa do roadmap.
- **Toda a documentação vai para `Projeto_Documento/`. Nada deste fluxo é gravado em `Projeto/`**, exceto `.gitignore`, `.gitattributes` e configuração do git.
- **Nunca avance de fase sem um "ok" explícito do usuário.** Ao fim de cada fase, mostre o que vai ser gravado e pergunte se pode seguir.
- Enquanto uma fase está em andamento, o documento dela fica com `Status: rascunho`. Só grave `Status: aprovado (AAAA-MM-DD)` quando a fase inteira terminar com o ok. É assim que a retomada sabe onde parou.
- **Não invente respostas.** O que o usuário não souber ou não quiser decidir agora entra como "Em aberto", com o motivo.
- Se uma resposta contradizer algo já aprovado, aponte a contradição e pergunte qual vale. Atualize o documento afetado só depois da resposta.
- Faça no máximo 4 perguntas por rodada, numeradas, priorizando as que mudam o desenho do sistema. Quando as alternativas forem poucas e claras, use a ferramenta de perguntas de múltipla escolha (AskUserQuestion); quando não forem, pergunte em texto.
- Requisito com adjetivo ("rápido", "seguro", "escalável") precisa de número e unidade; sem isso, vira pergunta.
- Testes automatizados ficam com o usuário: não entram como entregável nem como critério que depende do Claude escrevê-los.
- Escreva os documentos em português, curtos e objetivos. Use os modelos de `.claude/modelos/documentos.md`.

## Antes de começar

1. **Estrutura fixa.** O Root da sessão segue exatamente a estrutura da seção "Estrutura de pastas" do `CLAUDE.md`: `Root/Projeto/` (onde o projeto é construído) e `Root/Projeto_Documento/` (onde fica a documentação), além do kit. Ela não é alterável e não se discute neste fluxo. Crie o que faltar (`Projeto/`, `Projeto_Documento/etapas/`, `Projeto_Documento/decisoes/`, `Projeto_Documento/sensivel/`). Se houver algo solto no Root, mostre o que é e para onde vai (código para `Projeto/`, documentação para `Projeto_Documento/`) e só mova com o ok. Se a sessão foi aberta dentro de `Projeto/`, pare e peça ao usuário que abra no Root.
2. **Git.** Se o Root ou `Projeto_Documento/` estiver dentro de um repositório git, pare e avise: a documentação acabaria versionada. Se `Projeto/` não for repositório, pergunte se pode rodar `git -C Projeto init`. Depois, com o ok, ligue a trava de commit: `git -C Projeto config core.hooksPath ../.claude/git-hooks` (ela recusa commit com documentação, arquivo sensível ou segredo).
3. **Retomada.** Veja o que já existe em `Projeto_Documento/`, retome da primeira fase não concluída e diga ao usuário de onde está retomando:
   - `Projeto_Documento/objetivo.md` ausente ou `rascunho` → Fase 1;
   - `Projeto_Documento/objetivo.md` com `requisitos pendentes` → Fase 2;
   - `Projeto_Documento/referencias.md` ausente ou sem status final (`aprovado` ou `sem referências`) → Fase 2.5;
   - `Projeto_Documento/arquitetura.md` ausente ou `rascunho` → Fase 3;
   - `Projeto_Documento/roadmap.md` ausente ou `rascunho` → Fase 4;
   - os três aprovados, mas a seção "Projeto" do `CLAUDE.md` ainda com o texto padrão ou sem `Projeto_Documento/estado.md` → Fase 5;
   - tudo pronto → o projeto já foi iniciado: indique `/iniciar-etapa` ou `/progresso` conforme `estado.md`.
4. Se é o começo (nada em `Projeto_Documento/`) e já existe código, faça a Fase 0 antes da Fase 1. Código fora de `Projeto/` (por exemplo, um repositório solto no Root) precisa ir para `Projeto/` antes: mostre o que mover e só mova com o ok.

## Fase 0 — Mapeamento (só em projeto que já tem código)

1. Leia `Projeto/` sem alterar nada e monte um mapa a partir do que o código faz, não dos nomes de arquivo:
   1. o que o sistema faz hoje, em 1 ou 2 frases;
   2. pontos de entrada e interfaces públicas, com o caminho do arquivo;
   3. dados: bancos, tabelas, arquivos que lê e grava;
   4. integrações externas;
   5. como compila e roda (comandos que funcionam hoje);
   6. riscos: acoplamento forte, falha silenciosa, partes sem dono claro;
   7. bons exemplos no próprio código, que valem como padrão a seguir.
2. **Separação.** Liste o que em `Projeto/` é documentação (`.md` além do `README.md` da raiz, pasta `docs/`) ou sensível (`.env` com valores, chaves, certificados, senha em arquivo de configuração). Proponha mover a documentação para `Projeto_Documento/` e o sensível para `Projeto_Documento/sensivel/`, tirando do git com `git -C Projeto rm --cached`. Avise que o que já foi enviado ao GitHub continua no histórico: segredo que já subiu precisa ser trocado. Só mova com o ok.
3. Mostre o mapa e as perguntas que o código não responde. Ele é a base das fases seguintes: o objetivo descreve o sistema atual e o que se quer mudar, a arquitetura descreve o que existe e o roadmap só traz trabalho novo. Os comandos que já funcionam vão para `.claude/comandos.conf` (mostre e grave com o ok).

## Fase 1 — Objetivo

1. Peça ao usuário que descreva o projeto com as palavras dele: o que faz, para quem e por quê.
2. Reescreva no modelo de `Projeto_Documento/objetivo.md`: objetivo em um parágrafo, o que o projeto faz, **o que ele não faz**, critério de sucesso.
3. Mostre o rascunho e ajuste até o usuário aprovar. Grave `Projeto_Documento/objetivo.md` com `Status: requisitos pendentes`.

## Fase 2 — Perguntas de esclarecimento

1. Liste para você mesmo as ambiguidades do objetivo, usando este roteiro: escopo (o que entra e o que fica de fora); dados (entidades, relações, ciclo de vida, o que torna um registro único); requisitos não funcionais com número e unidade (volume, frequência, tempo de resposta, custo, segurança); termos do domínio (o nome oficial de cada coisa); casos de erro e o que acontece quando algo externo falha; como saber que está pronto.
2. Pergunte em rodadas. Depois de cada rodada, diga quantas dúvidas ainda restam.
3. Quando não houver mais ambiguidade relevante, mostre a seção "Requisitos" consolidada. Com o ok, acrescente-a em `Projeto_Documento/objetivo.md` e mude o status para `aprovado (AAAA-MM-DD)`.

## Fase 2.5 — Referências

1. Pergunte se existe material de referência (um projeto seu anterior, uma pasta, um repositório, um link).
2. Se não existir, crie `Projeto_Documento/referencias.md` só com `Status: sem referências (AAAA-MM-DD)` e siga para a Fase 3.
3. Se existir, siga o fluxo de `.claude/skills/buscar-referencia/SKILL.md`. Ao final, grave `Status: aprovado (AAAA-MM-DD)` em `Projeto_Documento/referencias.md`.

## Fase 3 — Ambiente, tecnologias e estrutura

Leia antes `Projeto_Documento/referencias.md`. Nas escolhas em que uma referência tem algo a dizer, cite o que ela fez, o que vale reaproveitar e o que vale evitar, ao lado das outras opções. Referência não é decisão: ela entra na comparação como mais uma opção.

Cubra, em rodadas: onde o sistema roda e como fica no ar (serviço, container, agendamento, reinício após falha); stack e versões; persistência; integrações externas e como lidar com indisponibilidade delas; configuração e segredos (no padrão `segredo.json` de `.claude/rules/segredos.md`: liste cada chave de API e senha de banco com o caminho dela no JSON); logs e monitoramento; como o usuário imagina a estrutura de funcionamento.

Para cada escolha relevante, apresente 2 ou 3 opções com prós e contras e diga qual recomenda e por quê. A decisão é do usuário.

1. Grave `Projeto_Documento/arquitetura.md` no modelo, como `rascunho` até o fim da fase.
2. Cada escolha relevante vira um arquivo em `Projeto_Documento/decisoes/NNN-titulo-curto.md` (modelo de decisão).
3. Convenções de código: crie `.claude/rules/<stack>.md`, com `paths:` apontando para as extensões da stack dentro de `Projeto/`. Se houver modelo em `.claude/modelos/convencoes/` (ex.: `dotnet.md`, `banco-relacional.md`), parta dele e tire o que não se aplica; senão, escreva com o usuário. Acrescente as convenções que decorrem das decisões (ex.: como acessar o banco, como chamar APIs externas).
4. Proponha os ajustes de ambiente da stack: padrões em `Projeto/.gitignore` (ex.: `bin/` e `obj/` em .NET), sem remover os de documentação e segredos que já estão lá; permissões em `.claude/settings.json` para os comandos de build e formatação; e confirmação (`ask`) para clientes de banco de dados.
5. Mostre tudo, grave após o ok e mude `Projeto_Documento/arquitetura.md` para `aprovado (AAAA-MM-DD)`.

## Fase 4 — Roadmap

1. Proponha etapas pequenas, cada uma executável numa sessão de etapa sem precisar compactar o contexto, e com entrega verificável. A primeira costuma ser o esqueleto do projeto em `Projeto/` rodando, com o build funcionando e `.claude/comandos.conf` preenchido.
2. Para cada etapa: objetivo, entregáveis, critérios de aceite **verificáveis** (um comando, um comportamento observável, uma chamada real) e o que fica fora dela.
3. Ajuste até o usuário aprovar. Grave `Projeto_Documento/roadmap.md` com `Status: aprovado (AAAA-MM-DD)` e todas as etapas como `pendente`.

## Fase 5 — Fechamento

1. Substitua a seção "Projeto" do `CLAUDE.md` pelo bloco "Seção Projeto do CLAUDE.md" de `.claude/modelos/documentos.md`, preenchido. Ele importa o estado, o objetivo e a arquitetura para que sejam carregados em toda sessão (gerente e etapas); o roadmap fica fora, lido pelas skills. Mantenha as demais seções do `CLAUDE.md`.
2. Crie `Projeto_Documento/estado.md` (próximo passo: etapa 1) e `Projeto_Documento/metricas.md` vazio, nos modelos.
3. Mostre o `CLAUDE.md` final ao usuário.
4. Encerre dizendo que o próximo passo é `/iniciar-etapa`, que abre a etapa 1 numa sessão vinculada. Não comece a etapa 1.
