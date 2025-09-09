# Banco de Dados Asset

Este repositório contém o script SQL para criação do schema `volt` no PostgreSQL.

## Como executar

1. Criar o banco de dados (se necessário):
   - `CREATE DATABASE volt_capital;`
2. Conectar no banco `volt_capital` e rodar o arquivo `01_database (1).sql`:
   - `\i '01_database (1).sql'`

Observações:
- Requer extensão `citext` (permissão de superuser para `CREATE EXTENSION citext`).
- O script usa `IF NOT EXISTS` e é idempotente.
