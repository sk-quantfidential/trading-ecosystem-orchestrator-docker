#!/bin/sh

# Trading Ecosystem Service Registry
# Lightweight service discovery and configuration service

set -e

echo "Starting Trading Ecosystem Service Registry..."

# Install required packages
apk add --no-cache curl jq redis postgresql-client

# Wait for dependencies
echo "Waiting for Redis..."
until redis-cli -h 172.20.0.10 -p 6379 --no-auth-warning -u "redis://registry:registry-pass@172.20.0.10:6379" ping > /dev/null 2>&1; do
    echo "Redis not ready, waiting..."
    sleep 2
done
echo "Redis is ready!"

echo "Waiting for PostgreSQL..."
until pg_isready -h 172.20.0.20 -p 5432 -U postgres -d trading_ecosystem > /dev/null 2>&1; do
    echo "PostgreSQL not ready, waiting..."
    sleep 2
done
echo "PostgreSQL is ready!"

# Register service endpoints in Redis
echo "Registering service endpoints..."

# Infrastructure services
redis-cli -h 172.20.0.10 -p 6379 --no-auth-warning -u "redis://registry:registry-pass@172.20.0.10:6379" HSET "registry:services:redis" \
    "name" "redis" \
    "host" "172.20.0.10" \
    "port" "6379" \
    "status" "healthy" \
    "updated_at" "$(date -Iseconds)"

redis-cli -h 172.20.0.10 -p 6379 --no-auth-warning -u "redis://registry:registry-pass@172.20.0.10:6379" HSET "registry:services:postgres" \
    "name" "postgres" \
    "host" "172.20.0.20" \
    "port" "5432" \
    "status" "healthy" \
    "updated_at" "$(date -Iseconds)"

redis-cli -h 172.20.0.10 -p 6379 --no-auth-warning -u "redis://registry:registry-pass@172.20.0.10:6379" HSET "registry:services:service-registry" \
    "name" "service-registry" \
    "host" "172.20.0.30" \
    "port" "8080" \
    "status" "healthy" \
    "updated_at" "$(date -Iseconds)"

redis-cli -h 172.20.0.10 -p 6379 --no-auth-warning -u "redis://registry:registry-pass@172.20.0.10:6379" HSET "registry:services:prometheus" \
    "name" "prometheus" \
    "host" "172.20.0.40" \
    "port" "9090" \
    "type" "metrics" \
    "status" "healthy" \
    "updated_at" "$(date -Iseconds)"

redis-cli -h 172.20.0.10 -p 6379 --no-auth-warning -u "redis://registry:registry-pass@172.20.0.10:6379" HSET "registry:services:grafana" \
    "name" "grafana" \
    "host" "172.20.0.50" \
    "port" "3000" \
    "type" "dashboard" \
    "status" "healthy" \
    "updated_at" "$(date -Iseconds)"

redis-cli -h 172.20.0.10 -p 6379 --no-auth-warning -u "redis://registry:registry-pass@172.20.0.10:6379" HSET "registry:services:jaeger" \
    "name" "jaeger" \
    "host" "172.20.0.60" \
    "port" "16686" \
    "collector_port" "14268" \
    "grpc_port" "14250" \
    "admin_port" "14269" \
    "type" "tracing" \
    "status" "healthy" \
    "updated_at" "$(date -Iseconds)"

redis-cli -h 172.20.0.10 -p 6379 --no-auth-warning -u "redis://registry:registry-pass@172.20.0.10:6379" HSET "registry:services:otel-collector" \
    "name" "otel-collector" \
    "host" "172.20.0.70" \
    "port" "13133" \
    "otlp_grpc_port" "4317" \
    "otlp_http_port" "4318" \
    "metrics_port" "8888" \
    "prometheus_port" "8889" \
    "type" "telemetry" \
    "status" "healthy" \
    "updated_at" "$(date -Iseconds)"

# Set service discovery configuration
redis-cli -h 172.20.0.10 -p 6379 --no-auth-warning -u "redis://registry:registry-pass@172.20.0.10:6379" HSET "config:infrastructure" \
    "redis_host" "172.20.0.10" \
    "redis_port" "6379" \
    "postgres_host" "172.20.0.20" \
    "postgres_port" "5432" \
    "postgres_db" "trading_ecosystem" \
    "network_subnet" "172.20.0.0/16"

echo "Service registry configuration completed!"

# Simple HTTP health check server
cat > /tmp/health-server.sh << 'EOF'
#!/bin/sh
while true; do
    printf "HTTP/1.1 200 OK\r\n\r\n{\"status\":\"healthy\",\"timestamp\":\"$(date -Iseconds)\",\"services\":[\"redis\",\"postgres\",\"service-registry\"]}" | nc -l -p 8080
done
EOF

chmod +x /tmp/health-server.sh

echo "Starting health check server on port 8080..."
exec /tmp/health-server.sh