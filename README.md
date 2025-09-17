# Trading Ecosystem Orchestrator

Docker Compose orchestration for the complete trading ecosystem simulation with production-like risk monitoring, chaos engineering, and comprehensive auditability.

## 🎯 Overview

This repository contains the Docker Compose orchestration and deployment configuration for the entire trading ecosystem simulation. It brings together all microservices into a cohesive system that can be deployed with a single command while maintaining clean network separation and realistic operational constraints.

### System Components
- **Exchange Simulator** (Go): Crypto exchange with order matching and chaos injection
- **Custodian Simulator** (Go): Settlement and custody operations with multi-day cycles  
- **Market Data Simulator** (Go): Real market data feeds with controlled price manipulation
- **Trading Strategy Engine** (Python): Algorithmic trading with misbehaving strategy chaos testing
- **Risk Monitor** (Python): Production-authentic risk surveillance and compliance alerting
- **Test Coordinator** (Python): Chaos scenario orchestration and validation framework
- **Audit Correlator** (Go): Independent system validation and event correlation
- **Observability Stack**: Prometheus, Grafana, OpenTelemetry, PostgreSQL, Redis

## 🚀 Quick Start

### Prerequisites
- Docker 28.4+
- Docker Compose 2.8+
- 8GB RAM minimum (16GB recommended)
- Available ports: 8080-8085, 3000, 9090, 16686

### One-Command Deployment
```bash
# Clone the orchestration repository
git clone <this-repo-url>
cd trading-ecosystem-orchestrator-docker

# Copy environment configuration
cp .env.example .env.dev

# Edit API keys and configuration (optional for basic testing)
nano .env.dev

# Deploy the complete ecosystem
./scripts/deploy.sh dev

# Verify deployment
./scripts/health-check.sh
```

### Access Points
After successful deployment:
- **Risk Dashboard**: http://localhost:8084 (Risk Monitor web interface)
- **Grafana Dashboards**: http://localhost:3000 (admin/admin)
- **Prometheus Metrics**: http://localhost:9090
- **Jaeger Tracing**: http://localhost:16686
- **Exchange API**: http://localhost:8080
- **Custodian API**: http://localhost:8081
- **Market Data API**: http://localhost:8082

## 📁 Repository Structure

```
├── docker-compose.yml              # Main orchestration file
├── docker-compose.dev.yml          # Development environment overrides
├── docker-compose.test.yml         # Testing environment configuration
├── docker-compose.prod.yml         # Production-ready configuration
├── .env.example                    # Environment template
├── .env.dev                        # Development environment
├── .env.test                       # Testing environment
├── configs/                        # Service configurations
│   ├── prometheus/
│   │   └── prometheus.yml          # Metrics collection config
│   ├── grafana/
│   │   ├── dashboards/             # Pre-built dashboards
│   │   └── datasources/            # Data source configurations
│   ├── otel-collector/
│   │   └── otel-config.yaml        # OpenTelemetry configuration
│   └── scenarios/                  # Chaos scenario definitions
├── scripts/                        # Deployment and utility scripts
│   ├── deploy.sh                   # Main deployment script
│   ├── health-check.sh             # System health verification
│   ├── cleanup.sh                  # Environment cleanup
│   ├── logs.sh                     # Log aggregation script
│   └── scenario-runner.sh          # Chaos scenario execution
├── volumes/                        # Persistent volume configurations
├── networks/                       # Network definitions
└── README.md                       # This file
```

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
docker-compose up -d --no-deps risk-monitor

# Scale services (if needed)
docker-compose up -d --scale trading-engine=2

# View service status
docker-compose ps

# Stop all services
docker-compose down

# Complete cleanup (removes volumes)
./scripts/cleanup.sh
```

### Troubleshooting
```bash
# View service logs
docker-compose logs -f [service-name]

# Restart problematic service
docker-compose restart risk-monitor

# Check network connectivity
docker-compose exec risk-monitor ping exchange-simulator

# Validate configuration
docker-compose config

# Debug container issues
docker-compose exec risk-monitor bash
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
1. Add service definition to `docker-compose.yml`
2. Configure appropriate networks and dependencies
3. Add health checks and resource limits
4. Update environment files with service configuration
5. Add monitoring configuration to Prometheus/Grafana
6. Update this README with new service documentation

### Modifying Orchestration
1. Test changes in development environment first
2. Validate with `docker-compose config`
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
