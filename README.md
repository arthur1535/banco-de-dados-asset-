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

### Sementes de dados (seeds)

O script já inclui cargas de exemplo para as tabelas `usuarios`, `clientes`, `ativos`, `transacoes` e `consultas`.

- As inserções usam `ON CONFLICT DO NOTHING` nos campos únicos para evitar duplicidades.
- A trigger de posição negativa é criada como `CONSTRAINT TRIGGER` e retorna `NEW`, permitindo reexecuções sem erro.
- A primeira carga cria compras iniciais para evitar posição negativa antes de alternar entre compras e vendas.

Para reaplicar com segurança:

1. Conecte-se ao banco `volt_capital`.
2. Execute novamente o arquivo `01_database (1).sql`.
3. Verifique os contadores com as consultas de verificação ao final do arquivo.

## Interface web para visualizar triggers

Para demonstrar as triggers do schema `volt`, há um pequeno aplicativo Flask.

1. Instale as dependências Python:
   - `pip install flask psycopg2-binary`
2. Ajuste as variáveis de ambiente `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER` e `PGPASSWORD` se necessário.
3. Execute o servidor:
   - `python app.py`
4. Acesse [http://localhost:5000/](http://localhost:5000/) para listar as triggers.
