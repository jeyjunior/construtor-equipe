---
name: construtor-equipe-ciclo-curto
description: Trabalho pequeno, sem ciclo, numa sessão só - uma correção, um ajuste, uma mudança que cabe numa sessão e não pede decisão de projeto. Faz na branch curto-NNN a partir da principal, prova que funciona, atualiza a arquitetura e o README se a mudança os afeta, leva para a principal com o ok do usuário e registra no quadro, direto em "Feito". Também corrige bug antigo quando aberta pelo gerente durante um ciclo.
disable-model-invocation: true
argument-hint: "[o que fazer]"
---

# Ciclo curto

Você é a **sessão de ciclo curto** (veja "Papéis" no `CLAUDE.md`). Há dois modos:

- **Sem ciclo aberto:** a sessão foi aberta pelo usuário. Você faz o trabalho, o merge na principal e o registro no quadro.
- **Aberta pelo gerente, durante um ciclo:** o `prompt` traz o item `#NNN` de um bug antigo. Você corrige e faz o merge na principal, mas **não edita o quadro**: quem registra é o gerente.

`NNN` é o número do item no quadro, com três dígitos, e `<principal>` é o `BRANCH_PRINCIPAL` de `.claude/comandos.conf`.

## 1. Situar

1. Leia `privado/QUADRO.md` e `.claude/comandos.conf`. Sem quadro, o projeto ainda não começou: indique `/construtor-equipe-iniciar` e pare.
2. Sem ciclo aberto: se a "Situação" aponta outra sessão aberta, pare e avise. Rode `git -C projeto status`: limpo e na principal; senão, mostre e pare.
3. **Cabe aqui?** Se o trabalho pede decisão de projeto, pesquisa, alteração fora do git ou mais de uma sessão, não é ciclo curto. Diga isso, ofereça registrar no Backlog e indique `/construtor-equipe-iniciar`.

## 2. Entender

- **Bug:** siga a skill `construtor-equipe-depurar` até a causa confirmada, sem a parte de classificar, reproduzindo na principal. No modo aberto pelo gerente, se o bug não aparecer na principal, não corrija: diga "não se confirmou", com a evidência, mande o usuário voltar ao gerente e pare.
- **Ajuste ou mudança:** leia o que for preciso e diga, em até 5 linhas, o que vai mudar, em quais arquivos e como vai provar que funcionou.

Espere o ok do usuário.

## 3. Fazer

1. Sem ciclo aberto, `NNN` é o número do item do Backlog que originou o trabalho ou, se não veio de lá, o maior número do quadro mais 1. Crie a branch:
   ```bash
   git -C projeto switch <principal>
   ```
   ```bash
   git -C projeto switch -c curto-NNN
   ```
2. Faça só o combinado, sem melhorias de passagem. Siga "Como escrever código" do `CLAUDE.md` e a linha "Testes" de `.claude/rules/projeto.md`.
3. Prove: repita a reprodução ou a verificação combinada, rode o `BUILD` e, se estiver preenchido, o `TESTE`. Mostre o comando e o trecho da saída.
4. **Documentos.** Confira se a mudança deixou errado algo que `privado/docs/arquitetura.md` ou `projeto/README.md` dizem: comando para rodar, configuração, segredo, integração externa, componente. Se deixou, mostre o trecho novo ao usuário e, com o ok, atualize, com a data em "Atualizado" da arquitetura; o README vai no mesmo commit do código. Se nada mudou, diga isso em uma linha. `privado/docs/objetivo.md` não muda aqui: se a mudança pede isso, não é ciclo curto (volte ao passo 1.3).
5. Faça o commit na branch `curto-NNN`, mostrando a mensagem (`Correcao: ...`, `Adicao: ...` ou `Refatoracao: ...`).

## 4. Levar para a principal

Mostre `git -C projeto diff --stat <principal>...curto-NNN` e a evidência, e peça um **ok explícito** para o merge.

```bash
git -C projeto switch <principal>
```
```bash
git -C projeto merge --no-ff curto-NNN -m "Merge: ciclo curto NNN — <o que foi feito>"
```

## 5. Registrar

- **Sem ciclo aberto:** na principal, acrescente em "Feito" do quadro a linha `#NNN [curto] <o que foi feito e por quê> — AAAA-MM-DD — commit <hash curto>`; se veio do Backlog, tire de lá. Envie com `git -C projeto push origin <principal>` (pede confirmação; sem remoto, diga isso).
- **Aberta pelo gerente:** não edite o quadro e não faça push. Diga ao usuário para voltar ao gerente e rodar `/construtor-equipe-progresso`.

Comece a última resposta pelo resultado (ex.: `Ciclo curto 014: feito`).
