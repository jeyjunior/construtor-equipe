---
name: depurar
description: Use ao encontrar bug, erro, build quebrado, exceção ou comportamento inesperado, ANTES de propor ou aplicar qualquer correção. Gatilhos - "não está funcionando", "deu erro", "quebrou", "por que isso falha", "bug", "não era pra dar isso", erro de build ou de execução. Exige achar a causa antes de mexer no código.
---

# Depurar

**Nenhuma correção sem causa encontrada.** Corrigir um sintoma que você não entende cria um segundo bug.

## 1. Causa

1. Leia a mensagem de erro inteira, com o stack trace, não só a última linha.
2. Reproduza de forma confiável e anote o comando ou os passos exatos. Sem reprodução não há correção, só chute.
3. Veja o que mudou há pouco na área (`git -C Projeto diff`, `git -C Projeto log`).
4. Com vários componentes, confira o dado em cada fronteira (entrada e saída) e siga o dado errado até a origem, não até onde ele explodiu.

## 2. Comparação

Ache no próprio projeto um caso parecido que funciona e liste as diferenças entre ele e o que quebra. A causa está nessa lista.

## 3. Hipótese

Escreva uma hipótese só: "falha porque X". Teste com a menor mudança que isola uma variável. Hipótese derrubada: volte ao passo 1 com o que aprendeu. Não empilhe mudanças especulativas.

## 4. Correção

1. Uma mudança, na causa confirmada.
2. Repita a reprodução do passo 1 e mostre que o problema sumiu.
3. Rode o `BUILD` de `.claude/comandos.conf`. Se o usuário tiver testes, rode-os. Não escreva testes novos.
4. Nada de "já que estou aqui": nenhuma melhoria fora da correção.
5. Anotações da investigação, se valerem guardar, vão para `Projeto_Documento/` (por exemplo, nas notas da etapa), nunca para `Projeto/`.

## Três tentativas

**Três correções que falharam indicam problema de desenho, não de linha.** Pare, não tente a quarta, e discuta a estrutura com o usuário.

## Sinais de que você está chutando (pare e volte ao passo 1)

- "correção rápida agora, investigo depois"
- "vou mudar X e ver se resolve"
- "várias mudanças de uma vez para ganhar tempo"
- "deve ser X, já corrijo"
- "mais uma tentativa" depois de duas que falharam
- cada correção revela um problema novo em outro lugar
- o usuário pergunta "isso está acontecendo mesmo?" ou diz "para de adivinhar"

## Saída

```
Causa: <o que era, onde, evidência>
Correção: <a mudança>
Prova: <reprodução repetida e build, com trecho da saída>
```
