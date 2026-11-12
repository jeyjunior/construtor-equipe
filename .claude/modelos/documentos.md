# Modelos de documentos

O quadro e os documentos ficam em `privado/`, fora de qualquer git: não vão para o GitHub e não têm histórico. Mantenha cada um curto. Em `projeto/` só fica o `README.md`, que é público com o código: nele, nada de dado pessoal, de cliente ou interno de empresa.

## .claude/rules/projeto.md

Criado pelo `/construtor-equipe-iniciar` (ou pela conversão). É carregado em toda sessão. Fica no kit, não em `projeto/`.

```markdown
# Projeto

**Nome:** <nome>
**Resumo:** <uma linha>
**Stack:** <ex.: .NET 10 Worker Service, PostgreSQL> (ou "a decidir")
**Repositório:** <URL do GitHub de projeto/, ou "ainda não publicado">
**Testes:** <"a decidir", "não", ou "por etapa, <ferramenta>, escritos por subagente | pela sessão da etapa">

Quadro: `privado/QUADRO.md` · Objetivo: `privado/docs/objetivo.md` · Arquitetura: `privado/docs/arquitetura.md`
```

## privado/QUADRO.md

O estado do projeto. Só o gerente edita (e a sessão de ciclo curto, depois do merge na principal). Uma linha por item; o detalhe fica no arquivo apontado. O número `#NNN` é único no projeto e nunca é reutilizado.

```markdown
# Quadro

## Situação
- Ciclo: N — <objetivo em uma linha> — `privado/docs/ciclos/NN-nome/` (ou "nenhum aberto")
- Sessão aberta: ciclo-NN-etapa-EE | curto-NNN | nenhuma
- Próximo passo: <ex.: /construtor-equipe-progresso da etapa 2 | /construtor-equipe-iniciar-etapa | /construtor-equipe-encerrar-ciclo | /construtor-equipe-iniciar num gerente novo>
- Decisões pendentes: <decisão — bloqueia a etapa E> (ou "nenhuma")

## Backlog
- #012 <ideia, pedido ou bug> — <origem, AAAA-MM-DD>

## A fazer
- #007 [código] Ciclo 2, etapa 3 — <nome>

## Fazendo
- #006 [ambiente] Ciclo 2, etapa 2 — <nome> — sessão ciclo-02-etapa-02 — desde AAAA-MM-DD

## Feito
- #005 [pesquisa] Ciclo 2, etapa 1 — <nome> — AAAA-MM-DD — `privado/docs/ciclos/02-nome/etapas/01-nome.md`
- #004 [curto] <o que foi feito e por quê, em uma linha> — AAAA-MM-DD — commit <hash curto>

## Homologado
### v0.1.0 — AAAA-MM-DD
- #001 [código] Ciclo 1, etapa 1 — <nome> — `privado/docs/ciclos/01-nome/etapas/01-nome.md`
```

Regras do quadro:
- **Backlog:** o que pode virar trabalho. **A fazer:** as etapas do ciclo aberto que ainda não começaram. **Fazendo:** a etapa com sessão aberta. **Feito:** aprovado pelo usuário e já na branch do ciclo ou na principal. **Homologado:** publicado ou validado pelo usuário, agrupado por versão.
- "Homologado" guarda as 3 versões mais recentes; as anteriores vão para `privado/docs/historico.md`, no mesmo formato.
- O andamento fino de uma etapa (planejada, em andamento, concluída, bloqueada, decisão pendente) fica no arquivo dela, não no quadro.

## privado/docs/objetivo.md

```markdown
# Objetivo

Status: rascunho | aprovado (AAAA-MM-DD)

## Objetivo
<um parágrafo: o que o sistema faz, para quem e por quê>

## O que o projeto faz
- ...

## O que o projeto NÃO faz
- ...

## Limites
- Custo: <ex.: "só serviços gratuitos", "até R$ 50 por mês">
- O que já existe: <contas, máquinas, serviços que o usuário já tem>

## Critério de sucesso
- <como saber que o projeto cumpre o objetivo>

## Requisitos
- R1. <não funcional sempre com número e unidade>

## Em aberto
- <dúvida> — <por que ficou em aberto e em que etapa será resolvida>
```

## privado/docs/arquitetura.md

Cresce aos poucos: cada seção é preenchida quando a decisão é tomada. Seção sem decisão fica `a decidir (etapa E)`.

```markdown
# Arquitetura

Atualizado: AAAA-MM-DD

## Visão geral
<2 a 4 frases: como o sistema funciona de ponta a ponta>

## Execução e disponibilidade
- Onde roda:
- Como fica no ar e se recupera de falhas:

## Stack
| Item | Escolha | Decisão |
|------|---------|---------|
| Runtime | ... | 001 |

## Componentes
- <Nome>: <responsabilidade> — <pasta em projeto/>

## Dados
- ...

## Integrações externas
| Serviço | Para quê | Custo e limites | Se estiver fora do ar |
|---------|----------|-----------------|------------------------|

## Configuração e segredos
Padrão `parametro.json` (`.claude/rules/parametros.md`).

| Segredo | Caminho no parametro.json | Para quê |
|---------|---------------------------|----------|

## Logs e monitoramento
- ...
```

## privado/docs/pesquisas/NNN-tema.md

Gravado pelo `/construtor-equipe-pesquisar` ou por uma etapa de `pesquisa`. Numeração única no projeto. Nunca contém segredos.

