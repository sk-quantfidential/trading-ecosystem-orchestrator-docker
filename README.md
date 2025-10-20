# Trading Ecosystem - Core Infrastructure

This directory contains the complete infrastructure deployment for the Trading Ecosystem, implementing **TSE-0001.3a: Core Infrastructure Setup** with enhanced observability capabilities.

## 🎯 Overview

This repository provides the foundational infrastructure for the Trading Ecosystem, establishing shared data services and a comprehensive observability stack. All future microservices will connect to this infrastructure for service discovery, data persistence, and telemetry.

### Infrastructure Components
- **Redis**: Service discovery, caching, and real-time data storage
- **PostgreSQL**: Persistent data storage with domain-specific schemas
- **Service Registry**: Lightweight service discovery and configuration API
- **Prometheus**: Metrics collection and monitoring
- **Grafana**: Visualization dashboards and alerting
- **Jaeger**: Distributed tracing and performance monitoring
- **OpenTelemetry Collector**: Telemetry aggregation and routing

### Future Services (TSE-0001.3b+)
- **Exchange Simulator** (Go): Crypto exchange with order matching and chaos injection
- **Custodian Simulator** (Go): Settlement and custody operations with multi-day cycles
- **Market Data Simulator** (Go): Real market data feeds with controlled price manipulation
- **Trading Strategy Engine** (Python): Algorithmic trading with misbehaving strategy chaos testing
- **Risk Monitor** (Python): Production-authentic risk surveillance and compliance alerting
- **Test Coordinator** (Python): Chaos scenario orchestration and validation framework
- **Audit Correlator** (Go): Independent system validation and event correlation

## 🚀 Quick Start

### Prerequisites
- Docker 24.0+ (with Compose plugin)
- Docker Compose V2 (modern `docker compose` command)
- 4GB RAM minimum (8GB recommended for full observability stack)
- Available ports: 3000, 5432, 6379, 8080, 9090, 16686, 4317, 4318

> **Note**: This project uses the modern `docker compose` command (with space) instead of the deprecated `docker-compose` (with hyphen). If you're using an older Docker installation, please upgrade to Docker 24.0+ which includes Compose V2.

### One-Command Deployment
```bash
# Start all infrastructure services
./scripts/manage-infrastructure.sh start

# Validate deployment
./scripts/manage-infrastructure.sh validate

# Stop all services
./scripts/manage-infrastructure.sh stop
```

### Alternative: Direct Docker Compose
```bash
# Start all infrastructure services
docker compose up -d

# Validate deployment
./scripts/validate-infrastructure.sh

# Stop all services
docker compose down
```

### Access Points
After successful deployment:
- **Service Registry Health**: http://localhost:8080/health
- **Grafana Dashboards**: http://localhost:3000 (admin/admin)
- **Prometheus Metrics**: http://localhost:9090
- **Jaeger Tracing**: http://localhost:16686
- **OpenTelemetry Collector**: http://localhost:13133
- **Redis**: redis://localhost:6379
- **PostgreSQL**: postgresql://localhost:5432/trading_ecosystem

## 🔧 Service Management

### Infrastructure Management Script

For simplified operations, use the infrastructure management utility:

```bash
# Available commands
./scripts/manage-infrastructure.sh <command>

# Common operations
./scripts/manage-infrastructure.sh start      # Start all services
./scripts/manage-infrastructure.sh stop       # Stop all services (keep volumes)
./scripts/manage-infrastructure.sh restart    # Restart all services
./scripts/manage-infrastructure.sh clean      # Complete cleanup (remove volumes)
./scripts/manage-infrastructure.sh status     # Show service status
./scripts/manage-infrastructure.sh validate   # Run health validation
./scripts/manage-infrastructure.sh logs       # Show all logs
./scripts/manage-infrastructure.sh logs redis # Show specific service logs
./scripts/manage-infrastructure.sh health     # Quick health check
./scripts/manage-infrastructure.sh help       # Show help
```

### Manual Docker Compose Operations

### Starting Services

```bash
# Start all services (recommended)
docker compose up -d

# Start specific services only
docker compose up -d redis postgres service-registry

# Start with logs visible (for debugging)
docker compose up

# Start infrastructure + observability
docker compose up -d redis postgres service-registry prometheus grafana

# Force recreate containers
docker compose up -d --force-recreate
```

