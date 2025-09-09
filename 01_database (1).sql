-- Antes de executar este script, crie o banco de dados `volt_capital` manualmente:
--   CREATE DATABASE volt_capital;
-- Em seguida, conecte-se ao banco `volt_capital` e execute o restante deste arquivo.



-- Schema and extension
CREATE SCHEMA IF NOT EXISTS volt;
CREATE EXTENSION IF NOT EXISTS citext;

-- Criação de tipos ENUM (executar apenas se ainda não existirem)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'role_type') THEN
        CREATE TYPE role_type AS ENUM ('admin','analyst','sales','support');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'status_usuario') THEN
        CREATE TYPE status_usuario AS ENUM ('ativo','inativo');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_documento') THEN
        CREATE TYPE tipo_documento AS ENUM ('cpf','cnpj');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'perfil_risco') THEN
        CREATE TYPE perfil_risco AS ENUM ('conservador','moderado','arrojado');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'classe_ativo') THEN
        CREATE TYPE classe_ativo AS ENUM ('acao','fundo','etf','fixa','cripto');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'moeda') THEN
        CREATE TYPE moeda AS ENUM ('BRL','USD');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_transacao') THEN
        CREATE TYPE tipo_transacao AS ENUM ('buy','sell');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'status_consulta') THEN
        CREATE TYPE status_consulta AS ENUM ('aberta','andamento','fechada');
    END IF;
END$$;





