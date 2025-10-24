# Grafana Dashboards for Multi-Instance Service Monitoring

This directory contains Grafana dashboard configurations for monitoring the Trading Ecosystem services with multi-instance support.

## Overview

TSE-0001.12.0 enables two DevOps views for monitoring:

1. **Docker Infrastructure View**: Monitor all Docker containers and infrastructure components
2. **Simulation Entity View**: Monitor trading simulation entities and their interactions

## Dashboard Setup

### Prerequisites

- Grafana installed and running
- Prometheus configured as data source
- All services exposing `/api/v1/health` endpoints
- Service discovery configured in Redis

### Dashboard Types

#### 1. Docker Infrastructure Dashboard

**Purpose**: Monitor all Docker containers as infrastructure components

**Panels**:
- Container health status grid (one panel per service)
- Resource usage (CPU, memory, network)
- Service uptime and restart count
- Log volume and error rates

**Services Monitored**:
- **Singleton Services**: audit-correlator, test-coordinator
- **Infrastructure**: Redis, PostgreSQL, Grafana, Prometheus
- **Multi-Instance Services**: All exchange, custodian, market-data, trading-system, risk-monitor instances

#### 2. Simulation Entity Dashboard

**Purpose**: Monitor trading simulation as business entities

**Panels**:
- Trading system status (e.g., trading-engine-lh)
- Exchange connectivity (e.g., exchange-okx, exchange-binance)
- Custodian status (e.g., custodian-komainu)
- Market data feeds (e.g., market-data-coinmetrics)
- Risk monitoring (e.g., risk-monitor-lh)

**Business Metrics**:
- Order flow and execution rates
- Position tracking
- Risk limit monitoring
- Market data latency
- Settlement status

## Health Check Integration

All services now provide instance-aware health checks:

```bash
curl http://localhost:8083/api/v1/health
```

**Response**:
```json
{
  "status": "healthy",
  "service": "audit-correlator",
  "instance": "audit-correlator",
  "version": "1.0.0",
  "environment": "docker",
  "timestamp": "2025-10-07T12:34:56Z"
}
```

## Prometheus Metrics

### Scrape Configuration

Add to `prometheus.yml`:

```yaml
scrape_configs:
  # Singleton: audit-correlator
  - job_name: 'audit-correlator'
    static_configs:
      - targets: ['audit-correlator:8083']
        labels:
          service: 'audit-correlator'
          instance_name: 'audit-correlator'
          service_type: 'singleton'

  # Multi-instance: exchange simulators
  - job_name: 'exchange-simulator'
    static_configs:
      - targets: ['exchange-okx:8084']
        labels:
          service: 'exchange-simulator'
          instance_name: 'exchange-okx'
          service_type: 'multi-instance'
          entity_type: 'exchange'

      - targets: ['exchange-binance:8084']
        labels:
          service: 'exchange-simulator'
          instance_name: 'exchange-binance'
          service_type: 'multi-instance'
          entity_type: 'exchange'

  # Multi-instance: custodian simulators
  - job_name: 'custodian-simulator'
    static_configs:
      - targets: ['custodian-komainu:8083']
        labels:
          service: 'custodian-simulator'
          instance_name: 'custodian-komainu'
          service_type: 'multi-instance'
          entity_type: 'custodian'
```

### PromQL Queries

#### Container Health Status
```promql
# All service health status
up{job=~"audit-correlator|exchange-simulator|custodian-simulator|.*"}

# Specific instance health
up{instance_name="exchange-okx"}

# All exchanges
up{entity_type="exchange"}

# Service type breakdown
count by (service_type) (up == 1)
```

#### Instance Grouping
```promql
# Group by service name (shows all instances)
sum by (service) (up)

# Group by instance name (individual instances)
sum by (instance_name) (up)

# Entity type view (simulation perspective)
sum by (entity_type) (up)
```

## Manual Dashboard Creation

### Step 1: Create Dashboard

1. Navigate to Grafana UI (http://localhost:3000)
2. Click "+" → "Dashboard"
3. Add panels as described below

### Step 2: Docker Infrastructure View

**Panel 1: Service Health Grid**
- Visualization: Stat
- Query: `up{job=~".*"}`
- Transform: Organize fields by instance_name
- Value mappings: 0 = Down (red), 1 = Up (green)
- Layout: Grid (multiple stat panels)

**Panel 2: Container Resource Usage**
- Visualization: Time series
- Queries:
  - CPU: `rate(container_cpu_usage_seconds_total[5m])`
  - Memory: `container_memory_usage_bytes`
- Legend: `{{instance_name}}`

**Panel 3: Service Uptime**
- Visualization: Stat
- Query: `time() - process_start_time_seconds`
- Format: Duration

### Step 3: Simulation Entity View

**Panel 1: Trading System Status**
- Visualization: Stat
- Query: `up{instance_name=~"trading-engine-.*"}`
- Group by: instance_name

**Panel 2: Exchange Connectivity**
- Visualization: Status timeline
- Query: `up{entity_type="exchange"}`
- Shows connection status over time

**Panel 3: Order Flow**
- Visualization: Time series
- Query: `rate(orders_total{instance_name=~"exchange-.*"}[5m])`
- Legend: `{{instance_name}}`

**Panel 4: Risk Monitor Status**
- Visualization: Gauge
- Query: `risk_limit_utilization{instance_name=~"risk-monitor-.*"}`
- Thresholds: 0-70% (green), 70-90% (yellow), 90-100% (red)

## Variable Templates

Add dashboard variables for dynamic filtering:

```
Name: instance
Label: Service Instance
Type: Query
Query: label_values(up, instance_name)
Multi-value: true
Include All: true

Name: service_type
Label: Service Type
Type: Custom
Values: singleton, multi-instance
Multi-value: true
Include All: true

Name: entity_type
Label: Entity Type
Type: Query
Query: label_values(up{service_type="multi-instance"}, entity_type)
Multi-value: true
Include All: true
```

## Dashboard JSON Templates

Full dashboard JSON templates will be added in future updates. Current setup supports manual dashboard creation using the queries above.

### Future Enhancements

- [ ] Complete Docker Infrastructure dashboard JSON
- [ ] Complete Simulation Entity dashboard JSON
- [ ] Automated dashboard provisioning via Grafana API
- [ ] Alert rules for service health
- [ ] Integration with service discovery for dynamic targets
- [ ] Custom metrics from each service type

## Testing Dashboard Queries

Test queries in Prometheus UI first:

```bash
# Open Prometheus
open http://localhost:9090

# Test query
up{job="audit-correlator"}

# Should return:
# up{instance="audit-correlator:8083", instance_name="audit-correlator", job="audit-correlator", service="audit-correlator"} 1
```

## Next Steps

1. Start Grafana: `docker-compose up -d grafana`
2. Configure Prometheus data source in Grafana
3. Create dashboards using panels above
4. Export dashboards as JSON and commit to this directory
5. Set up alerts for critical services

## Support

For issues or questions:
- Check service health: `docker-compose ps`
- View logs: `docker-compose logs [service-name]`
- Verify Prometheus targets: http://localhost:9090/targets