### Stopping Services

```bash
# Stop all services (keeps volumes)
docker compose down

# Stop and remove volumes (complete cleanup)
docker compose down -v

# Stop specific service
docker compose stop redis

# Stop and remove specific service container
docker compose rm -f redis
```

### Service Status & Health Checks

```bash
# Check service status
docker compose ps

# Validate all services are healthy
./scripts/validate-infrastructure.sh

# Check individual service health
curl http://localhost:8080/health      # Service Registry
curl http://localhost:9090/-/healthy   # Prometheus
curl http://localhost:3000/api/health  # Grafana
curl http://localhost:16686/           # Jaeger (returns HTML)
curl http://localhost:13133/           # OpenTelemetry Collector

# Check Redis connectivity
redis-cli -h localhost -p 6379 --no-auth-warning -u "redis://healthcheck:health-pass@localhost:6379" ping

# Check PostgreSQL connectivity
pg_isready -h localhost -p 5432 -U postgres -d trading_ecosystem
```

### Viewing Logs

```bash
# View all service logs
docker compose logs

# Follow logs in real-time
docker compose logs -f

# View specific service logs
docker compose logs redis
docker compose logs postgres
docker compose logs service-registry
docker compose logs prometheus
docker compose logs grafana
docker compose logs jaeger
docker compose logs otel-collector

# Follow specific service logs
docker compose logs -f grafana

# View recent logs with timestamps
docker compose logs -t --tail=100
```

### Service Operations

```bash
# Restart specific service
docker compose restart redis

# Restart all services
docker compose restart

# Scale services (if needed)
docker compose up -d --scale service-registry=2

# Update service configuration
# 1. Edit configuration files
# 2. Restart affected services
docker compose restart prometheus  # After editing prometheus.yml

# Execute commands in running containers
docker compose exec redis redis-cli
docker compose exec postgres psql -U postgres -d trading_ecosystem
docker compose exec service-registry sh

# View resource usage
docker stats $(docker compose ps -q)
```

### Validation & Troubleshooting

```bash
# Complete infrastructure validation
./scripts/validate-infrastructure.sh

# Manual health checks
curl -f http://localhost:8080/health && echo "✅ Service Registry OK"
curl -f http://localhost:9090/-/healthy && echo "✅ Prometheus OK"
curl -f http://localhost:3000/api/health && echo "✅ Grafana OK"
curl -f http://localhost:13133/ && echo "✅ OpenTelemetry Collector OK"

# Check Docker Compose configuration
docker compose config

# Validate network connectivity between services
docker compose exec service-registry ping redis
docker compose exec service-registry ping postgres

# Check service discovery
redis-cli -h localhost -p 6379 --no-auth-warning -u "redis://healthcheck:health-pass@localhost:6379" KEYS "registry:services:*"

# Check database schemas
docker compose exec postgres psql -U postgres -d trading_ecosystem -c "\dn"
```

### Common Issues & Solutions

```bash
# Port already in use
sudo lsof -i :6379  # Check what's using Redis port
sudo lsof -i :5432  # Check what's using PostgreSQL port

# Service won't start
docker compose logs <service-name>  # Check logs for errors
docker compose ps                   # Check service status

# Clear everything and restart
docker compose down -v             # Stop and remove volumes
docker system prune -f             # Clean up Docker
docker compose up -d               # Start fresh

# Redis connection issues
docker compose exec redis redis-cli ping  # Test from inside container

# PostgreSQL connection issues
docker compose exec postgres pg_isready -U postgres  # Test from inside container

# Health check failures
docker compose exec <service> wget --spider http://localhost:<port>/health
```

## 📁 Repository Structure

