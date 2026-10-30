---
name: etapa
description: Roda na sessão vinculada aberta pelo /iniciar-etapa. Conduz uma única etapa do roadmap em ordem fixa (apresentação, perguntas, execução, fechamento com o status no roadmap), lendo e atualizando Projeto_Documento/.
disable-model-invocation: true
argument-hint: "[número da etapa]"
---

# Etapa

Você é a **sessão desta etapa**, aberta pelo gerente (outra sessão; veja "Papéis" no `CLAUDE.md`). Você cuida só desta etapa, conversa direto com o usuário e, ao terminar, marca no roadmap como ela fechou.

Valem as regras do `CLAUDE.md` (estrutura de pastas, papéis e "Como trabalhamos"). Siga os passos **na ordem**, sem pular nenhum. Regras desta skill, do começo ao fim:

- **Pare e espere o "ok" do usuário** ao fim dos passos 2 e 3. Não emende um passo no outro na mesma resposta.
- **Decisão que o plano não cobre:**
  - dentro do escopo da etapa: pergunte ao usuário aqui e registre a resposta em `Projeto_Documento/decisoes/`;
  - que muda objetivo, arquitetura ou outras etapas do roadmap: não decida. Feche com status `decisão pendente` (passo 5) para o usuário levar ao gerente.
- **Tudo o que importa vai para o arquivo da etapa.** O gerente não lê esta conversa: o que não estiver em `Projeto_Documento/` não chega a ele.
- O status da etapa fica só na tabela do roadmap. Use os modelos de `.claude/modelos/documentos.md`.

## 1. Situar

1. Leia `Projeto_Documento/estado.md`, `Projeto_Documento/roadmap.md` e `.claude/comandos.conf`. Se `Projeto_Documento/referencias.md` citar esta etapa em "Onde pesa no projeto novo", leia a seção da referência. A etapa é a de `$ARGUMENTS` ou a indicada no `estado.md`.
2. A etapa anterior precisa estar `revisada`. Se não estiver, diga que o gerente ainda não liberou (`/progresso`) e pare.
3. Pelo status desta etapa no roadmap:
   - `pendente`: vá ao passo 2;
   - `planejada`: se a seção "Revisão" do arquivo da etapa trouxer mudanças no plano, ajuste o plano a elas; depois retome no passo 3.3 (revisar e mostrar o plano);
   - `em andamento` com correções pendentes na seção "Revisão": faça só as correções, depois vá ao passo 5;
   - `em andamento`: continue no passo 4, a partir do primeiro item não marcado;
   - `concluída`, `bloqueada` ou `decisão pendente`: a etapa já fechou. Diga ao usuário para rodar `/progresso` no gerente e pare;
   - `revisada`: a etapa já foi aprovada. Pare.

## 2. Apresentação

1. Mostre, a partir do roadmap: objetivo, entregáveis, critérios de aceite e o que fica fora.
2. Diga em poucas linhas como pretende fazer.
3. Pergunte se confirma. Mudança na etapa em si (entregáveis, critérios) é decisão do gerente: feche com `decisão pendente`.

## 3. Perguntas e plano

1. Antes de perguntar, confira para você mesmo o que a etapa precisa saber: escopo, dados (entidades, formatos, unicidade), comportamento em erro e quando algo externo falha, números (volume, tempo, limite, sempre com unidade), nomes já usados no projeto, como saber que terminou. Pergunte só o que estiver faltando ou ambíguo **e** mudar a implementação. O que já está nos documentos ou no código não vira pergunta. Siga a regra de perguntas do `CLAUDE.md`.
2. Crie `Projeto_Documento/etapas/NN-nome.md` com as respostas, os padrões a seguir (arquivos existentes a imitar) e o plano em checklist, cada item com os arquivos de `Projeto/` que vai tocar. Marque a etapa como `planejada` no roadmap.
3. Revise o plano antes de mostrar: nada "a definir", nenhuma contradição com os documentos, nada que exija adivinhar, cada critério de aceite verificável por um comando ou comportamento observável.
4. Mostre o plano. Com o ok, marque a etapa como `em andamento` no roadmap.

## 4. Execução

1. Siga o checklist, marcando cada item ao terminar.
2. Rode o `BUILD` ao longo do trabalho, não só no final. Erro ou comportamento inesperado: siga a skill `depurar`, sem tentativas no escuro.
3. Registre em "Notas da execução" qualquer desvio, problema ou escolha feita no caminho.
4. Leitura ou pesquisa ampla (muitos arquivos, documentação externa): use um subagente e traga só a conclusão, para manter esta sessão leve.

## 5. Fechamento

1. Revise o próprio diff da etapa (`git -C Projeto diff` e arquivos novos) e corrija o que achar, dentro do escopo:
   - código que não precisava existir: abstração sem segundo uso, wrapper que só repassa, configuração para algo que não varia;
   - duplicação: algo que já existia no projeto e foi reescrito;
   - falha silenciosa: erro capturado sem log, `|| true` ou valor padrão escondendo falha real.
2. Confira `git -C Projeto status`: nenhum arquivo de documentação (`.md` além do `README.md`, pasta `docs/`) e nenhum arquivo sensível (`.env`, `segredo.json`, chave, certificado). Se houver, mova para `Projeto_Documento/` antes de seguir.
3. Verifique cada critério de aceite agora (build, execução, chamada real, testes do usuário se existirem) e registre a evidência: comando executado e trecho da saída. Critério sem evidência fresca não passou.
4. Se comandos ou convenções mudaram, atualize `.claude/comandos.conf` ou o arquivo de convenções em `.claude/rules/` e mostre a alteração.
5. Preencha a seção "Fechamento" do arquivo da etapa (substitua a anterior, se houver) e marque no roadmap um destes status:
   - `concluída`: todos os critérios de aceite têm evidência;
   - `bloqueada`: falta algo que não depende de você. Escreva no "Fechamento" o que falta e por quê;
   - `decisão pendente`: precisa de uma decisão do gerente. Escreva no "Fechamento" a decisão e as opções.
6. Mostre um resumo curto do que foi feito e do que a revisão do diff corrigiu. Sugira uma mensagem de commit no formato `<Tipo>: <descrição>`, com `Adicao`, `Correcao` ou `Refatoracao`.
7. Comece esta última resposta pelo status (ex.: `Etapa 03: concluída`), para o usuário ver de cara como a etapa fechou. Termine dizendo a ele para voltar ao gerente e rodar `/progresso`. Não comece outra etapa.
