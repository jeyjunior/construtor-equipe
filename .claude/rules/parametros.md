# Parâmetros: padrão parametro.json (fixo em todo projeto)

Toda chave de API e senha de banco do projeto fica num único arquivo JSON chamado `parametro.json`, com esta forma:

```json
{
  "<NomeDaEmpresa>": {
    "ApiKey": "",
    "ApiSecret": ""
  },
  "Banco": {
    "ConnectionString": ""
  }
}
```

- Um objeto por empresa ou serviço externo, com o nome dela (ex.: `GatewayPagamento`, `ServicoEmail`). `ApiKey` e `ApiSecret` são os nomes padrão; outras propriedades do mesmo serviço entram no mesmo objeto (ex.: `Passphrase`).
- `Banco` guarda a conexão com o banco: `ConnectionString` é a string de conexão completa, com usuário e senha. Projeto que monta a conexão por partes guarda só a senha (`Senha`) e deixa servidor, porta e nome do banco na configuração normal. Mais de um banco: um objeto por banco (ex.: `BancoRelatorios`).
- Só entra o que é segredo. Configuração comum (URLs, nomes de banco, intervalos) fica na configuração normal do projeto.

**Onde fica:**
- O arquivo real: `privado/parametros/parametro.json`. Quem preenche é o usuário. Você não lê nem grava esse arquivo.
- Em `projeto/` vai só `parametro.exemplo.json`: mesma estrutura, todos os valores vazios. É ele que documenta as chaves e é versionado. Mudou a estrutura, mude o exemplo e avise o usuário para atualizar o real.
- `parametro.json` nunca entra em `projeto/` nem no git (bloqueado pelo kit).

**Como o sistema lê:** pelo caminho na variável de ambiente `PARAMETRO_JSON`. Em desenvolvimento ela aponta para `privado/parametros/parametro.json`; em produção, para o arquivo guardado no servidor, fora do repositório. Na inicialização, o sistema falha com mensagem clara se a variável não existir, o arquivo não existir ou um valor obrigatório estiver vazio, sem imprimir os valores. Em .NET: `AddJsonFile(caminho)` e `IOptions<T>` com validação na inicialização.

Se precisar de um segredo novo, acrescente a chave em `parametro.exemplo.json`, registre na tabela "Configuração e segredos" de `privado/docs/arquitetura.md` e peça ao usuário para preencher o real.