```
orchestrator-docker/
├── docker-compose.yml           # Main service orchestration
├── README.md                    # This file
├── scripts/
│   ├── manage-infrastructure.sh     # Infrastructure management utility
│   └── validate-infrastructure.sh  # Deployment validation script
├── redis/
│   ├── redis.conf              # Redis configuration
│   └── users.acl               # Redis ACL users
├── postgres/
│   ├── postgresql.conf         # PostgreSQL configuration
│   └── init/
│       └── 01-init-schemas.sql # Database initialization
├── registry/
│   └── registry-service.sh     # Service registry implementation
├── prometheus/
│   └── prometheus.yml          # Prometheus configuration
├── grafana/
│   └── provisioning/           # Grafana auto-provisioning
│       ├── datasources/
│       │   └── prometheus.yml  # Prometheus datasource config
│       └── dashboards/
│           └── default.yml     # Dashboard provider config
└── otel-collector/
    └── config.yaml            # OpenTelemetry Collector configuration
```

### Key Configuration Files

| File | Purpose | Key Features |
|------|---------|--------------|
| `docker-compose.yml` | Service orchestration | 7 services, health checks, networking (modern docker compose) |
| `scripts/manage-infrastructure.sh` | Infrastructure utility | Start, stop, validate, logs, status |
| `scripts/validate-infrastructure.sh` | Health validation | Automated testing of all services |
| `redis/redis.conf` | Redis configuration | ACL security, performance tuning |
| `redis/users.acl` | Redis ACL users | Domain-specific access control |
| `postgres/postgresql.conf` | PostgreSQL config | Performance optimization |
| `postgres/init/01-init-schemas.sql` | Database schemas | Domain separation |
| `prometheus/prometheus.yml` | Metrics collection | Service discovery targets |
| `grafana/provisioning/` | Dashboard setup | Auto-provisioned datasources |
| `otel-collector/config.yaml` | Telemetry routing | OTLP, Jaeger, Prometheus |

## 📊 Services & Endpoints

| Service | Container | Internal IP | External Port | Purpose | Health Check |
|---------|-----------|-------------|---------------|---------|--------------|
| **Redis** | `trading-ecosystem-redis` | 172.20.0.10 | 6379 | Service discovery, caching | `redis://healthcheck:health-pass@localhost:6379 PING` |
| **PostgreSQL** | `trading-ecosystem-postgres` | 172.20.0.20 | 5432 | Persistent data storage | `pg_isready -h localhost -p 5432` |
| **Service Registry** | `trading-ecosystem-registry` | 172.20.0.30 | 8080 | Service discovery API | `http://localhost:8080/health` |
| **Prometheus** | `trading-ecosystem-prometheus` | 172.20.0.40 | 9090 | Metrics collection | `http://localhost:9090/-/healthy` |
| **Grafana** | `trading-ecosystem-grafana` | 172.20.0.50 | 3000 | Visualization dashboards | `http://localhost:3000/api/health` |
| **Jaeger** | `trading-ecosystem-jaeger` | 172.20.0.60 | 16686 | Distributed tracing UI | `http://localhost:16686/` |
| **OpenTelemetry Collector** | `trading-ecosystem-otel-collector` | 172.20.0.70 | 4317/4318 | Telemetry aggregation | `http://localhost:13133/` |

### Service Connectivity Matrix

| From Service | To Service | Protocol | Purpose |
|--------------|------------|----------|---------|
| Service Registry | Redis | TCP:6379 | Service registration storage |
| Service Registry | PostgreSQL | TCP:5432 | Health check validation |
| Prometheus | All Services | HTTP | Metrics scraping |
| Grafana | Prometheus | HTTP:9090 | Data source queries |
| Jaeger | Prometheus | HTTP:9090 | Metrics integration |
| OpenTelemetry Collector | Prometheus | HTTP:9090 | Metrics export |
| OpenTelemetry Collector | Jaeger | gRPC:14250 | Trace export |
| Future Services | Service Registry | HTTP:8080 | Service discovery |
| Future Services | Redis | TCP:6379 | Caching & real-time data |
| Future Services | PostgreSQL | TCP:5432 | Persistent data storage |
| Future Services | OpenTelemetry Collector | gRPC:4317/HTTP:4318 | Telemetry export |

## ✅ TSE-0001.3a Acceptance Criteria

- [x] **Redis services can be brought up and down with Docker** ✅
- [x] **PostgreSQL services can be brought up and down with Docker** ✅
- [x] **Docker network configured with proper subnet isolation** ✅
- [x] **Services are discoverable through Redis service registry** ✅
- [x] **All services report healthy status via health checks** ✅
- [x] **BONUS: Complete observability stack ready for service integration** ✅

