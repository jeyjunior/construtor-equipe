---
name: encerrar-ciclo
description: Roda no gerente quando todas as etapas do ciclo estão revisadas. Confere o ciclo inteiro, registra os padrões observados, leva a branch do ciclo para a principal com o ok do usuário e deixa o projeto sem ciclo aberto.
disable-model-invocation: true
---

# Encerrar ciclo

Você é o **gerente** (veja "Papéis" no `CLAUDE.md`). O projeto não termina: ele fica sem ciclo aberto até o próximo `/novo-ciclo`. Todo ciclo passa por todos estes passos, seja grande ou pequeno.

`<ciclo>` é a pasta do ciclo atual em `estado.md`, `NN` é o número dele e `<principal>` é o `BRANCH_PRINCIPAL` de `.claude/comandos.conf`.

## 1. Conferir se pode fechar

Leia `Projeto_Documento/estado.md`, `<ciclo>/ciclo.md` e `<ciclo>/roadmap.md`. Se alguma etapa ou correção não está `revisada`, liste quais e pare. Se o usuário quiser desistir do ciclo, indique `/cancelar-ciclo`.

## 2. Conferir o ciclo inteiro (subagente)

Dispare **um** subagente (tipo `general-purpose`, só leitura e comandos de verificação):

> Confira o ciclo NN inteiro, na branch `ciclo-NN`. Leia `<ciclo>/ciclo.md`, `<ciclo>/roadmap.md` e `.claude/comandos.conf`. Confirme que `git -C Projeto status` está limpo e na branch `ciclo-NN`. Rode o `BUILD` e, se estiver preenchido, o `TESTE` dentro de `Projeto/`. Verifique o critério de pronto do ciclo com um comando ou comportamento observável; o que depender do usuário, aponte. Rode `git -C Projeto diff <principal>...ciclo-NN --stat` e diga se há documentação ou arquivo sensível. Não edite nada. Responda em no máximo 15 linhas: build, testes, critério de pronto (ok/faltando + evidência), riscos.

Se algo falhar, mostre e pare. O que faltar vira etapa nova neste ciclo, com o ok do usuário. O ciclo não fecha com falha conhecida.

## 3. Levantar os padrões (subagente)

Dispare **um** subagente (tipo `general-purpose`, só leitura):

> Leia `<ciclo>/` inteiro: `ciclo.md`, `roadmap.md`, `etapas/`, `correcoes/` e `metricas.md`, além das decisões deste ciclo em `Projeto_Documento/decisoes/` e de `git -C Projeto log --stat <principal>..ciclo-NN`. Procure o que se repetiu: problemas e bugs com a mesma causa, perguntas feitas em várias etapas, decisões parecidas, estruturas de código repetidas, correções pedidas no `/progresso`, desvios do plano, passos manuais. Só conta o que apareceu 2 vezes ou mais, com onde apareceu. Se nada se repetiu, diga isso. Não edite nada. Devolva no formato da seção "padroes-observados.md" de `.claude/modelos/documentos.md`.

## 4. Revisar com o usuário

1. Mostre o rascunho. Pergunte o que ele percebeu e o subagente não pegou.
2. Para cada padrão, defina com ele o candidato: skill, regra (`.claude/rules/`), modelo, hook, convenção ou nada.
3. Com o ok, grave `<ciclo>/padroes-observados.md`. Num ciclo sem repetições, registre `Nada se repetiu neste ciclo`.
4. Acrescente o resumo do ciclo em `<ciclo>/metricas.md` (totais e médias).

## 5. Levar para a principal

Mostre `git -C Projeto log --oneline <principal>..ciclo-NN` e peça um **ok explícito** para o merge. Sem esse ok, pare aqui: o ciclo continua aberto.

```bash
git -C Projeto switch <principal>
```
```bash
git -C Projeto merge --no-ff ciclo-NN -m "Merge: ciclo NN — <objetivo do ciclo>"
```

Se der conflito, rode `git -C Projeto merge --abort` e pare: conte ao usuário o que conflitou. O gerente não resolve conflito de código. O que conflitar vira etapa nova neste ciclo.

Com o merge feito, rode o `BUILD` em `Projeto/` e envie: `git -C Projeto push origin <principal>` (o kit pede confirmação; sem remoto, diga isso e siga).

## 6. Fechar

1. Em `ciclo.md`, grave `Status: encerrado (AAAA-MM-DD)` e o commit final (`git -C Projeto rev-parse HEAD`).
2. Atualize `Projeto_Documento/estado.md`: `sem ciclo aberto`, último ciclo fechado, último commit da principal, próximo passo `/novo-ciclo` num gerente novo. Este é o último registro.
3. Diga ao usuário para fechar esta sessão: o próximo ciclo começa numa sessão nova, aberta por ele no Root, com `/novo-ciclo`. Lembre que `padroes-observados.md` segue o mesmo formato em todo ciclo e projeto, para ser comparado depois.
