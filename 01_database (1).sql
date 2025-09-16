-- volt schema and seed data (idempotent)

CREATE SCHEMA IF NOT EXISTS volt;
CREATE EXTENSION IF NOT EXISTS citext;

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
    nome TEXT NOT NULL,
    email CITEXT NOT NULL UNIQUE,
    role role_type NOT NULL,
    status status_usuario NOT NULL DEFAULT 'ativo',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS volt.clientes (
    cliente_id SERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    documento TEXT NOT NULL UNIQUE,
    tipo_documento tipo_documento NOT NULL,
    perfil_risco perfil_risco NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS volt.ativos (
    ativo_id SERIAL PRIMARY KEY,
    ticker TEXT NOT NULL UNIQUE,
    nome TEXT NOT NULL,
    classe classe_ativo NOT NULL,
    moeda moeda NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS volt.transacoes (
    transacao_id SERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL REFERENCES volt.clientes(cliente_id),
    ativo_id INTEGER NOT NULL REFERENCES volt.ativos(ativo_id),
    tipo tipo_transacao NOT NULL,
    quantidade NUMERIC(18,6) NOT NULL CHECK (quantidade > 0),
    preco NUMERIC(18,6) NOT NULL CHECK (preco > 0),
    data_execucao TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS volt.consultas (
    consulta_id SERIAL PRIMARY KEY,
    usuario_id INTEGER NOT NULL REFERENCES volt.usuarios(usuario_id),
    cliente_id INTEGER REFERENCES volt.clientes(cliente_id),
    titulo TEXT NOT NULL,
    descricao TEXT NOT NULL,
    status status_consulta NOT NULL DEFAULT 'aberta',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_usuarios_email ON volt.usuarios (email);
CREATE INDEX IF NOT EXISTS idx_transacoes_cliente_id ON volt.transacoes (cliente_id);
CREATE INDEX IF NOT EXISTS idx_transacoes_ativo_id ON volt.transacoes (ativo_id);
CREATE INDEX IF NOT EXISTS idx_consultas_usuario_id ON volt.consultas (usuario_id);
CREATE INDEX IF NOT EXISTS idx_consultas_status ON volt.consultas (status);
CREATE INDEX IF NOT EXISTS idx_ativos_ticker ON volt.ativos (ticker);
CREATE INDEX IF NOT EXISTS idx_clientes_documento ON volt.clientes (documento);

CREATE OR REPLACE FUNCTION volt.set_updated_at() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION volt.normalize_email() RETURNS TRIGGER AS $$
BEGIN
    NEW.email := lower(trim(NEW.email));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION volt.only_digits_documento() RETURNS TRIGGER AS $$
BEGIN
    NEW.documento := regexp_replace(NEW.documento, '[^0-9]', '', 'g');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION volt.default_status_consulta() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IS NULL THEN
        NEW.status := 'aberta';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION volt.prevent_negative_position() RETURNS TRIGGER AS $$
DECLARE
    net_qty NUMERIC(18,6);
BEGIN
    SELECT SUM(CASE WHEN tipo = 'buy' THEN quantidade ELSE -quantidade END)
      INTO net_qty
      FROM volt.transacoes
     WHERE cliente_id = NEW.cliente_id AND ativo_id = NEW.ativo_id;

    IF net_qty IS NOT NULL AND net_qty < 0 THEN
        RAISE EXCEPTION 'Operação inválida: posição resultante negativa para cliente % e ativo %', NEW.cliente_id, NEW.ativo_id;
    END IF;

    RETURN NEW; -- for constraint trigger semantics
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_usuarios_set_updated_at') THEN
        CREATE TRIGGER trg_usuarios_set_updated_at BEFORE UPDATE ON volt.usuarios FOR EACH ROW EXECUTE FUNCTION volt.set_updated_at();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_clientes_set_updated_at') THEN
        CREATE TRIGGER trg_clientes_set_updated_at BEFORE UPDATE ON volt.clientes FOR EACH ROW EXECUTE FUNCTION volt.set_updated_at();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_ativos_set_updated_at') THEN
        CREATE TRIGGER trg_ativos_set_updated_at BEFORE UPDATE ON volt.ativos FOR EACH ROW EXECUTE FUNCTION volt.set_updated_at();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_transacoes_set_updated_at') THEN
        CREATE TRIGGER trg_transacoes_set_updated_at BEFORE UPDATE ON volt.transacoes FOR EACH ROW EXECUTE FUNCTION volt.set_updated_at();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_consultas_set_updated_at') THEN
        CREATE TRIGGER trg_consultas_set_updated_at BEFORE UPDATE ON volt.consultas FOR EACH ROW EXECUTE FUNCTION volt.set_updated_at();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_usuarios_normalize_email') THEN
        CREATE TRIGGER trg_usuarios_normalize_email BEFORE INSERT OR UPDATE ON volt.usuarios FOR EACH ROW EXECUTE FUNCTION volt.normalize_email();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_clientes_only_digits') THEN
        CREATE TRIGGER trg_clientes_only_digits BEFORE INSERT OR UPDATE ON volt.clientes FOR EACH ROW EXECUTE FUNCTION volt.only_digits_documento();
    END IF;

    -- always recreate constraint trigger safely
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_transacoes_prevent_negative') THEN
        EXECUTE 'DROP TRIGGER trg_transacoes_prevent_negative ON volt.transacoes';
    END IF;
    EXECUTE 'CREATE CONSTRAINT TRIGGER trg_transacoes_prevent_negative AFTER INSERT OR UPDATE ON volt.transacoes DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION volt.prevent_negative_position()';
END;
$$;

-- Seed data
INSERT INTO volt.usuarios (nome, email, role, status)
VALUES ('Super Admin', 'admin@volt.com', 'admin', 'ativo')
ON CONFLICT (email) DO NOTHING;

INSERT INTO volt.usuarios (nome, email, role, status)
SELECT 'Usuario ' || i,
       'user' || i || '@example.com',
       CASE (i % 3)
           WHEN 0 THEN 'analyst'::role_type
           WHEN 1 THEN 'sales'::role_type
           ELSE 'support'::role_type
       END,
       CASE (i % 2)
           WHEN 0 THEN 'ativo'::status_usuario
           ELSE 'inativo'::status_usuario
       END
FROM generate_series(2, 500) AS s(i)
ON CONFLICT (email) DO NOTHING;

INSERT INTO volt.clientes (nome, documento, tipo_documento, perfil_risco)
SELECT 'Cliente ' || i,
       lpad(floor(random() * 99999999999)::bigint::text, CASE (i % 2) WHEN 0 THEN 11 ELSE 14 END, '0'),
       CASE (i % 2)
           WHEN 0 THEN 'cpf'::tipo_documento
           ELSE 'cnpj'::tipo_documento
       END,
       CASE (i % 3)
           WHEN 0 THEN 'conservador'::perfil_risco
           WHEN 1 THEN 'moderado'::perfil_risco
           ELSE 'arrojado'::perfil_risco
       END
FROM generate_series(1, 400) AS s(i)
ON CONFLICT (documento) DO NOTHING;

INSERT INTO volt.ativos (ticker, nome, classe, moeda)
SELECT 'ATV' || i,
       'Ativo ' || i,
       CASE (i % 5)
           WHEN 0 THEN 'acao'::classe_ativo
           WHEN 1 THEN 'fundo'::classe_ativo
           WHEN 2 THEN 'etf'::classe_ativo
           WHEN 3 THEN 'fixa'::classe_ativo
           ELSE 'cripto'::classe_ativo
       END,
       CASE (i % 2)
           WHEN 0 THEN 'BRL'::moeda
           ELSE 'USD'::moeda
       END
FROM generate_series(1, 500) AS s(i)
ON CONFLICT (ticker) DO NOTHING;

-- initial buys to ensure non-negative positions
INSERT INTO volt.transacoes (cliente_id, ativo_id, tipo, quantidade, preco)
SELECT ((i - 1) % 400) + 1,
       ((i - 1) % 500) + 1,
       'buy'::tipo_transacao,
       (random() * 100 + 1)::NUMERIC(18,6),
       (random() * 50 + 1)::NUMERIC(18,6)
FROM generate_series(1, 1000) AS s(i);

-- alternating buys/sells with smaller sizes
INSERT INTO volt.transacoes (cliente_id, ativo_id, tipo, quantidade, preco)
SELECT ((i - 1) % 400) + 1,
       ((i - 1) % 500) + 1,
       CASE (i % 2)
           WHEN 0 THEN 'buy'::tipo_transacao
           ELSE 'sell'::tipo_transacao
       END,
       (random() * 20 + 1)::NUMERIC(18,6),
       (random() * 55 + 1)::NUMERIC(18,6)
FROM generate_series(1001, 2000) AS s(i);

INSERT INTO volt.consultas (usuario_id, cliente_id, titulo, descricao, status)
SELECT ((i - 1) % 500) + 1,
       ((i - 1) % 400) + 1,
       'Consulta ' || i,
       'Descrição automática para a consulta ' || i,
       CASE (i % 3)
           WHEN 0 THEN 'aberta'::status_consulta
           WHEN 1 THEN 'andamento'::status_consulta
           ELSE 'fechada'::status_consulta
       END
FROM generate_series(1, 1000) AS s(i);

-- verification samples
SELECT role, status, COUNT(*) FROM volt.usuarios GROUP BY role, status ORDER BY role, status;
SELECT tipo_documento, perfil_risco, COUNT(*) FROM volt.clientes GROUP BY tipo_documento, perfil_risco ORDER BY tipo_documento, perfil_risco;
SELECT classe, moeda, COUNT(*) FROM volt.ativos GROUP BY classe, moeda ORDER BY classe, moeda;
SELECT tipo, COUNT(*) FROM volt.transacoes GROUP BY tipo;
SELECT status, COUNT(*) FROM volt.consultas GROUP BY status;

SELECT t.data_execucao, c.nome AS nome_do_cliente, a.ticker AS codigo_do_ativo, t.tipo, t.quantidade, t.preco
FROM volt.transacoes AS t
JOIN volt.clientes AS c ON t.cliente_id = c.cliente_id
JOIN volt.ativos   AS a ON t.ativo_id   = a.ativo_id
ORDER BY t.data_execucao DESC
LIMIT 10;

SELECT co.consulta_id, co.titulo, co.status, u.nome AS nome_do_analista, cl.nome AS nome_do_cliente
FROM volt.consultas AS co
JOIN volt.usuarios AS u ON co.usuario_id = u.usuario_id
JOIN volt.clientes AS cl ON co.cliente_id = cl.cliente_id
WHERE co.status = 'aberta'
LIMIT 10;
