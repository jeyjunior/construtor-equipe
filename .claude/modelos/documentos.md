# Modelos de documentos

Todos estes documentos ficam em `Projeto_Documento/`, nunca em `Projeto/`. Mantenha cada um curto: estado, objetivo e arquitetura são carregados em toda sessão e o espaço custa.

## Seção Projeto do CLAUDE.md

Entra no lugar da linha `(Esta seção é preenchida no final do /iniciar-projeto.)`, logo abaixo do título `# Projeto`. As subseções que vêm depois ("Como trabalhamos", "Como escrever código", "Comandos") ficam como estão.

```markdown
**Nome:** <nome>
**Resumo:** <uma linha>
**Stack:** <ex.: .NET 10 Worker Service, PostgreSQL, Dapper>
**Repositório:** <URL do GitHub de Projeto/, ou "ainda não publicado">

Estado atual: @Projeto_Documento/estado.md
Objetivo e escopo: @Projeto_Documento/objetivo.md
Arquitetura: @Projeto_Documento/arquitetura.md
Roadmap e etapas: `Projeto_Documento/roadmap.md` e `Projeto_Documento/etapas/` (lidos pelas skills, não carregados em toda sessão)
```

## Projeto_Documento/estado.md

Painel do projeto. Só o gerente grava. Máximo de meia página: é por ele que um gerente novo continua o trabalho.

```markdown
# Estado

Atualizado: AAAA-MM-DD · Status: em andamento | projeto encerrado (AAAA-MM-DD)

## Agora
- Etapa atual: N — <nome> (o status fica na tabela do roadmap)
- Sessão da etapa: etapa-NN (ou "nenhuma aberta")
- Próximo passo: <ex.: /progresso da etapa N | /iniciar-etapa N+1>

## Decisões pendentes
- <decisão> — <opções> — bloqueia a etapa N

## Decisões tomadas (índice)
- 001 — <título em uma linha>

## Pontos de atenção
- <risco ou combinado com o usuário que ainda não virou decisão>
```

## Projeto_Documento/metricas.md

Uma linha por etapa, atualizada a cada `/progresso` dela. Só o gerente grava.

```markdown
# Métricas

| Etapa | Início | Revisada | Rodadas de correção | Bloqueios por decisão | Compactou (etapa/gerente) | Custo (informado pelo usuário) | Bugs que vieram depois |
|-------|--------|----------|---------------------|-----------------------|---------------------------|--------------------------------|------------------------|
| 1 | AAAA-MM-DD | AAAA-MM-DD | 0 | 0 | não/não | <do painel de uso, ou —> | — |

## Resumo final
<preenchido no /encerrar-projeto: totais, médias e observações>
```

## Projeto_Documento/referencias.md

Gravado pelo `/buscar-referencia` (na Fase 2.5 do `/iniciar-projeto` ou depois). Uma seção por referência. Nunca contém segredos.

```markdown
# Referências

Status: sem referências (AAAA-MM-DD) | aprovado (AAAA-MM-DD)

## R1 — <nome da referência>
- Onde: <caminho ou link>
- Contexto do usuário: <por que serve de referência>
- Analisada em: AAAA-MM-DD

### Respostas
- <pergunta>: <resposta> — `<arquivo que comprova>`

### Reaproveitar
- <o quê> — <por quê>

### Evitar
- <o quê> — <por quê, com a fonte: padroes-observados, decisão ou código>

### Onde pesa no projeto novo
- <decisão ou etapa em que esta referência entra>
```

## Projeto_Documento/padroes-observados.md

Gerado no `/encerrar-projeto`. Formato fixo em todo projeto, para comparar entre projetos.

```markdown
# Padrões observados — <nome do projeto>

Data: AAAA-MM-DD · Stack: <stack> · Etapas: N · Duração: <início> a <fim>

## Padrões
### P1 — <nome curto>
- Tipo: problema recorrente | decisão recorrente | estrutura de código | pergunta recorrente | passo manual | correção recorrente
- Onde apareceu: <etapas, decisões, arquivos>
- Frequência: <quantas vezes>
- O que aconteceu: <2 ou 3 frases>
- Candidato a: skill | regra | modelo | hook | convenção | nada — <por quê>

## O que funcionou bem
- ...

## O que atrapalhou
- ...
```