## 🌍 Environment Management

### Available Environments

#### **Development Environment**
```bash
# Start development environment
./scripts/deploy.sh dev

# Features:
# - Debug logging enabled
# - Hot reload for configuration changes
# - Chaos scenarios enabled
# - Resource limits relaxed
```

#### **Testing Environment**
```bash
# Start testing environment
./scripts/deploy.sh test

# Features:
# - Automated scenario execution
# - Comprehensive health checks
# - Performance monitoring enabled
# - Isolated from development data
```

#### **Production-Simulation Environment**
```bash
# Start production simulation
./scripts/deploy.sh prod

# Features:
# - Production-like resource constraints
# - Enhanced security settings
# - Complete audit logging
# - Regulatory compliance mode
```

### Environment Configuration
```bash
# .env.dev example
COMPOSE_PROJECT_NAME=trading-ecosystem-dev
ENVIRONMENT=development

# Component Versions
EXCHANGE_VERSION=v1.0.0
CUSTODIAN_VERSION=v1.0.0
MARKET_DATA_VERSION=v1.0.0
TRADING_ENGINE_VERSION=v1.0.0
RISK_MONITOR_VERSION=v1.0.0

# External API Keys (required for market data)
COINGECKO_API_KEY=your_coingecko_key_here
COINMARKETCAP_API_KEY=your_cmc_key_here

# System Configuration
POSTGRES_PASSWORD=secure_password
REDIS_PASSWORD=redis_password
GRAFANA_ADMIN_PASSWORD=admin_password

# Feature Flags
ENABLE_CHAOS_SCENARIOS=true
ENABLE_REAL_MARKET_DATA=true
ENABLE_AUDIT_LOGGING=true
```

## 🎭 Chaos Engineering

### Running Chaos Scenarios
```bash
# List available scenarios
./scripts/scenario-runner.sh list

# Run market crash scenario
./scripts/scenario-runner.sh run market-crash

# Run stablecoin depeg scenario
./scripts/scenario-runner.sh run stablecoin-depeg

# Run custom scenario
./scripts/scenario-runner.sh run custom-scenario.yaml
```

### Available Scenarios
- **Market Crash**: 15% coordinated price drop across all assets
- **Stablecoin Depeg**: USDT gradual depeg over 36 hours
- **Exchange Downtime**: Simulated exchange outage with recovery
- **Settlement Failure**: Custodian settlement delays and failures
- **Strategy Malfunction**: Runaway trading algorithm scenarios
- **Feed Disruption**: Market data latency and corruption scenarios

## 📊 Monitoring & Observability

### Pre-Configured Dashboards

#### **Executive Overview Dashboard**
- Portfolio P&L and risk metrics
- System health across all components
- Active scenario status
- Risk alert summary

#### **Risk Monitoring Dashboard**
- Position limits and utilization
- Risk alert timeline
- Compliance status tracking
- Circuit breaker activity

#### **Audit Correlation Dashboard**
- Scenario injection timeline
- Risk detection latency
- Event correlation analysis
- Validation coverage tracking

#### **System Performance Dashboard**
- Service health and uptime
- API response times
- Resource utilization
- Error rates and recovery

### Accessing Monitoring Tools
```bash
# View real-time logs from all services
./scripts/logs.sh

# View specific service logs
./scripts/logs.sh risk-monitor

# Export metrics for analysis
curl http://localhost:9090/api/v1/query?query=risk_monitor_portfolio_pnl

# Access Jaeger traces
open http://localhost:16686
```

## 🔧 Operations

### Health Checks
```bash
# Check system health
./scripts/health-check.sh

# Expected output:
# ✅ Exchange Simulator: Healthy
# ✅ Custodian Simulator: Healthy  
# ✅ Market Data Simulator: Healthy
# ✅ Trading Engine: Healthy
# ✅ Risk Monitor: Healthy
# ✅ Audit Correlator: Healthy
# ✅ PostgreSQL: Healthy
# ✅ Redis: Healthy
# ✅ Prometheus: Healthy
# ✅ Grafana: Healthy
```