```markdown
# NNN — <tema>

Data: AAAA-MM-DD · Pedida por: briefing do ciclo N | etapa E do ciclo N

## Perguntas
1. <o que precisava ser respondido>

## Respostas
- P1: <resposta> — fonte: <link ou arquivo> — consultada em AAAA-MM-DD

## Opções
| Opção | Custo | Limites | Prós | Contras |
|-------|-------|---------|------|---------|

## Recomendação
<qual e por quê. Quem decide é o usuário.>

## O que a pesquisa não confirma
- <o que só um teste real mostra> — candidato a etapa de `prova`

## Referência analisada (se for outro projeto)
- Reaproveitar: <o quê> — <por quê>
- Evitar: <o quê> — <por quê>
```

## privado/docs/subagentes.md

Uma linha por disparo de subagente, acrescentada por quem disparou (regra em `.claude/skills/construtor-equipe-subagente/SKILL.md`). A sessão de consulta não registra. Revisado no `/construtor-equipe-encerrar-ciclo`.

```markdown
# Subagentes

| Data | Sessão | Tarefa | Nota | Conta | Modelo · esforço | Resultado |
|------|--------|--------|------|-------|------------------|-----------|
| AAAA-MM-DD | ciclo-NN-etapa-EE | <tarefa em poucas palavras> | N | principal \| secundária | sonnet · medium | aproveitado \| subiu de nível \| descartado \| abortado |
```

## privado/docs/decisoes/NNN-titulo-curto.md

Numeração única no projeto.

```markdown
# NNN — <título>

Data: AAAA-MM-DD · Ciclo: N · Status: aceita | substituída por NNN

## Contexto
<o problema, em 2 ou 3 frases>

## Decisão
<o que foi decidido>

## Alternativas consideradas
- <alternativa> — <por que não>

## Base
- <pesquisa NNN, prova da etapa E, ou "escolha do usuário">
```

## privado/docs/ciclos/NN-nome/ciclo.md

Criado pelo `/construtor-equipe-iniciar`. Só o gerente edita.

```markdown
# Ciclo N — <nome>

Status: rascunho | aprovado (AAAA-MM-DD) | encerrado (AAAA-MM-DD) | cancelado (AAAA-MM-DD)

## Objetivo
<o que este ciclo entrega, em uma ou duas frases>

## Critério de pronto
- <comando, comportamento observável ou medição>

## Briefing
- P: ... — R: ...

## Decidir depois
- <decisão> — na etapa E — depende de: <pesquisa, prova ou resultado>

## Etapas
| # | Item | Tipo | Etapa |
|---|------|------|-------|
| 1 | #005 | pesquisa | <nome> |

### Etapa 1 — <nome> [pesquisa]
**Objetivo:** ...
**Entregáveis:** ...
**Critérios de aceite:**
- [ ] <comando, comportamento observável ou documento com fonte>
**Fora desta etapa:** ...

## Git
- Branch: ciclo-NN
- Commit inicial: <hash>
- Commit final: <hash, no /construtor-equipe-encerrar-ciclo>

## Lições
<no /construtor-equipe-encerrar-ciclo: o que se repetiu, o que funcionou, o que atrapalhou; cada item com o que fazer a respeito (regra, convenção, nada)>

## Cancelamento
<só se cancelado: motivo e o que o usuário decidiu sobre o que ficou fora do git>
```

No ciclo de conversão, troque "Briefing", "Decidir depois" e "Etapas" por:

```markdown
## Conversão
- Origem: <pasta dentro de conversor/>, <remoto, ou "sem git">, commit <hash, ou "nenhum">
- [ ] 1. Preparar
- [ ] 2. Inventário
- [ ] 3. Trazer o código e guardar o antigo
- [ ] 4. Entender o projeto
- [ ] 5. Documentos e quadro
- [ ] 6. Regras (<N> de <total> revisadas)
- [ ] 7. Fora da pasta
- [ ] 8. Conferir
- [ ] 9. Fechar

## Respostas
- P: ... — R: ...
```

## privado/docs/ciclos/NN-nome/etapas/EE-nome.md

Criado e mantido pela sessão da etapa. O gerente só escreve na seção "Revisão".

```markdown
# Ciclo N, etapa E — <nome> [tipo]

Status: planejada | em andamento | concluída | bloqueada | decisão pendente | revisada

## Respostas da sessão de perguntas
- P: ... — R: ...

## Padrões a seguir
- <arquivo existente em projeto/ a imitar> — <por quê> (ou "nenhum")

## Plano
- [ ] <passo> — arquivos: <caminhos em projeto/>

## Verificação dos critérios de aceite
- [ ] <critério> — <evidência: comando executado e trecho da saída, ou fonte e data>

## Notas da execução
- <desvios, problemas encontrados e como foram resolvidos>

## Alterações fora do git
- <servidor, banco, nuvem ou serviço: o que mudou, com o ok de quando, e como desfazer> (ou "nenhuma")

## Para o backlog
- <ideia, pendência ou bug antigo que não cabe nesta etapa> (ou "nada")

## Fechamento
- Data: AAAA-MM-DD
- Se bloqueada: <o que falta e por quê; em bug antigo: "Bug antigo (caso 3)", causa, passos para reproduzir e evidência>
- Se decisão pendente: <a decisão e as opções>

## Revisão
<do gerente, no /construtor-equipe-progresso: veredito, conversa com o usuário, correções pendentes>
```
