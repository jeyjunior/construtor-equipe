# privado/parametros

`parametro.json` (chaves de API e senhas de banco, no padrão de `.claude/rules/parametros.md`), certificados (.pfx, .pem, .key) e documentos sensíveis.

- Nunca copie nada daqui para `projeto/`. O sistema lê o `parametro.json` pelo caminho da variável de ambiente `PARAMETRO_JSON`.
- O `parametro.json` já vem com a estrutura base: troque `NomeDaEmpresa` pelo nome do serviço (um objeto por serviço; string de conexão do banco em `Banco.ConnectionString`) e preencha. A estrutura que o projeto usa fica em `projeto/parametro.exemplo.json` (valores vazios).
- O Claude não lê nem grava nesta pasta (bloqueado em `.claude/settings.json`). Se ele precisar de um segredo novo, ele acrescenta a chave no exemplo e pede para você preencher aqui.
- Esta pasta não entra em git, como todo o `privado/`. Faça o seu próprio backup dela.