### Deployment Operations
```bash
# Deploy specific environment
./scripts/deploy.sh [dev|test|prod]

# Update single service
docker compose up -d --no-deps risk-monitor

# Scale services (if needed)
docker compose up -d --scale trading-engine=2

# View service status
docker compose ps

# Stop all services
docker compose down

# Complete cleanup (removes volumes)
./scripts/cleanup.sh
```

### Troubleshooting
```bash
# View service logs
docker compose logs -f [service-name]

# Restart problematic service
docker compose restart risk-monitor

# Check network connectivity
docker compose exec risk-monitor ping exchange-simulator

# Validate configuration
docker compose config

# Debug container issues
docker compose exec risk-monitor bash
```

## 🌐 Network Architecture

### Network Separation
```yaml
networks:
  production-apis:
    # Risk Monitor access only - simulates production constraints
    # Connected: Risk Monitor, Exchange, Custodian, Market Data
    
  audit-network:
    # Complete system visibility for audit correlation
    # Connected: All services, Audit Correlator
    
  internal:
    # Service-to-service communication
    # Connected: All services, databases, monitoring
```

### Port Allocation

| Service | Internal Port | External Port | Purpose |
|---------|---------------|---------------|---------|
| Exchange Simulator | 8080 | 8080 | REST API |
| Custodian Simulator | 8081 | 8081 | REST API |
| Market Data Simulator | 8082 | 8082 | REST API |
| Trading Engine | 8083 | 8083 | REST API |
| Risk Monitor | 8084 | 8084 | Dashboard + API |
| Test Coordinator | 8085 | 8085 | Scenario API |
| Grafana | 3000 | 3000 | Dashboards |
| Prometheus | 9090 | 9090 | Metrics |
| Jaeger | 16686 | 16686 | Tracing |

## 🔒 Security Considerations

### Development Security
- Default passwords should be changed for any sensitive testing
- API keys stored in environment files (not committed to git)
- Network isolation between production and audit layers
- Container security scanning recommended

### Production Deployment Notes
- Use Docker secrets for sensitive data
- Enable TLS for all inter-service communication
- Implement proper authentication and authorization
- Use private container registry
- Enable audit logging and compliance features

## 🤝 Contributing

### Adding New Services
1. Add service definition to `docker compose.yml`
2. Configure appropriate networks and dependencies
3. Add health checks and resource limits
4. Update environment files with service configuration
5. Add monitoring configuration to Prometheus/Grafana
6. Update this README with new service documentation

### Modifying Orchestration
1. Test changes in development environment first
2. Validate with `docker compose config`
3. Update environment-specific overrides as needed
4. Test deployment scripts and health checks
5. Update documentation for any configuration changes

## 📚 Related Repositories

- **Project Plan**: [trading-ecosystem-project-plan](../trading-ecosystem-project-plan)
- **Exchange Simulator**: [exchange-simulator](../exchange-simulator)
- **Custodian Simulator**: [custodian-simulator](../custodian-simulator)
- **Market Data Simulator**: [market-data-simulator](../market-data-simulator)
- **Trading Engine**: [trading-strategy-engine](../trading-strategy-engine)
- **Risk Monitor**: [risk-monitor](../risk-monitor)
- **Test Coordinator**: [test-coordinator](../test-coordinator)
- **Audit Correlator**: [audit-correlator](../audit-correlator)

## 🐛 Known Issues

### Common Deployment Issues
- **Port conflicts**: Ensure ports 8080-8085, 3000, 9090, 16686 are available
- **Memory constraints**: Requires minimum 8GB RAM for full ecosystem
- **API rate limits**: Market data APIs may require paid plans for sustained testing
- **Container startup timing**: Some services may need retry logic for dependency startup

### Performance Considerations
- Initial startup takes 2-3 minutes for all health checks to pass
- Market data ingestion may have initial latency while establishing connections
- Grafana dashboard loading may be slow on first access
- Large scenario executions may require increased resource limits

---

**Quick Links:**
- 📖 [Full Documentation](https://github.com/your-org/trading-ecosystem-project-plan)
- 🐳 [Docker Hub Images](https://hub.docker.com/u/your-org)
- 📊 [Grafana Dashboards](http://localhost:3000)
- 🔍 [System Health](http://localhost:8084/health)

**Status**: 🚧 Active Development  
**Last Updated**: September 2025
