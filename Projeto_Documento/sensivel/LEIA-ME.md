# Projeto_Documento/sensivel

`segredo.json` (chaves de API e senhas de banco, no padrão de `.claude/rules/segredos.md`), certificados (.pfx, .pem, .key) e documentos sensíveis.

- Nunca copie nada daqui para `Projeto/`. O sistema lê o `segredo.json` pelo caminho da variável de ambiente `SEGREDO_JSON`.
- A estrutura do `segredo.json` está em `Projeto/segredo.exemplo.json` (valores vazios). Copie para cá como `segredo.json` e preencha.
- O Claude não lê nem grava nesta pasta (bloqueado em `.claude/settings.json`). Se ele precisar de um segredo novo, ele acrescenta a chave no exemplo e pede para você preencher aqui.
- Esta pasta não entra em git, como todo o `Projeto_Documento/`.
