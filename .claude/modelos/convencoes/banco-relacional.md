---
paths:
  - "Projeto/**/*.sql"
---

<!--
MODELO para projetos com banco relacional (PostgreSQL, SQL Server, MySQL), trazido do vault.
Na Fase 3 do /iniciar-projeto, copie para .claude/rules/banco.md, remova este comentário e
ajuste `paths:` para onde o SQL vive no projeto (ex.: pasta de migrations, ou os arquivos
de repositório quando o SQL fica dentro do código, como em Dapper).
-->

# Convenções de banco de dados

## Chaves
- Toda tabela tem chave primária identity chamada `pk_<tabela>` (ex.: `pk_usuarios`). Nunca `id`.
- Chave estrangeira se chama `fk_<tabela_referenciada>` (ex.: `fk_usuarios`), sem prefixo de schema.
- Duas ou mais chaves estrangeiras para a mesma tabela: sufixe com o papel (`fk_usuarios_criador`, `fk_usuarios_revisor`).
- Identity por banco: PostgreSQL `INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`; SQL Server `INT IDENTITY(1,1) PRIMARY KEY`; MySQL `INT AUTO_INCREMENT PRIMARY KEY`.

## Datas
- Colunas de data e hora guardam horário de Brasília e se chamam `Data<Evento>` em PascalCase: `DataCriacao`, `DataAtualizacao`, `DataImportacao`, `DataVencimento`. Data efetiva do próprio registro (lançamento, ato): `Data`.
- Não usar `CreatedAt`, `UpdatedAt`, `Timestamp`, `created_at`, `updated_at`.

## Tipos
- Valor monetário: `DECIMAL(19,4)` (ou `NUMERIC(19,4)`). Nunca `FLOAT` ou `REAL`; no SQL Server, prefira `DECIMAL` a `MONEY`.
