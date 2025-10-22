-- Audit Correlator Schema
-- Tables for audit event management and correlation

-- Create the audit_correlator schema for backward compatibility
CREATE SCHEMA IF NOT EXISTS audit_correlator;
COMMENT ON SCHEMA audit_correlator IS 'Audit correlator domain - events, correlations, service discovery';

-- Grant permissions to audit_adapter user for audit_correlator schema
GRANT USAGE ON SCHEMA audit_correlator TO audit_adapter;
GRANT CREATE ON SCHEMA audit_correlator TO audit_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit_correlator GRANT ALL ON TABLES TO audit_adapter;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit_correlator GRANT ALL ON SEQUENCES TO audit_adapter;

-- Update audit_adapter search path to include audit_correlator
ALTER USER audit_adapter SET search_path = audit, audit_correlator, public;

-- Create audit events table
CREATE TABLE IF NOT EXISTS audit_correlator.audit_events (
    id VARCHAR(255) PRIMARY KEY,
    trace_id VARCHAR(255) NOT NULL,
    span_id VARCHAR(255),
    service_name VARCHAR(255) NOT NULL,
    event_type VARCHAR(255) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    duration BIGINT DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    metadata JSONB DEFAULT '{}',
    tags TEXT[] DEFAULT '{}',
    correlated_to TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_audit_events_trace_id ON audit_correlator.audit_events(trace_id);
CREATE INDEX IF NOT EXISTS idx_audit_events_service_name ON audit_correlator.audit_events(service_name);
CREATE INDEX IF NOT EXISTS idx_audit_events_event_type ON audit_correlator.audit_events(event_type);
CREATE INDEX IF NOT EXISTS idx_audit_events_timestamp ON audit_correlator.audit_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_audit_events_status ON audit_correlator.audit_events(status);
CREATE INDEX IF NOT EXISTS idx_audit_events_metadata ON audit_correlator.audit_events USING GIN(metadata);
CREATE INDEX IF NOT EXISTS idx_audit_events_tags ON audit_correlator.audit_events USING GIN(tags);

-- Create service registrations table (for service discovery via data adapter)
CREATE TABLE IF NOT EXISTS audit_correlator.service_registrations (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    version VARCHAR(255) NOT NULL,
    host VARCHAR(255) NOT NULL,
    grpc_port INTEGER NOT NULL,
    http_port INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'healthy',
    metadata JSONB DEFAULT '{}',
    last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for service discovery
CREATE INDEX IF NOT EXISTS idx_service_registrations_name ON audit_correlator.service_registrations(name);
CREATE INDEX IF NOT EXISTS idx_service_registrations_status ON audit_correlator.service_registrations(status);
CREATE INDEX IF NOT EXISTS idx_service_registrations_last_seen ON audit_correlator.service_registrations(last_seen);

-- Create audit correlations table
CREATE TABLE IF NOT EXISTS audit_correlator.audit_correlations (
    id VARCHAR(255) PRIMARY KEY,
    source_event_id VARCHAR(255) NOT NULL,
    target_event_id VARCHAR(255) NOT NULL,
    correlation_type VARCHAR(255) NOT NULL,
    confidence DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (source_event_id) REFERENCES audit_correlator.audit_events(id) ON DELETE CASCADE,
    FOREIGN KEY (target_event_id) REFERENCES audit_correlator.audit_events(id) ON DELETE CASCADE
);

-- Create indexes for correlations
CREATE INDEX IF NOT EXISTS idx_audit_correlations_source_event_id ON audit_correlator.audit_correlations(source_event_id);
CREATE INDEX IF NOT EXISTS idx_audit_correlations_target_event_id ON audit_correlator.audit_correlations(target_event_id);
CREATE INDEX IF NOT EXISTS idx_audit_correlations_type ON audit_correlator.audit_correlations(correlation_type);
CREATE INDEX IF NOT EXISTS idx_audit_correlations_confidence ON audit_correlator.audit_correlations(confidence);

-- Create service metrics table
CREATE TABLE IF NOT EXISTS audit_correlator.service_metrics (
    id SERIAL PRIMARY KEY,
    service_name VARCHAR(255) NOT NULL,
    instance_id VARCHAR(255) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    request_count BIGINT DEFAULT 0,
    error_count BIGINT DEFAULT 0,
    response_time_ms BIGINT DEFAULT 0,
    custom_metrics JSONB DEFAULT '{}'
);

-- Create indexes for metrics
CREATE INDEX IF NOT EXISTS idx_service_metrics_service_name ON audit_correlator.service_metrics(service_name);
CREATE INDEX IF NOT EXISTS idx_service_metrics_instance_id ON audit_correlator.service_metrics(instance_id);
CREATE INDEX IF NOT EXISTS idx_service_metrics_timestamp ON audit_correlator.service_metrics(timestamp);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION audit_correlator.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for audit_events table
CREATE TRIGGER trigger_audit_events_updated_at
    BEFORE UPDATE ON audit_correlator.audit_events
    FOR EACH ROW
    EXECUTE FUNCTION audit_correlator.update_updated_at_column();

-- Update health check function to include audit_correlator schema
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
                'trading', 'test_coordination', 'audit', 'audit_correlator'
            )
        )
    );
END;
$$ LANGUAGE plpgsql;

-- Grant permissions to monitor_user for audit_correlator schema
GRANT USAGE ON SCHEMA audit_correlator TO monitor_user;
GRANT SELECT ON ALL TABLES IN SCHEMA audit_correlator TO monitor_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit_correlator GRANT SELECT ON TABLES TO monitor_user;