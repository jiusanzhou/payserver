-- PayServer Database Schema
-- Run this in Supabase SQL Editor or psql

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Agents table
CREATE TABLE IF NOT EXISTS agents (
    id BIGSERIAL PRIMARY KEY,
    uid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    device_id VARCHAR(255) UNIQUE NOT NULL,
    pay_types VARCHAR(255) DEFAULT '',
    heartbeat_at TIMESTAMPTZ DEFAULT NOW(),
    status INTEGER DEFAULT 0,
    ticket VARCHAR(255) DEFAULT '',
    device_info TEXT DEFAULT '',
    external TEXT DEFAULT '',
    create_at TIMESTAMPTZ DEFAULT NOW(),
    update_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_agents_device_id ON agents(device_id);
CREATE INDEX IF NOT EXISTS idx_agents_ticket ON agents(ticket);
CREATE INDEX IF NOT EXISTS idx_agents_status ON agents(status);

-- Apps table
CREATE TABLE IF NOT EXISTS apps (
    id BIGSERIAL PRIMARY KEY,
    uid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT DEFAULT '',
    callback_url VARCHAR(1024) DEFAULT '',
    secret VARCHAR(255) NOT NULL,
    aes_key VARCHAR(255) DEFAULT '',
    price_floor INTEGER DEFAULT 2,
    price_ceil INTEGER DEFAULT 2,
    expire_in INTEGER DEFAULT 300,
    max_pendding_order INTEGER DEFAULT 10,
    user_uid UUID,
    create_at TIMESTAMPTZ DEFAULT NOW(),
    update_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_apps_name ON apps(name);

-- App-Agent binding table (many-to-many)
CREATE TABLE IF NOT EXISTS app_agents (
    id BIGSERIAL PRIMARY KEY,
    app_uid UUID NOT NULL,
    agent_uid UUID NOT NULL,
    weight INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    UNIQUE(app_uid, agent_uid)
);

CREATE INDEX IF NOT EXISTS idx_app_agents_app ON app_agents(app_uid);
CREATE INDEX IF NOT EXISTS idx_app_agents_agent ON app_agents(agent_uid);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
    id BIGSERIAL PRIMARY KEY,
    uid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    app_id UUID NOT NULL,
    -- PreOrder embedded fields (prefixed with o_)
    o_number VARCHAR(255) NOT NULL,
    o_name VARCHAR(255) DEFAULT '',
    o_price INTEGER NOT NULL,
    o_redirect_url VARCHAR(1024) DEFAULT '',
    o_external TEXT DEFAULT '',
    -- Order fields
    expires_in INTEGER DEFAULT 300,
    qr_data TEXT DEFAULT '',
    qr_image_url VARCHAR(1024) DEFAULT '',
    sched_agent_uid UUID NOT NULL,
    sched_pay_type VARCHAR(50) NOT NULL,
    sched_price INTEGER NOT NULL,
    pay_record_uid UUID,
    status INTEGER DEFAULT 1,
    create_at TIMESTAMPTZ DEFAULT NOW(),
    update_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    UNIQUE(app_id, o_number)
);

CREATE INDEX IF NOT EXISTS idx_orders_app ON orders(app_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_sched ON orders(sched_agent_uid, sched_pay_type, sched_price);

-- Pay Records table
CREATE TABLE IF NOT EXISTS pay_records (
    id BIGSERIAL PRIMARY KEY,
    uid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    agent_uid UUID NOT NULL,
    type VARCHAR(50) NOT NULL,
    number VARCHAR(255) NOT NULL,
    amount INTEGER NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    account_uid UUID,
    external TEXT DEFAULT '',
    create_at TIMESTAMPTZ DEFAULT NOW(),
    update_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_pay_records_agent ON pay_records(agent_uid);
CREATE INDEX IF NOT EXISTS idx_pay_records_type ON pay_records(type);

-- Callback Logs table
CREATE TABLE IF NOT EXISTS callback_logs (
    id BIGSERIAL PRIMARY KEY,
    uid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    order_uid UUID NOT NULL,
    app_id UUID NOT NULL,
    callback_url VARCHAR(1024) NOT NULL,
    payload TEXT NOT NULL,
    status INTEGER DEFAULT 1,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 5,
    last_error TEXT DEFAULT '',
    last_response TEXT DEFAULT '',
    last_attempt TIMESTAMPTZ,
    next_attempt TIMESTAMPTZ,
    create_at TIMESTAMPTZ DEFAULT NOW(),
    update_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_callback_logs_order ON callback_logs(order_uid);
CREATE INDEX IF NOT EXISTS idx_callback_logs_status ON callback_logs(status);
CREATE INDEX IF NOT EXISTS idx_callback_logs_next ON callback_logs(next_attempt);

-- Accounts table (optional, for future use)
CREATE TABLE IF NOT EXISTS accounts (
    id BIGSERIAL PRIMARY KEY,
    uid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    name VARCHAR(255) DEFAULT '',
    type VARCHAR(50) DEFAULT '',
    external TEXT DEFAULT '',
    create_at TIMESTAMPTZ DEFAULT NOW(),
    update_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Users table (for admin)
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    uid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    create_at TIMESTAMPTZ DEFAULT NOW(),
    update_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Enable Row Level Security (optional, for production)
-- ALTER TABLE agents ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE apps ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE pay_records ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE callback_logs ENABLE ROW LEVEL SECURITY;

SELECT 'PayServer schema created successfully!' AS result;
