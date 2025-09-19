-- Trading Ecosystem Database Initialization
-- PostgreSQL 17 with SQL:2023 compliance
-- Creates schema namespaces for domain-driven data adapters

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- Market Data Schema
CREATE SCHEMA IF NOT EXISTS market_data;
COMMENT ON SCHEMA market_data IS 'Market data adapter domain - price feeds, OHLCV, scenarios';

-- Exchange Schema
CREATE SCHEMA IF NOT EXISTS exchange;
COMMENT ON SCHEMA exchange IS 'Exchange adapter domain - accounts, orders, trades';

-- Custodian Schema
CREATE SCHEMA IF NOT EXISTS custodian;
COMMENT ON SCHEMA custodian IS 'Custodian adapter domain - custody, settlements, transfers';

-- Risk Management Schema
CREATE SCHEMA IF NOT EXISTS risk;
COMMENT ON SCHEMA risk IS 'Risk adapter domain - monitoring, limits, alerts';

-- Trading Engine Schema
CREATE SCHEMA IF NOT EXISTS trading;
COMMENT ON SCHEMA trading IS 'Trading adapter domain - strategies, portfolio, performance';

-- Test Coordination Schema
CREATE SCHEMA IF NOT EXISTS test_coordination;
COMMENT ON SCHEMA test_coordination IS 'Test coordinator adapter domain - scenarios, execution, validation';

-- Audit Schema
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS 'Audit adapter domain - events, correlation, compliance';

-- Create dedicated users for each adapter with schema-specific permissions
-- Market Data Adapter User
CREATE USER market_adapter WITH PASSWORD 'market-adapter-db-pass';
GRANT USAGE ON SCHEMA market_data TO market_adapter;
GRANT CREATE ON SCHEMA market_data TO market_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA market_data GRANT ALL ON TABLES TO market_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA market_data GRANT ALL ON SEQUENCES TO market_adapter;

-- Exchange Adapter User
CREATE USER exchange_adapter WITH PASSWORD 'exchange-adapter-db-pass';
GRANT USAGE ON SCHEMA exchange TO exchange_adapter;
GRANT CREATE ON SCHEMA exchange TO exchange_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA exchange GRANT ALL ON TABLES TO exchange_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA exchange GRANT ALL ON SEQUENCES TO exchange_adapter;

-- Custodian Adapter User
CREATE USER custodian_adapter WITH PASSWORD 'custodian-adapter-db-pass';
GRANT USAGE ON SCHEMA custodian TO custodian_adapter;
GRANT CREATE ON SCHEMA custodian TO custodian_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA custodian GRANT ALL ON TABLES TO custodian_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA custodian GRANT ALL ON SEQUENCES TO custodian_adapter;

-- Risk Adapter User
CREATE USER risk_adapter WITH PASSWORD 'risk-adapter-db-pass';
GRANT USAGE ON SCHEMA risk TO risk_adapter;
GRANT CREATE ON SCHEMA risk TO risk_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA risk GRANT ALL ON TABLES TO risk_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA risk GRANT ALL ON SEQUENCES TO risk_adapter;

-- Trading Adapter User
CREATE USER trading_adapter WITH PASSWORD 'trading-adapter-db-pass';
GRANT USAGE ON SCHEMA trading TO trading_adapter;
GRANT CREATE ON SCHEMA trading TO trading_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA trading GRANT ALL ON TABLES TO trading_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA trading GRANT ALL ON SEQUENCES TO trading_adapter;

-- Test Coordination Adapter User
CREATE USER test_coordinator_adapter WITH PASSWORD 'test-coordinator-adapter-db-pass';
GRANT USAGE ON SCHEMA test_coordination TO test_coordinator_adapter;
GRANT CREATE ON SCHEMA test_coordination TO test_coordinator_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA test_coordination GRANT ALL ON TABLES TO test_coordinator_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA test_coordination GRANT ALL ON SEQUENCES TO test_coordinator_adapter;

-- Audit Adapter User
CREATE USER audit_adapter WITH PASSWORD 'audit-adapter-db-pass';
GRANT USAGE ON SCHEMA audit TO audit_adapter;
GRANT CREATE ON SCHEMA audit TO audit_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit GRANT ALL ON TABLES TO audit_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit GRANT ALL ON SEQUENCES TO audit_adapter;

-- Create shared monitoring user (read-only across all schemas)
CREATE USER monitor_user WITH PASSWORD 'monitor-db-pass';
GRANT USAGE ON SCHEMA market_data, exchange, custodian, risk, trading, test_coordination, audit TO monitor_user;
GRANT SELECT ON ALL TABLES IN SCHEMA market_data, exchange, custodian, risk, trading, test_coordination, audit TO monitor_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA market_data, exchange, custodian, risk, trading, test_coordination, audit GRANT SELECT ON TABLES TO monitor_user;

-- Set search paths for each adapter user
ALTER USER market_adapter SET search_path = market_data, public;
ALTER USER exchange_adapter SET search_path = exchange, public;
ALTER USER custodian_adapter SET search_path = custodian, public;
ALTER USER risk_adapter SET search_path = risk, public;
ALTER USER trading_adapter SET search_path = trading, public;
ALTER USER test_coordinator_adapter SET search_path = test_coordination, public;
ALTER USER audit_adapter SET search_path = audit, public;

-- Create health check function
CREATE OR REPLACE FUNCTION public.health_check()
RETURNS jsonb AS $$
BEGIN
    RETURN jsonb_build_object(
        'status', 'healthy',
        'timestamp', now(),
        'version', version(),
        'schemas', (
            SELECT jsonb_agg(schema_name)
            FROM information_schema.schemata
            WHERE schema_name IN (
                'market_data', 'exchange', 'custodian', 'risk',
                'trading', 'test_coordination', 'audit'
            )
        )
    );
END;
$$ LANGUAGE plpgsql;