## Projeto_Documento/objetivo.md

```markdown
# Objetivo

Status: rascunho | requisitos pendentes | aprovado (AAAA-MM-DD)

## Objetivo
<um parágrafo: o que o sistema faz, para quem e por quê>

## O que o projeto faz
- ...

## O que o projeto NÃO faz
- ...

## Critério de sucesso
- <como saber que o projeto cumpre o objetivo>

## Requisitos
- R1. ...
- R2. <não funcional sempre com número e unidade, ex.: "processa 1.000 itens em menos de 1 min">

## Em aberto
- <dúvida> — <por que ficou em aberto>
```

## Projeto_Documento/arquitetura.md

```markdown
# Arquitetura

Status: rascunho | aprovado (AAAA-MM-DD)

## Visão geral
<2 a 4 frases: como o sistema funciona de ponta a ponta>

## Execução e disponibilidade
- Onde roda:
- Como fica no ar e se recupera de falhas:
- Ciclo de trabalho / agendamento:

## Stack
| Item | Escolha | Decisão |
|------|---------|---------|
| Runtime | ... | 001 |

## Componentes
- <Nome>: <responsabilidade> — <pasta em Projeto/>

## Dados
- Banco:
- Tabelas principais: <nome — o que guarda>

## Integrações externas
| Serviço | Para quê | Se estiver fora do ar |
|---------|----------|------------------------|

## Configuração e segredos
Padrão `segredo.json` (`.claude/rules/segredos.md`).

| Segredo | Caminho no segredo.json | Para quê |
|---------|-------------------------|----------|
| <ex.: chave da API de pagamento> | `GatewayPagamento.ApiKey` | <uso> |

## Logs e monitoramento
- ...

## Em aberto
- ...
```

## Projeto_Documento/roadmap.md

```markdown
# Roadmap

Status: rascunho | aprovado (AAAA-MM-DD)

| # | Etapa | Status |
|---|-------|--------|
| 1 | <nome> | pendente |

Esta tabela é o único lugar do status de cada etapa.
Status possíveis: pendente → planejada → em andamento → concluída → revisada.
A sessão da etapa também pode fechar como `bloqueada` ou `decisão pendente`; depois do `/progresso`, a etapa volta a `planejada`.

## Etapa 1 — <nome>
**Objetivo:** ...

**Entregáveis:**
- ...

**Critérios de aceite:**
- [ ] build sem erros (`BUILD` de `.claude/comandos.conf`)
- [ ] <comando, comportamento observável ou chamada real>

**Fora desta etapa:** ...

## Fora do escopo e ideias
- <ideia> — <origem e data> — avaliar | virou etapa N | descartada
```

## Projeto_Documento/etapas/NN-nome.md

```markdown
# Etapa N — <nome>

O status desta etapa fica na tabela do roadmap.

## Respostas da sessão de perguntas
- P: ... — R: ...

## Padrões a seguir
- <arquivo existente em Projeto/ a imitar> — <por quê> (ou "nenhum: primeira etapa")

## Plano
- [ ] <passo> — arquivos: <caminhos em Projeto/>

## Verificação dos critérios de aceite
- [ ] <critério> — <evidência: comando executado e trecho da saída>

## Notas da execução
- <desvios, problemas encontrados e como foram resolvidos>

## Fechamento
<preenchido pela sessão da etapa ao fechar; substitui o anterior, se houver>
- Data: AAAA-MM-DD
- Se bloqueada: <o que falta e por quê>
- Se decisão pendente: <a decisão e as opções>
- Esta conversa foi compactada: sim | não

## Revisão
<preenchido pelo gerente no /progresso: veredito, conversa com o usuário, correções pendentes>
```

## Projeto_Documento/decisoes/NNN-titulo-curto.md

```markdown
# NNN — <título>

Data: AAAA-MM-DD · Status: aceita | substituída por NNN

## Contexto
<o problema, em 2 ou 3 frases>

## Decisão
<o que foi decidido>

## Alternativas consideradas
- <alternativa> — <por que não>

## Consequências
- ...
```