CREATE TABLE IF NOT EXISTS volt.usuarios (
    usuario_id SERIAL PRIMARY KEY,
    nome       TEXT NOT NULL,
    email      CITEXT NOT NULL UNIQUE,
    role       role_type NOT NULL,
    status     status_usuario NOT NULL DEFAULT 'ativo',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


CREATE TABLE IF NOT EXISTS volt.clientes (
    cliente_id     SERIAL PRIMARY KEY,
    nome           TEXT NOT NULL,
    documento      TEXT NOT NULL UNIQUE,
    tipo_documento tipo_documento NOT NULL,
    perfil_risco   perfil_risco NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);


CREATE TABLE IF NOT EXISTS volt.ativos (
    ativo_id   SERIAL PRIMARY KEY,
    ticker     TEXT NOT NULL UNIQUE,
    nome       TEXT NOT NULL,
    classe     classe_ativo NOT NULL,
    moeda      moeda NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


CREATE TABLE IF NOT EXISTS volt.transacoes (
    transacao_id   SERIAL PRIMARY KEY,
    cliente_id     INTEGER NOT NULL REFERENCES volt.clientes(cliente_id),
    ativo_id       INTEGER NOT NULL REFERENCES volt.ativos(ativo_id),
    tipo           tipo_transacao NOT NULL,
    quantidade     NUMERIC(18,6) NOT NULL CHECK (quantidade > 0),
    preco          NUMERIC(18,6) NOT NULL CHECK (preco > 0),
    data_execucao  TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);


CREATE TABLE IF NOT EXISTS volt.consultas (
    consulta_id SERIAL PRIMARY KEY,
    usuario_id  INTEGER NOT NULL REFERENCES volt.usuarios(usuario_id),
    cliente_id  INTEGER REFERENCES volt.clientes(cliente_id),
    titulo      TEXT NOT NULL,
    descricao   TEXT NOT NULL,
    status      status_consulta NOT NULL DEFAULT 'aberta',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- Indexes
CREATE INDEX IF NOT EXISTS idx_usuarios_email ON volt.usuarios (email);
CREATE INDEX IF NOT EXISTS idx_transacoes_cliente_id ON volt.transacoes (cliente_id);
CREATE INDEX IF NOT EXISTS idx_transacoes_ativo_id ON volt.transacoes (ativo_id);
CREATE INDEX IF NOT EXISTS idx_consultas_usuario_id ON volt.consultas (usuario_id);
CREATE INDEX IF NOT EXISTS idx_consultas_status ON volt.consultas (status);
CREATE INDEX IF NOT EXISTS idx_ativos_ticker ON volt.ativos (ticker);
CREATE INDEX IF NOT EXISTS idx_clientes_documento ON volt.clientes (documento);

-- Trigger function to set updated_at
CREATE OR REPLACE FUNCTION volt.set_updated_at() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Normalize email to lowercase and trim spaces
CREATE OR REPLACE FUNCTION volt.normalize_email() RETURNS TRIGGER AS $$
BEGIN
    NEW.email := lower(trim(NEW.email));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Strip non-numeric characters from documento
CREATE OR REPLACE FUNCTION volt.only_digits_documento() RETURNS TRIGGER AS $$
BEGIN
    NEW.documento := regexp_replace(NEW.documento, '[^0-9]', '', 'g');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Default status for consultas if null
CREATE OR REPLACE FUNCTION volt.default_status_consulta() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IS NULL THEN
        NEW.status := 'aberta';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Prevent negative position for transacoes
CREATE OR REPLACE FUNCTION volt.prevent_negative_position() RETURNS TRIGGER AS $$
DECLARE
    net_qty NUMERIC(18,6);
BEGIN
    SELECT SUM(CASE WHEN tipo = 'buy' THEN quantidade ELSE -quantidade END)
    INTO net_qty
    FROM volt.transacoes
    WHERE cliente_id = NEW.cliente_id AND ativo_id = NEW.ativo_id;
    IF net_qty < 0 THEN
        RAISE EXCEPTION 'Operação inválida: posição resultante negativa para cliente % e ativo %', NEW.cliente_id, NEW.ativo_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger assignments
CREATE OR REPLACE TRIGGER trg_usuarios_set_updated_at
BEFORE UPDATE ON volt.usuarios
FOR EACH ROW EXECUTE FUNCTION volt.set_updated_at();

CREATE OR REPLACE TRIGGER trg_clientes_set_updated_at
BEFORE UPDATE ON volt.clientes
FOR EACH ROW EXECUTE FUNCTION volt.set_updated_at();

CREATE OR REPLACE TRIGGER trg_ativos_set_updated_at
BEFORE UPDATE ON volt.ativos
FOR EACH ROW EXECUTE FUNCTION volt.set_updated_at();

CREATE OR REPLACE TRIGGER trg_transacoes_set_updated_at
BEFORE UPDATE ON volt.transacoes
FOR EACH ROW EXECUTE FUNCTION volt.set_updated_at();

CREATE OR REPLACE TRIGGER trg_consultas_set_updated_at
BEFORE UPDATE ON volt.consultas
FOR EACH ROW EXECUTE FUNCTION volt.set_updated_at();

CREATE OR REPLACE TRIGGER trg_usuarios_normalize_email
BEFORE INSERT OR UPDATE ON volt.usuarios
FOR EACH ROW EXECUTE FUNCTION volt.normalize_email();

CREATE OR REPLACE TRIGGER trg_clientes_only_digits
BEFORE INSERT OR UPDATE ON volt.clientes
FOR EACH ROW EXECUTE FUNCTION volt.only_digits_documento();

CREATE OR REPLACE TRIGGER trg_consultas_default_status
BEFORE INSERT ON volt.consultas
FOR EACH ROW EXECUTE FUNCTION volt.default_status_consulta();

-- Ensure idempotency for the constraint trigger on transacoes
DROP TRIGGER IF EXISTS trg_transacoes_prevent_negative ON volt.transacoes;
CREATE CONSTRAINT TRIGGER trg_transacoes_prevent_negative
AFTER INSERT OR UPDATE ON volt.transacoes
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION volt.prevent_negative_position();

-- ---------------------------------------------------------------------------
-- Sample data
-- ---------------------------------------------------------------------------

-- Usuarios de exemplo
INSERT INTO volt.usuarios (nome, email, role)
SELECT 'Usuario ' || i, 'user' || i || '@example.com', 'analyst'
FROM generate_series(1, 50) AS s(i);

-- Clientes de exemplo
INSERT INTO volt.clientes (nome, documento, tipo_documento, perfil_risco)
SELECT 'Cliente ' || i,
       lpad(i::text, 11, '0'),
       'cpf',
       'moderado'
FROM generate_series(1, 200) AS s(i);

-- Ativos de exemplo
INSERT INTO volt.ativos (ticker, nome, classe, moeda)
SELECT 'ATV' || i,
       'Ativo ' || i,
       'acao',
       'BRL'
FROM generate_series(1, 20) AS s(i);

-- Transacoes de exemplo (1000 linhas)
INSERT INTO volt.transacoes (cliente_id, ativo_id, tipo, quantidade, preco)
SELECT ((i - 1) % 200) + 1 AS cliente_id,
       ((i - 1) % 20) + 1 AS ativo_id,
       CASE WHEN i % 2 = 0 THEN 'buy' ELSE 'sell' END AS tipo,
       (i % 100 + 1)::NUMERIC(18,6) AS quantidade,
       (i % 50 + 1)::NUMERIC(18,6) AS preco
FROM generate_series(1, 1000) AS s(i);

-- Consultas de exemplo (1000 linhas)
INSERT INTO volt.consultas (usuario_id, cliente_id, titulo, descricao, status)
SELECT ((i - 1) % 50) + 1 AS usuario_id,
       ((i - 1) % 200) + 1 AS cliente_id,
       'Consulta ' || i AS titulo,
       CASE ((i - 1) % 4)
           WHEN 0 THEN 'consulta de saldo'
           WHEN 1 THEN 'consulta de vendas'
           WHEN 2 THEN 'consulta de ativos'
           ELSE 'consulta de ativos'
       END AS descricao,
       'aberta' AS status
FROM generate_series(1, 1000) AS s(i);
