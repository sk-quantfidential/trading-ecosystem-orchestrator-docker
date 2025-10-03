-- =====================================================
-- Trading Schema - Trading System Engine Data Adapter
-- =====================================================
-- Purpose: Stores trading strategies, orders, trades, and positions
-- Owner: trading_adapter user
-- Epic: TSE-0001.4 Data Adapters and Orchestrator Integration

-- Create trading schema if not exists
CREATE SCHEMA IF NOT EXISTS trading;

-- =====================================================
-- TYPES
-- =====================================================

-- Strategy status enumeration
CREATE TYPE trading.strategy_status AS ENUM (
    'inactive',
    'active',
    'paused',
    'stopped',
    'error'
);

-- Strategy type enumeration
CREATE TYPE trading.strategy_type AS ENUM (
    'market_making',
    'trend_following',
    'mean_reversion',
    'arbitrage',
    'momentum',
    'custom'
);

-- Order side enumeration
CREATE TYPE trading.order_side AS ENUM (
    'buy',
    'sell'
);

-- Order type enumeration
CREATE TYPE trading.order_type AS ENUM (
    'market',
    'limit',
    'stop_loss',
    'stop_limit',
    'trailing_stop'
);

-- Order status enumeration
CREATE TYPE trading.order_status AS ENUM (
    'pending',
    'submitted',
    'accepted',
    'partially_filled',
    'filled',
    'cancelled',
    'rejected',
    'expired'
);

-- Trade side enumeration
CREATE TYPE trading.trade_side AS ENUM (
    'buy',
    'sell'
);

-- =====================================================
-- TABLES
-- =====================================================

-- Strategies table
CREATE TABLE IF NOT EXISTS trading.strategies (
    strategy_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    strategy_type trading.strategy_type NOT NULL,
    status trading.strategy_status NOT NULL DEFAULT 'inactive',
    parameters JSONB DEFAULT '{}',
    instruments TEXT[] DEFAULT '{}',
    max_position_size DECIMAL(20, 8),
    total_pnl DECIMAL(20, 8) DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version INTEGER NOT NULL DEFAULT 1
);

-- Orders table
CREATE TABLE IF NOT EXISTS trading.orders (
    order_id TEXT PRIMARY KEY,
    strategy_id TEXT NOT NULL REFERENCES trading.strategies(strategy_id) ON DELETE CASCADE,
    instrument_id TEXT NOT NULL,
    side trading.order_side NOT NULL,
    order_type trading.order_type NOT NULL,
    status trading.order_status NOT NULL DEFAULT 'pending',
    quantity DECIMAL(20, 8) NOT NULL,
    filled_quantity DECIMAL(20, 8) DEFAULT 0,
    price DECIMAL(20, 8),
    average_fill_price DECIMAL(20, 8),
    exchange_order_id TEXT,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    submitted_at TIMESTAMPTZ,
    filled_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ
);

