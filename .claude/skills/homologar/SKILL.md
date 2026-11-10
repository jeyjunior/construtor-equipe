---
name: homologar
description: Roda no gerente, sem ciclo aberto. Leva os itens de "Feito" para "Homologado" no quadro, agrupados pela versão que o usuário informar, e cria a tag da versão com o ok dele.
disable-model-invocation: true
argument-hint: "[versão, opcional]"
---

# Homologar

"Homologado" quer dizer: publicado ou validado pelo usuário no destino. Quem afirma isso é o usuário; você só registra.

`<principal>` é o `BRANCH_PRINCIPAL` de `.claude/comandos.conf`.

## 1. Situar

1. Leia `privado/QUADRO.md`. Com ciclo aberto, diga que a homologação é registrada depois do `/encerrar-ciclo` e pare. Com "Feito" vazio, diga isso e pare.
2. Rode `git -C projeto status`: limpo e na branch principal. Se não estiver, mostre e pare.

## 2. Perguntar

1. **Quais itens** de "Feito" foram homologados. O padrão é todos.
2. **Versão** (`$ARGUMENTS` pode já trazer). Mostre a última de "Homologado" e sugira a próxima no formato `vMAIOR.MENOR.CORRECAO`: correção para bug, menor para funcionalidade, maior para mudança que quebra o uso anterior. A primeira é `v0.1.0`.
3. **Onde e quando** foi publicado ou validado, em uma linha.

## 3. Registrar

1. No quadro, crie `### vX.Y.Z — AAAA-MM-DD` no topo de "Homologado", com a linha de onde foi validado, e mova os itens para lá.
2. "Homologado" guarda as 3 versões mais recentes. As anteriores vão para `privado/docs/historico.md`, no mesmo formato, no topo.

## 4. Tag

Pergunte se cria a tag da versão. Com o ok:

```bash
git -C projeto tag -a vX.Y.Z -m "vX.Y.Z"
```
```bash
git -C projeto push origin <principal> --follow-tags
```

O push pede confirmação; sem remoto, diga isso e siga.
