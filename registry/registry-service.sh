#!/bin/sh

# Trading Ecosystem Service Registry
# Lightweight service discovery and configuration service

set -e

echo "Starting Trading Ecosystem Service Registry..."

# Install required packages
apk add --no-cache curl jq redis postgresql-client python3 py3-pip

# Install prometheus_client via pip
pip3 install --break-system-packages prometheus-client

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

# Application services
redis-cli -h 172.20.0.10 -p 6379 --no-auth-warning -u "redis://registry:registry-pass@172.20.0.10:6379" HSET "registry:services:audit-correlator" \
    "name" "audit-correlator" \
    "host" "172.20.0.80" \
    "http_port" "8083" \
    "grpc_port" "9093" \
    "type" "service" \
    "status" "healthy" \
    "updated_at" "$(date -Iseconds)"

redis-cli -h 172.20.0.10 -p 6379 --no-auth-warning -u "redis://registry:registry-pass@172.20.0.10:6379" HSET "registry:services:custodian-simulator" \
    "name" "custodian-simulator" \
    "host" "172.20.0.81" \
    "http_port" "8084" \
    "grpc_port" "9094" \
    "type" "service" \
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

# Python HTTP server for health checks and Prometheus metrics
cat > /tmp/health-server.py << 'EOF'
#!/usr/bin/env python3
import json
import http.server
import socketserver
from datetime import datetime
from prometheus_client import Counter, Gauge, CollectorRegistry, generate_latest

# Create Prometheus registry and metrics
registry = CollectorRegistry()

# Service registry metrics
service_registrations = Counter(
    'service_registry_registrations_total',
    'Total number of service registrations',
    ['service'],
    registry=registry
)

service_health_status = Gauge(
    'service_registry_health_status',
    'Service health status (1=healthy, 0=unhealthy)',
    ['service'],
    registry=registry
)

# Set initial health status for infrastructure services
service_health_status.labels(service='redis').set(1)
service_health_status.labels(service='postgres').set(1)
service_health_status.labels(service='service-registry').set(1)

# Count registrations (8 infrastructure + 2 application services from startup)
service_registrations.labels(service='infrastructure').inc(8)
service_registrations.labels(service='application').inc(2)

class HealthMetricsHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            response = {
                "status": "healthy",
                "timestamp": datetime.now().isoformat(),
                "services": ["redis", "postgres", "service-registry"]
            }
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
        elif self.path == '/metrics':
            metrics_output = generate_latest(registry)
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain; version=0.0.4; charset=utf-8')
            self.end_headers()
            self.wfile.write(metrics_output)
        else:
            self.send_response(404)
            self.end_headers()

with socketserver.TCPServer(("", 8080), HealthMetricsHandler) as httpd:
    print("Health check and metrics server listening on port 8080...")
    print("Endpoints: /health (JSON), /metrics (Prometheus)")
    httpd.serve_forever()
EOF

echo "Starting health check server on port 8080..."
exec python3 /tmp/health-server.py