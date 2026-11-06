---
name: buscar-referencia
description: Analisa material de referência (outro projeto, pasta, repositório, link) com subagentes guiados por perguntas dirigidas e grava o resultado em Projeto_Documento/referencias.md. Usada na fase de referências do /iniciar-projeto ou sozinha, a qualquer momento.
disable-model-invocation: true
argument-hint: "[caminho ou link, opcional]"
---

# Buscar referência

Referência **informa** decisões, não decide. O resultado vai para `Projeto_Documento/referencias.md`, porque o gerente é descartável e as sessões de etapa não leem esta conversa.

## 1. Coletar

1. Leia `Projeto_Documento/objetivo.md` (se existir) e `Projeto_Documento/referencias.md` (se existir, para não analisar de novo o que já está lá).
2. Peça ao usuário, para cada referência (pode vir em `$ARGUMENTS`):
   - onde está: pasta, repositório ou link;
   - uma ou duas frases de contexto: o que é e por que serve de referência;
   - o que ele quer tirar dela (ex.: "o esquema do banco", "como o bot se recupera de queda").
3. Pasta fora do Root: avise que o Claude pode pedir permissão para ler lá. Repositório privado: depende do `gh` autenticado na máquina.

## 2. Perguntas dirigidas

Monte, para cada referência, as perguntas que ela deve responder: as que o usuário pediu, mais as que o objetivo do projeto novo torna relevantes, partindo desta lista:

- stack e versões;
- estrutura de pastas e componentes;
- banco: tabelas principais, chaves, como acessa;
- configuração e segredos (só a estrutura, nunca valores);
- como roda, agenda e se recupera de falha;
- integrações externas e o que faz quando caem;
- logs e monitoramento.

Corte o que não interessa ao projeto novo. Mostre as perguntas e espere o ok.

## 3. Análise (subagentes)

Dispare **um subagente por referência** (tipo `general-purpose`, só leitura). Referências independentes rodam em paralelo. Tarefa de cada um:

> Analise a referência em `<caminho ou link>`. Contexto do usuário: `<contexto>`. Projeto novo: `<objetivo em 2 linhas>`.
> **Nunca abra** `sensivel/`, `segredo.json`, `.env*`, chaves ou certificados, nem copie valores que pareçam segredo.
> Se existirem, leia primeiro `Projeto_Documento/ciclos/*/padroes-observados.md` (ou `Projeto_Documento/padroes-observados.md`, em projeto antigo), `arquitetura.md` e `decisoes/` da referência: são a experiência registrada do projeto. Depois, o código.
> Responda cada pergunta com o caminho do arquivo que comprova: `<perguntas>`.
> Separe o que vale **reaproveitar** do que vale **evitar** (problemas, gambiarras, padrões que o próprio projeto registrou como ruins).
> Não decida nada pelo projeto novo. Não edite nada. Máximo de uma página, no formato da seção "referencias.md" de `.claude/modelos/documentos.md`. Trechos de código só curtos, quando a estrutura não der para descrever em texto.

## 4. Registrar

1. Mostre o resultado. Pergunte o que o usuário corrige ou acrescenta: ele conhece a referência melhor que o subagente.
2. Com o ok, acrescente uma seção por referência em `Projeto_Documento/referencias.md` (crie o arquivo se não existir).
3. Diga em uma linha onde cada referência pesa nas próximas decisões (ex.: "o esquema do bot X entra na discussão do banco na Fase 3"). A decisão continua sendo do usuário.