-- Trades table
CREATE TABLE IF NOT EXISTS trading.trades (
    trade_id TEXT PRIMARY KEY,
    order_id TEXT NOT NULL REFERENCES trading.orders(order_id) ON DELETE CASCADE,
    strategy_id TEXT NOT NULL REFERENCES trading.strategies(strategy_id) ON DELETE CASCADE,
    instrument_id TEXT NOT NULL,
    side trading.trade_side NOT NULL,
    quantity DECIMAL(20, 8) NOT NULL,
    price DECIMAL(20, 8) NOT NULL,
    gross_value DECIMAL(20, 8) NOT NULL,
    commission DECIMAL(20, 8) DEFAULT 0,
    net_value DECIMAL(20, 8) NOT NULL,
    realized_pnl DECIMAL(20, 8),
    exchange_trade_id TEXT,
    executed_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Positions table
CREATE TABLE IF NOT EXISTS trading.positions (
    position_id TEXT PRIMARY KEY,
    strategy_id TEXT NOT NULL REFERENCES trading.strategies(strategy_id) ON DELETE CASCADE,
    instrument_id TEXT NOT NULL,
    quantity DECIMAL(20, 8) NOT NULL,
    average_entry_price DECIMAL(20, 8) NOT NULL,
    current_price DECIMAL(20, 8) NOT NULL,
    market_value DECIMAL(20, 8) NOT NULL,
    unrealized_pnl DECIMAL(20, 8) NOT NULL,
    realized_pnl DECIMAL(20, 8) DEFAULT 0,
    total_pnl DECIMAL(20, 8) NOT NULL,
    exposure DECIMAL(20, 8) NOT NULL,
    opened_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (strategy_id, instrument_id)
);

-- =====================================================
-- INDEXES
-- =====================================================

-- Strategy indexes
CREATE INDEX IF NOT EXISTS idx_strategies_status ON trading.strategies(status);
CREATE INDEX IF NOT EXISTS idx_strategies_type ON trading.strategies(strategy_type);
CREATE INDEX IF NOT EXISTS idx_strategies_created_at ON trading.strategies(created_at);

-- Order indexes
CREATE INDEX IF NOT EXISTS idx_orders_strategy_id ON trading.orders(strategy_id);
CREATE INDEX IF NOT EXISTS idx_orders_instrument_id ON trading.orders(instrument_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON trading.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON trading.orders(created_at);
CREATE INDEX IF NOT EXISTS idx_orders_exchange_order_id ON trading.orders(exchange_order_id) WHERE exchange_order_id IS NOT NULL;

-- Trade indexes
CREATE INDEX IF NOT EXISTS idx_trades_order_id ON trading.trades(order_id);
CREATE INDEX IF NOT EXISTS idx_trades_strategy_id ON trading.trades(strategy_id);
CREATE INDEX IF NOT EXISTS idx_trades_instrument_id ON trading.trades(instrument_id);
CREATE INDEX IF NOT EXISTS idx_trades_executed_at ON trading.trades(executed_at);

-- Position indexes
CREATE INDEX IF NOT EXISTS idx_positions_strategy_id ON trading.positions(strategy_id);
CREATE INDEX IF NOT EXISTS idx_positions_instrument_id ON trading.positions(instrument_id);
CREATE INDEX IF NOT EXISTS idx_positions_quantity ON trading.positions(quantity) WHERE quantity != 0;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Update updated_at timestamp function
CREATE OR REPLACE FUNCTION trading.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_strategies_updated_at
    BEFORE UPDATE ON trading.strategies
    FOR EACH ROW
    EXECUTE FUNCTION trading.update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON trading.orders
    FOR EACH ROW
    EXECUTE FUNCTION trading.update_updated_at_column();

CREATE TRIGGER update_positions_updated_at
    BEFORE UPDATE ON trading.positions
    FOR EACH ROW
    EXECUTE FUNCTION trading.update_updated_at_column();

-- =====================================================
-- HEALTH CHECK FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION trading.health_check()
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'schema', 'trading',
        'status', 'healthy',
        'tables', json_build_object(
            'strategies', (SELECT COUNT(*) FROM trading.strategies),
            'orders', (SELECT COUNT(*) FROM trading.orders),
            'trades', (SELECT COUNT(*) FROM trading.trades),
            'positions', (SELECT COUNT(*) FROM trading.positions)
        ),
        'timestamp', CURRENT_TIMESTAMP
    ) INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant schema usage
GRANT USAGE ON SCHEMA trading TO trading_adapter;

-- Grant table permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA trading TO trading_adapter;

-- Grant sequence permissions (if any added later)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA trading TO trading_adapter;

-- Grant type permissions
GRANT USAGE ON TYPE trading.strategy_status TO trading_adapter;
GRANT USAGE ON TYPE trading.strategy_type TO trading_adapter;
GRANT USAGE ON TYPE trading.order_side TO trading_adapter;
GRANT USAGE ON TYPE trading.order_type TO trading_adapter;
GRANT USAGE ON TYPE trading.order_status TO trading_adapter;
GRANT USAGE ON TYPE trading.trade_side TO trading_adapter;

-- Grant execute on functions
GRANT EXECUTE ON FUNCTION trading.health_check() TO trading_adapter;
GRANT EXECUTE ON FUNCTION trading.update_updated_at_column() TO trading_adapter;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA trading GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO trading_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA trading GRANT USAGE, SELECT ON SEQUENCES TO trading_adapter;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON SCHEMA trading IS 'Trading system data - strategies, orders, trades, positions';
COMMENT ON TABLE trading.strategies IS 'Trading strategy definitions and parameters';
COMMENT ON TABLE trading.orders IS 'Order lifecycle tracking from submission to fill';
COMMENT ON TABLE trading.trades IS 'Executed trades with fill information';
COMMENT ON TABLE trading.positions IS 'Aggregated positions with P&L calculation';
COMMENT ON FUNCTION trading.health_check() IS 'Health check function returning schema status and table counts';
