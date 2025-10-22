-- Custodian Domain Schema Initialization
-- TSE-0001.4 Data Adapters & Orchestrator Integration

-- Create custodian schema
CREATE SCHEMA IF NOT EXISTS custodian;

-- positions: Track asset positions held in custody
CREATE TABLE IF NOT EXISTS custodian.positions (
    position_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id VARCHAR(100) NOT NULL,
    symbol VARCHAR(50) NOT NULL,
    quantity DECIMAL(24, 8) NOT NULL,
    available_quantity DECIMAL(24, 8) NOT NULL,
    locked_quantity DECIMAL(24, 8) NOT NULL DEFAULT 0,
    average_cost DECIMAL(24, 8),
    market_value DECIMAL(24, 8),
    currency VARCHAR(10) NOT NULL DEFAULT 'USD',
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB,

    CONSTRAINT positive_quantity CHECK (quantity >= 0),
    CONSTRAINT available_less_equal_quantity CHECK (available_quantity <= quantity),
    CONSTRAINT unique_account_symbol UNIQUE (account_id, symbol)
);

CREATE INDEX idx_positions_account ON custodian.positions(account_id);
CREATE INDEX idx_positions_symbol ON custodian.positions(symbol);
CREATE INDEX idx_positions_updated ON custodian.positions(last_updated);

-- settlements: Track settlement instructions and status
CREATE TABLE IF NOT EXISTS custodian.settlements (
    settlement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_id VARCHAR(100) UNIQUE,
    settlement_type VARCHAR(50) NOT NULL, -- 'DEPOSIT', 'WITHDRAWAL', 'TRANSFER'
    account_id VARCHAR(100) NOT NULL,
    symbol VARCHAR(50) NOT NULL,
    quantity DECIMAL(24, 8) NOT NULL,
    status VARCHAR(50) NOT NULL, -- 'PENDING', 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'CANCELLED'
    source_account VARCHAR(100),
    destination_account VARCHAR(100),
    initiated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    expected_settlement_date TIMESTAMPTZ,
    metadata JSONB,

    CONSTRAINT positive_settlement_quantity CHECK (quantity > 0)
);

CREATE INDEX idx_settlements_account ON custodian.settlements(account_id);
CREATE INDEX idx_settlements_status ON custodian.settlements(status);
CREATE INDEX idx_settlements_type ON custodian.settlements(settlement_type);
CREATE INDEX idx_settlements_initiated ON custodian.settlements(initiated_at);

-- balances: Track account balances and balance history
CREATE TABLE IF NOT EXISTS custodian.balances (
    balance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id VARCHAR(100) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    available_balance DECIMAL(24, 8) NOT NULL DEFAULT 0,
    locked_balance DECIMAL(24, 8) NOT NULL DEFAULT 0,
    total_balance DECIMAL(24, 8) NOT NULL DEFAULT 0,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB,

    CONSTRAINT positive_available_balance CHECK (available_balance >= 0),
    CONSTRAINT positive_locked_balance CHECK (locked_balance >= 0),
    CONSTRAINT total_equals_sum CHECK (total_balance = available_balance + locked_balance),
    CONSTRAINT unique_account_currency UNIQUE (account_id, currency)
);

CREATE INDEX idx_balances_account ON custodian.balances(account_id);
CREATE INDEX idx_balances_currency ON custodian.balances(currency);
CREATE INDEX idx_balances_updated ON custodian.balances(last_updated);

-- Create custodian_adapter database user
CREATE USER custodian_adapter WITH PASSWORD 'custodian-adapter-db-pass';

-- Grant schema permissions
GRANT USAGE ON SCHEMA custodian TO custodian_adapter;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA custodian TO custodian_adapter;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA custodian TO custodian_adapter;

-- Grant connect permission
GRANT CONNECT ON DATABASE trading_ecosystem TO custodian_adapter;

-- Ensure default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA custodian GRANT ALL PRIVILEGES ON TABLES TO custodian_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA custodian GRANT ALL PRIVILEGES ON SEQUENCES TO custodian_adapter;

-- Create health check function for custodian schema
CREATE OR REPLACE FUNCTION custodian.health_check()
RETURNS TABLE(schema_name TEXT, table_count BIGINT, status TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        'custodian'::TEXT,
        COUNT(*)::BIGINT,
        'healthy'::TEXT
    FROM information_schema.tables
    WHERE table_schema = 'custodian';
END;
$$ LANGUAGE plpgsql;

-- Grant execute on health check function
GRANT EXECUTE ON FUNCTION custodian.health_check() TO custodian_adapter;

COMMENT ON SCHEMA custodian IS 'Custodian domain: positions, settlements, balances';
COMMENT ON TABLE custodian.positions IS 'Asset positions held in custody';
COMMENT ON TABLE custodian.settlements IS 'Settlement instructions and tracking';
COMMENT ON TABLE custodian.balances IS 'Account balance tracking with locked/available split';
