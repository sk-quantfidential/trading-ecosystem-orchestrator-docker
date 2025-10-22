-- Exchange Domain Schema Initialization
-- TSE-0001.4.2 Exchange Data Adapter & Orchestrator Integration

-- Create exchange schema
CREATE SCHEMA IF NOT EXISTS exchange;

-- accounts: User trading accounts
CREATE TABLE IF NOT EXISTS exchange.accounts (
    account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(100) NOT NULL,
    account_type VARCHAR(50) NOT NULL CHECK (account_type IN ('SPOT', 'MARGIN', 'FUTURES')),
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUSPENDED', 'CLOSED')),
    kyc_status VARCHAR(50) NOT NULL DEFAULT 'PENDING' CHECK (kyc_status IN ('PENDING', 'APPROVED', 'REJECTED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB,

    CONSTRAINT unique_user_account_type UNIQUE (user_id, account_type)
);

CREATE INDEX idx_accounts_user ON exchange.accounts(user_id);
CREATE INDEX idx_accounts_status ON exchange.accounts(status);
CREATE INDEX idx_accounts_kyc ON exchange.accounts(kyc_status);
CREATE INDEX idx_accounts_created ON exchange.accounts(created_at);

-- orders: Trading orders
CREATE TABLE IF NOT EXISTS exchange.orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES exchange.accounts(account_id),
    symbol VARCHAR(50) NOT NULL,
    order_type VARCHAR(50) NOT NULL CHECK (order_type IN ('MARKET', 'LIMIT', 'STOP')),
    side VARCHAR(10) NOT NULL CHECK (side IN ('BUY', 'SELL')),
    quantity DECIMAL(24, 8) NOT NULL,
    price DECIMAL(24, 8), -- NULL for market orders
    filled_quantity DECIMAL(24, 8) NOT NULL DEFAULT 0,
    average_price DECIMAL(24, 8),
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'OPEN', 'FILLED', 'PARTIAL', 'CANCELLED', 'REJECTED', 'EXPIRED')),
    time_in_force VARCHAR(10) NOT NULL DEFAULT 'GTC' CHECK (time_in_force IN ('GTC', 'IOC', 'FOK')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    filled_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    metadata JSONB,

    CONSTRAINT positive_quantity CHECK (quantity > 0),
    CONSTRAINT positive_filled_quantity CHECK (filled_quantity >= 0),
    CONSTRAINT filled_less_equal_quantity CHECK (filled_quantity <= quantity)
);

CREATE INDEX idx_orders_account ON exchange.orders(account_id);
CREATE INDEX idx_orders_symbol ON exchange.orders(symbol);
CREATE INDEX idx_orders_status ON exchange.orders(status);
CREATE INDEX idx_orders_side ON exchange.orders(side);
CREATE INDEX idx_orders_created ON exchange.orders(created_at);

-- trades: Executed trades (fills)
CREATE TABLE IF NOT EXISTS exchange.trades (
    trade_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES exchange.orders(order_id),
    account_id UUID NOT NULL REFERENCES exchange.accounts(account_id),
    symbol VARCHAR(50) NOT NULL,
    side VARCHAR(10) NOT NULL CHECK (side IN ('BUY', 'SELL')),
    quantity DECIMAL(24, 8) NOT NULL,
    price DECIMAL(24, 8) NOT NULL,
    fee DECIMAL(24, 8) NOT NULL DEFAULT 0,
    fee_currency VARCHAR(10),
    executed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB,

    CONSTRAINT positive_trade_quantity CHECK (quantity > 0),
    CONSTRAINT positive_price CHECK (price > 0),
    CONSTRAINT non_negative_fee CHECK (fee >= 0)
);

CREATE INDEX idx_trades_order ON exchange.trades(order_id);
CREATE INDEX idx_trades_account ON exchange.trades(account_id);
CREATE INDEX idx_trades_symbol ON exchange.trades(symbol);
CREATE INDEX idx_trades_executed ON exchange.trades(executed_at);

-- balances: Account balances per symbol
CREATE TABLE IF NOT EXISTS exchange.balances (
    balance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES exchange.accounts(account_id),
    symbol VARCHAR(50) NOT NULL,
    available_balance DECIMAL(24, 8) NOT NULL DEFAULT 0,
    locked_balance DECIMAL(24, 8) NOT NULL DEFAULT 0,
    total_balance DECIMAL(24, 8) NOT NULL DEFAULT 0,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB,

    CONSTRAINT positive_available_balance CHECK (available_balance >= 0),
    CONSTRAINT positive_locked_balance CHECK (locked_balance >= 0),
    CONSTRAINT total_equals_sum CHECK (total_balance = available_balance + locked_balance),
    CONSTRAINT unique_account_symbol UNIQUE (account_id, symbol)
);

CREATE INDEX idx_balances_account ON exchange.balances(account_id);
CREATE INDEX idx_balances_symbol ON exchange.balances(symbol);
CREATE INDEX idx_balances_updated ON exchange.balances(last_updated);

-- Create exchange_adapter database user
CREATE USER exchange_adapter WITH PASSWORD 'exchange-adapter-db-pass';

-- Grant schema permissions
GRANT USAGE ON SCHEMA exchange TO exchange_adapter;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA exchange TO exchange_adapter;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA exchange TO exchange_adapter;

-- Grant connect permission
GRANT CONNECT ON DATABASE trading_ecosystem TO exchange_adapter;

-- Ensure default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA exchange GRANT ALL PRIVILEGES ON TABLES TO exchange_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA exchange GRANT ALL PRIVILEGES ON SEQUENCES TO exchange_adapter;

-- Create health check function for exchange schema
CREATE OR REPLACE FUNCTION exchange.health_check()
RETURNS TABLE(schema_name TEXT, table_count BIGINT, status TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        'exchange'::TEXT,
        COUNT(*)::BIGINT,
        'healthy'::TEXT
    FROM information_schema.tables
    WHERE table_schema = 'exchange';
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission on health check function
GRANT EXECUTE ON FUNCTION exchange.health_check() TO exchange_adapter;
