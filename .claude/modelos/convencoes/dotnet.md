---
paths:
  - "projeto/**/*.cs"
  - "projeto/**/*.csproj"
---

<!--
MODELO para projetos .NET. Quando a tecnologia for decidida no /construtor-equipe-iniciar, copie para .claude/rules/dotnet.md,
remova este comentário, tire o que não se aplica (ex.: a seção Workers num projeto web) e
acrescente as convenções que decorrem das decisões do projeto.

Ajustes de ambiente que acompanham este modelo:

.claude/comandos.conf (na etapa 1, quando a solution existir; caminhos relativos a projeto/):
  BUILD="dotnet build <Solution>.slnx -nologo -v q -clp:ErrorsOnly"
  CODIGO="*.cs *.csproj *.props *.targets *.sln *.slnx"
  BUILD_IGNORAR="MSB3021|MSB3026|MSB3027"
  FORMATAR="dotnet format whitespace --folder --include {arquivo}"
  FORMATAR_EXTENSOES="cs"
  EXECUTAR="dotnet run --project <projeto executável>"
  TESTE="dotnet test <Solution>.slnx -nologo -v q" (só se o projeto tiver testes)

projeto/.gitignore (acrescentar):  bin/  obj/  *.user  .vs/  TestResults/

.claude/settings.json, em permissions.allow:
  "Bash(dotnet build *)", "Bash(dotnet format *)", "Bash(dotnet restore *)", "Bash(dotnet run *)"
  e "Bash(dotnet test *)" se o projeto tiver testes.

Etapa 1: criar projeto/.editorconfig (o dotnet format segue ele) e projeto/Directory.Build.props
com <Nullable>enable</Nullable>; avaliar <TreatWarningsAsErrors>true</TreatWarningsAsErrors>.
-->

# Convenções de C#

## Gerais
- Nullable habilitado e avisos tratados; não suprimir aviso sem comentário explicando o motivo.
- `async` de ponta a ponta. Nada de `.Result` ou `.Wait()`.
- Todo método assíncrono que faz I/O recebe e repassa `CancellationToken`.
- Injeção de dependência pelo construtor. Sem service locator.
- Configuração via `IOptions<T>` com classes tipadas e validação na inicialização. Não ler `IConfiguration` direto nas classes de negócio.
- Logs com `ILogger<T>` e mensagens estruturadas (`"Processou {Quantidade} itens"`), nunca com interpolação de string.
- Nenhum segredo no código nem em `appsettings*.json`: chaves de API e senhas de banco seguem o padrão `parametro.json` de `.claude/rules/parametros.md` (lido com `AddJsonFile` pelo caminho de `PARAMETRO_JSON`, com `IOptions<T>` validado na inicialização).
- Lógica de negócio em classes que não dependem de banco nem de rede, para que possam ser testadas.

## Workers (se o projeto tiver)
- Cada worker herda de `BackgroundService` e mantém `ExecuteAsync` enxuto, delegando o trabalho a serviços.
- Exceção dentro do laço do worker é registrada no log e não derruba o processo, a menos que seja irrecuperável.
- O worker respeita o `stoppingToken` para encerrar de forma limpa.

<!-- O /construtor-equipe-iniciar acrescenta abaixo as convenções que decorrem das decisões do projeto (acesso a dados, APIs externas etc.). -->
