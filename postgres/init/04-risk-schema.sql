-- Risk Management Schema
-- Tables for risk monitoring, alerts, limits, and position tracking

-- Risk Metrics Table (Time-series risk calculations)
CREATE TABLE IF NOT EXISTS risk.metrics (
    metric_id VARCHAR(255) PRIMARY KEY,
    instrument_id VARCHAR(255) NOT NULL,
    account_id VARCHAR(255),

    -- Core metrics
    portfolio_value DECIMAL(20, 8) NOT NULL,
    unrealized_pnl DECIMAL(20, 8) NOT NULL,
    realized_pnl DECIMAL(20, 8) NOT NULL,
    total_exposure DECIMAL(20, 8) NOT NULL,
    leverage_ratio DECIMAL(10, 4) NOT NULL,

    -- Risk metrics
    var_95 DECIMAL(20, 8) NOT NULL,
    var_99 DECIMAL(20, 8),
    expected_shortfall DECIMAL(20, 8),

    -- Calculation metadata
    calculation_timestamp TIMESTAMPTZ NOT NULL,
    lookback_days INTEGER NOT NULL DEFAULT 30,
    confidence_level DECIMAL(5, 4) NOT NULL DEFAULT 0.95,

    -- Audit fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for efficient time-series queries
CREATE INDEX IF NOT EXISTS idx_risk_metrics_instrument_id ON risk.metrics(instrument_id);
CREATE INDEX IF NOT EXISTS idx_risk_metrics_account_id ON risk.metrics(account_id);
CREATE INDEX IF NOT EXISTS idx_risk_metrics_calculation_timestamp ON risk.metrics(calculation_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_risk_metrics_instrument_timestamp ON risk.metrics(instrument_id, calculation_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_risk_metrics_var_95 ON risk.metrics(var_95);

COMMENT ON TABLE risk.metrics IS 'Time-series risk metric calculations with VaR and P&L tracking';


-- Risk Alerts Table (Alert management with status tracking)
CREATE TABLE IF NOT EXISTS risk.alerts (
    alert_id VARCHAR(255) PRIMARY KEY,
    severity VARCHAR(50) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    status VARCHAR(50) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'acknowledged', 'resolved', 'expired')),

    -- Alert details
    metric_name VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    current_value DECIMAL(20, 8) NOT NULL,
    threshold_value DECIMAL(20, 8) NOT NULL,

    -- Context
    instrument_id VARCHAR(255),
    account_id VARCHAR(255),

    -- Lifecycle timestamps
    triggered_at TIMESTAMPTZ NOT NULL,
    acknowledged_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,

    -- Audit fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for alert queries
CREATE INDEX IF NOT EXISTS idx_risk_alerts_severity ON risk.alerts(severity);
CREATE INDEX IF NOT EXISTS idx_risk_alerts_status ON risk.alerts(status);
CREATE INDEX IF NOT EXISTS idx_risk_alerts_metric_name ON risk.alerts(metric_name);
CREATE INDEX IF NOT EXISTS idx_risk_alerts_instrument_id ON risk.alerts(instrument_id);
CREATE INDEX IF NOT EXISTS idx_risk_alerts_account_id ON risk.alerts(account_id);
CREATE INDEX IF NOT EXISTS idx_risk_alerts_triggered_at ON risk.alerts(triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_risk_alerts_status_severity ON risk.alerts(status, severity);

COMMENT ON TABLE risk.alerts IS 'Risk breach alerts with lifecycle management and status tracking';


-- Risk Limits Table (Risk limit configurations with versioning)
CREATE TABLE IF NOT EXISTS risk.limits (
    limit_id VARCHAR(255) PRIMARY KEY,
    limit_type VARCHAR(50) NOT NULL CHECK (limit_type IN ('position_size', 'leverage', 'var', 'daily_loss', 'total_exposure')),

    -- Limit value
    threshold_value DECIMAL(20, 8) NOT NULL,
    warning_value DECIMAL(20, 8),

    -- Scope
    instrument_id VARCHAR(255),
    account_id VARCHAR(255),
    global_limit BOOLEAN NOT NULL DEFAULT FALSE,

    -- Configuration
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    version INTEGER NOT NULL DEFAULT 1,

    -- Metadata
    description TEXT,

    -- Audit fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for limit queries
CREATE INDEX IF NOT EXISTS idx_risk_limits_limit_type ON risk.limits(limit_type);
CREATE INDEX IF NOT EXISTS idx_risk_limits_instrument_id ON risk.limits(instrument_id);
CREATE INDEX IF NOT EXISTS idx_risk_limits_account_id ON risk.limits(account_id);
CREATE INDEX IF NOT EXISTS idx_risk_limits_enabled ON risk.limits(enabled);
CREATE INDEX IF NOT EXISTS idx_risk_limits_global ON risk.limits(global_limit);
CREATE INDEX IF NOT EXISTS idx_risk_limits_type_enabled ON risk.limits(limit_type, enabled);

COMMENT ON TABLE risk.limits IS 'Risk limit configurations with versioning for audit trail';


-- Position Snapshots Table (Point-in-time position data)
CREATE TABLE IF NOT EXISTS risk.position_snapshots (
    snapshot_id VARCHAR(255) PRIMARY KEY,
    instrument_id VARCHAR(255) NOT NULL,
    account_id VARCHAR(255) NOT NULL,

    -- Position details
    quantity DECIMAL(20, 8) NOT NULL,
    market_value DECIMAL(20, 8) NOT NULL,
    average_entry_price DECIMAL(20, 8) NOT NULL,
    current_price DECIMAL(20, 8) NOT NULL,

    -- P&L
    unrealized_pnl DECIMAL(20, 8) NOT NULL,
    realized_pnl DECIMAL(20, 8) NOT NULL,

    -- Source metadata
    source VARCHAR(255) NOT NULL,
    venue VARCHAR(255),

    -- Snapshot timing
    snapshot_timestamp TIMESTAMPTZ NOT NULL,

    -- Audit field
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for position snapshot queries
CREATE INDEX IF NOT EXISTS idx_position_snapshots_instrument_id ON risk.position_snapshots(instrument_id);
CREATE INDEX IF NOT EXISTS idx_position_snapshots_account_id ON risk.position_snapshots(account_id);
CREATE INDEX IF NOT EXISTS idx_position_snapshots_source ON risk.position_snapshots(source);
CREATE INDEX IF NOT EXISTS idx_position_snapshots_timestamp ON risk.position_snapshots(snapshot_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_position_snapshots_instrument_timestamp ON risk.position_snapshots(instrument_id, snapshot_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_position_snapshots_account_timestamp ON risk.position_snapshots(account_id, snapshot_timestamp DESC);

COMMENT ON TABLE risk.position_snapshots IS 'Point-in-time position snapshots from production APIs for historical tracking';


-- Create updated_at trigger function for risk schema
CREATE OR REPLACE FUNCTION risk.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers
CREATE TRIGGER update_risk_metrics_updated_at
    BEFORE UPDATE ON risk.metrics
    FOR EACH ROW
    EXECUTE FUNCTION risk.update_updated_at_column();

CREATE TRIGGER update_risk_alerts_updated_at
    BEFORE UPDATE ON risk.alerts
    FOR EACH ROW
    EXECUTE FUNCTION risk.update_updated_at_column();

CREATE TRIGGER update_risk_limits_updated_at
    BEFORE UPDATE ON risk.limits
    FOR EACH ROW
    EXECUTE FUNCTION risk.update_updated_at_column();


-- Grant permissions to risk_adapter user (created in 01-init-schemas.sql)
GRANT ALL ON ALL TABLES IN SCHEMA risk TO risk_adapter;
GRANT ALL ON ALL SEQUENCES IN SCHEMA risk TO risk_adapter;

-- Create health check function for risk schema
CREATE OR REPLACE FUNCTION risk.health_check()
RETURNS jsonb AS $$
BEGIN
    RETURN jsonb_build_object(
        'status', 'healthy',
        'timestamp', now(),
        'schema', 'risk',
        'tables', (
            SELECT jsonb_agg(tablename)
            FROM pg_tables
            WHERE schemaname = 'risk'
        ),
        'metrics_count', (SELECT COUNT(*) FROM risk.metrics),
        'alerts_count', (SELECT COUNT(*) FROM risk.alerts),
        'limits_count', (SELECT COUNT(*) FROM risk.limits),
        'snapshots_count', (SELECT COUNT(*) FROM risk.position_snapshots)
    );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION risk.health_check() IS 'Health check for risk schema with table statistics';
