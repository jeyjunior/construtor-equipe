# privado/parametros

`parametro.json` (chaves de API e senhas de banco, no padrão de `.claude/rules/parametros.md`), certificados (.pfx, .pem, .key) e documentos sensíveis.

- Nunca copie nada daqui para `projeto/`. O sistema lê o `parametro.json` pelo caminho da variável de ambiente `PARAMETRO_JSON`.
- A estrutura do `parametro.json` está em `projeto/parametro.exemplo.json` (valores vazios). Copie para cá como `parametro.json` e preencha.
- O Claude não lê nem grava nesta pasta (bloqueado em `.claude/settings.json`). Se ele precisar de um segredo novo, ele acrescenta a chave no exemplo e pede para você preencher aqui.
- Esta pasta não entra em git, como todo o `privado/`. Faça o seu próprio backup dela.
