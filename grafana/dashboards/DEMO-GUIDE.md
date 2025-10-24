# Grafana Dashboard Demonstration Guide

**Epic:** TSE-0001.12.0 - Multi-Instance Infrastructure Foundation
**Purpose:** Step-by-step guide to demonstrate Grafana monitoring capabilities

## Overview

This guide demonstrates the multi-instance monitoring foundation with two DevOps views:
1. **Docker Infrastructure View**: Monitor all containers as infrastructure components
2. **Simulation Entity View**: Monitor trading simulation as business entities

## Prerequisites

- Docker and Docker Compose installed
- Working directory: `/home/skingham/Projects/Quantfidential/trading-ecosystem/orchestrator-docker`
- At least 4GB RAM available for containers
- Ports available: 3000 (Grafana), 9090 (Prometheus), 8083 (audit-correlator)

## Step 1: Start the Infrastructure

### 1.1 Start Core Infrastructure

```bash
cd /home/skingham/Projects/Quantfidential/trading-ecosystem/orchestrator-docker

# Start infrastructure services
docker-compose up -d redis postgres prometheus grafana
```

**Expected Output:**
```
✅ Container trading-ecosystem-redis       Started
✅ Container trading-ecosystem-postgres    Started
✅ Container trading-ecosystem-prometheus  Started
✅ Container trading-ecosystem-grafana     Started
```

### 1.2 Verify Infrastructure Health

```bash
# Wait 30 seconds for health checks
sleep 30

# Check service status
docker-compose ps
```

**Expected Status:**
```
NAME                              STATUS              PORTS
trading-ecosystem-redis           Up (healthy)        127.0.0.1:6379->6379/tcp
trading-ecosystem-postgres        Up (healthy)        127.0.0.1:5432->5432/tcp
trading-ecosystem-prometheus      Up (healthy)        127.0.0.1:9090->9090/tcp
trading-ecosystem-grafana         Up (healthy)        127.0.0.1:3000->3000/tcp
```

### 1.3 Start Application Services

```bash
# Start audit-correlator (singleton service)
docker-compose up -d audit-correlator

# Wait for startup
sleep 15

# Verify audit-correlator is healthy
curl http://localhost:8083/api/v1/health | jq
```

**Expected Response:**
```json
{
  "status": "healthy",
  "service": "audit-correlator",
  "instance": "audit-correlator",
  "version": "1.0.0",
  "environment": "docker",
  "timestamp": "2025-10-08T12:34:56Z"
}
```

**✅ Key Point**: Notice the `instance` field in the health check - this enables instance-aware monitoring!

## Step 2: Access Grafana

### 2.1 Open Grafana UI

```bash
# Open browser to Grafana
open http://localhost:3000
# Or on Linux/WSL
xdg-open http://localhost:3000
```

### 2.2 Login

**Credentials:**
- Username: `admin`
- Password: `admin`

(You may be prompted to change the password - you can skip this for the demo)

### 2.3 Verify Prometheus Datasource

1. Click **⚙️ Configuration** (gear icon) → **Data sources**
2. Verify **Prometheus** datasource is listed
3. Click on **Prometheus**
4. Scroll down and click **Save & test**

**Expected:** ✅ "Data source is working"

## Step 3: Verify Prometheus Metrics

### 3.1 Check Prometheus Targets

```bash
# Open Prometheus UI
open http://localhost:9090/targets
```

**Expected Targets:**
- ✅ `prometheus` (localhost:9090) - UP
- ✅ `grafana` (172.20.0.50:3000) - UP
- ⚠️ `redis` (172.20.0.10:6379) - DOWN (no metrics endpoint yet)
- ⚠️ `postgres` (172.20.0.20:5432) - DOWN (no metrics endpoint yet)

**Note:** Redis and PostgreSQL don't expose metrics by default. For the demo, we'll use Prometheus and Grafana's own metrics.

### 3.2 Test Prometheus Queries

In Prometheus UI (http://localhost:9090):

**Query 1: Check if services are up**
```promql
up
```

**Expected Results:**
```
up{instance="172.20.0.50:3000", job="grafana"}     1
up{instance="172.20.0.60:14269", job="jaeger"}     1
up{instance="172.20.0.70:8888", job="otel-collector"} 1
up{instance="localhost:9090", job="prometheus"}    1
```

**Query 2: Grafana HTTP requests**
```promql
rate(grafana_http_request_duration_seconds_count[5m])
```

**Query 3: Prometheus scrape duration**
```promql
scrape_duration_seconds
```

## Step 4: Create Dashboard - Docker Infrastructure View

### 4.1 Create New Dashboard

1. In Grafana, click **➕** (plus icon) → **Dashboard**
2. Click **Add visualization**
3. Select **Prometheus** datasource

### 4.2 Panel 1: Service Health Status

**Configuration:**
- **Panel Title**: Service Health Status
- **Visualization**: Stat
- **Query**: `up`
- **Legend**: `{{job}} - {{instance}}`

**Options:**
1. Under **Value options** → **Calculation**: Last
2. Under **Value mappings**:
   - Add mapping: `0` → Text: `DOWN` → Color: Red
   - Add mapping: `1` → Text: `UP` → Color: Green
3. Under **Graph mode**: None
4. Under **Text mode**: Value and name

**Expected Display:**
```
✅ prometheus - localhost:9090        UP
✅ grafana - 172.20.0.50:3000        UP
✅ jaeger - 172.20.0.60:14269        UP
✅ otel-collector - 172.20.0.70:8888 UP
```

**Action:** Click **Apply** to save the panel

### 4.3 Panel 2: Service Uptime

1. Click **Add** → **Visualization**
2. Select **Prometheus** datasource

**Configuration:**
- **Panel Title**: Service Uptime
- **Visualization**: Stat
- **Query**: `time() - process_start_time_seconds`
- **Legend**: `{{job}}`

**Options:**
1. Under **Standard options** → **Unit**: Duration (s)
2. Under **Graph mode**: None
3. Under **Color mode**: Background

**Expected Display:**
```
prometheus      2h 15m
grafana         2h 14m
jaeger          2h 14m
otel-collector  2h 13m
```

**Action:** Click **Apply**

### 4.4 Panel 3: HTTP Request Rate

1. Click **Add** → **Visualization**
2. Select **Prometheus** datasource

**Configuration:**
- **Panel Title**: HTTP Requests (per second)
- **Visualization**: Time series
- **Query**: `rate(grafana_http_request_duration_seconds_count[5m])`
- **Legend**: `{{handler}} - {{method}}`

**Options:**
1. Under **Legend** → **Visibility**: Show
2. Under **Legend** → **Placement**: Bottom
3. Under **Axis** → **Unit**: ops/sec

**Expected Display:**
- Line graph showing Grafana HTTP request rates over time
- Multiple series for different endpoints

**Action:** Click **Apply**

### 4.5 Panel 4: Memory Usage

1. Click **Add** → **Visualization**
2. Select **Prometheus** datasource

**Configuration:**
- **Panel Title**: Memory Usage (MB)
- **Visualization**: Time series
- **Query**: `process_resident_memory_bytes / 1024 / 1024`
- **Legend**: `{{job}}`

**Options:**
1. Under **Axis** → **Unit**: MB
2. Under **Legend** → **Placement**: Bottom

**Expected Display:**
- Line graph showing memory usage for Prometheus, Grafana, etc.

**Action:** Click **Apply**

### 4.6 Save Dashboard

1. Click **💾 Save dashboard** (top right)
2. **Name**: `Docker Infrastructure - Trading Ecosystem`
3. **Folder**: General
4. Click **Save**

## Step 5: Add Dashboard Variables (Instance Filtering)

### 5.1 Add Instance Variable

1. Click **⚙️ Dashboard settings** (top right)
2. Click **Variables** → **Add variable**

**Configuration:**
- **Name**: `instance`
- **Label**: Service Instance
- **Type**: Query
- **Data source**: Prometheus
- **Query**: `label_values(up, job)`
- **Multi-value**: ☑️ Enabled
- **Include All option**: ☑️ Enabled

**Action:** Click **Apply**

### 5.2 Update Panels to Use Variable

1. Go back to dashboard
2. Edit **Service Health Status** panel
3. Update query to: `up{job=~"$instance"}`
4. Repeat for other panels where applicable

**Action:** Click **Apply** and **Save dashboard**

### 5.3 Test Variable

1. At the top of the dashboard, you'll now see **Service Instance** dropdown
2. Try selecting different services (prometheus, grafana, jaeger)
3. Observe panels update to show only selected instances

## Step 6: Demonstrate Instance-Aware Monitoring

### 6.1 Show Singleton Service Pattern

**Current Setup:**
- `audit-correlator` is running as singleton (SERVICE_NAME == SERVICE_INSTANCE_NAME)

**Demonstrate:**
```bash
# Show instance awareness in health check
curl http://localhost:8083/api/v1/health | jq '.instance'
```

**Expected:** `"audit-correlator"`

**Explanation:**
> "The audit-correlator is a singleton service. Notice how `instance` equals `service`. This derives the PostgreSQL schema as 'audit' and Redis namespace as 'audit'."

### 6.2 Simulate Multi-Instance Pattern

**Explain:** (No need to actually deploy multiple instances for demo)

> "In TSE-0001.13, we'll deploy multi-instance services like:
> - `exchange-OKX` (instance of exchange-simulator)
> - `exchange-Binance` (instance of exchange-simulator)
> - `custodian-Komainu` (instance of custodian-simulator)
>
> Each instance will have:
> - Unique PostgreSQL schema: `exchange_okx`, `exchange_binance`
> - Unique Redis namespace: `exchange:OKX`, `exchange:Binance`
> - Separate health check endpoints
> - Separate Prometheus scrape targets"

### 6.3 Show Derivation Logic

**Create slides or explain:**

**Singleton Service Derivation:**
```
Input:
  SERVICE_NAME: audit-correlator
  SERVICE_INSTANCE_NAME: audit-correlator

Derivation:
  Schema: "audit" (first part before hyphen)
  Redis Namespace: "audit"
```

**Multi-Instance Service Derivation:**
```
Input:
  SERVICE_NAME: exchange-simulator
  SERVICE_INSTANCE_NAME: exchange-OKX

Derivation:
  Schema: "exchange_okx" (first two parts, underscore, lowercase)
  Redis Namespace: "exchange:OKX" (first two parts, colon)
```

## Step 7: Create Dashboard - Simulation Entity View (Conceptual)

### 7.1 Explain the Concept

> "The Simulation Entity View groups services by business purpose rather than infrastructure:
>
> - **Trading Systems**: trading-system-LH, trading-system-MK
> - **Exchanges**: exchange-OKX, exchange-Binance, exchange-Coinbase
> - **Custodians**: custodian-Komainu, custodian-Fireblocks
> - **Market Data**: market-data-Coinmetrics, market-data-Bloomberg
> - **Risk Monitors**: risk-monitor-LH, risk-monitor-MK
>
> Each entity type would have dedicated panels showing business metrics like:
> - Order flow rates
> - Position values
> - Risk limit utilization
> - Settlement status"

### 7.2 Create Placeholder Dashboard

1. Create new dashboard: `Trading Simulation Entities`
2. Add text panel explaining the concept
3. Add placeholder stat panels for:
   - Trading Systems Status
   - Exchange Connectivity
   - Custodian Operations
   - Market Data Feeds
   - Risk Monitor Status

**Panel Text Example:**
```markdown
# Trading Simulation Entity View

This dashboard will monitor trading simulation as business entities:

## Entity Types
- **Trading Systems**: Decision-making engines
- **Exchanges**: Order execution venues
- **Custodians**: Asset custody and settlement
- **Market Data**: Price feeds and market info
- **Risk Monitors**: Risk management and limits

*To be implemented in TSE-0001.13 (Multi-Instance Deployment)*
```

## Step 8: Show Prometheus Scrape Configuration

### 8.1 Explain Current Config

```bash
# Show prometheus config
cat prometheus/prometheus.yml | grep -A 10 "scrape_configs"
```

**Highlight:**
- Infrastructure services (Redis, Postgres)
- Service registry
- Placeholder for Go services
- Placeholder for Python services

### 8.2 Show Future Multi-Instance Config

**Create example** (you can show this in a text editor):

```yaml
# Future: Multi-Instance Exchange Scraping
- job_name: 'exchange-simulator'
  static_configs:
    - targets: ['172.20.0.82:8082']
      labels:
        service: 'exchange-simulator'
        instance_name: 'exchange-OKX'
        service_type: 'multi-instance'
        entity_type: 'exchange'

    - targets: ['172.20.0.83:8082']
      labels:
        service: 'exchange-simulator'
        instance_name: 'exchange-Binance'
        service_type: 'multi-instance'
        entity_type: 'exchange'
```

**Explain:**
> "Each instance gets its own target with labels:
> - `instance_name`: Unique identifier
> - `service_type`: singleton or multi-instance
> - `entity_type`: Business category (exchange, custodian, etc.)
>
> These labels enable powerful Grafana queries like:
> - All exchanges: `{entity_type='exchange'}`
> - Specific instance: `{instance_name='exchange-OKX'}`
> - All multi-instance: `{service_type='multi-instance'}`"

## Step 9: Demonstrate Query Patterns

### 9.1 Infrastructure Grouping

**Query in Prometheus:**
```promql
# Group all services by job
count by (job) (up == 1)
```

**Expected Result:**
```
{job="grafana"}         1
{job="jaeger"}          1
{job="otel-collector"}  1
{job="prometheus"}      1
```

### 9.2 Instance Filtering

**Query:**
```promql
# Show only Grafana metrics
up{job="grafana"}
```

### 9.3 Future Multi-Instance Queries

**Show examples** (explain conceptually):

```promql
# All exchanges
up{entity_type="exchange"}

# Specific exchange
up{instance_name="exchange-OKX"}

# Count instances by entity type
count by (entity_type) (up{service_type="multi-instance"})

# Instance health percentage
avg by (service) (up{service_type="multi-instance"}) * 100
```

## Step 10: Show Logs with Instance Context

### 10.1 View Audit Correlator Logs

```bash
# Show logs with instance context
docker-compose logs audit-correlator | grep -i instance | head -20
```

**Expected Output:**
```json
{
  "level": "info",
  "service_name": "audit-correlator",
  "instance_name": "audit-correlator",
  "environment": "docker",
  "msg": "Starting audit-correlator service",
  "time": "2025-10-08T12:34:56Z"
}
{
  "level": "info",
  "service_name": "audit-correlator",
  "instance_name": "audit-correlator",
  "msg": "DataAdapter configuration resolved",
  "schema_name": "audit",
  "redis_namespace": "audit",
  "time": "2025-10-08T12:34:57Z"
}
```

**Highlight:**
> "Every log entry includes instance context. In multi-instance deployments, this allows filtering logs by specific instance:
> - `instance_name=exchange-OKX` → Only OKX exchange logs
> - `instance_name=trading-system-LH` → Only LH trading system logs"

## Step 11: Architecture Demonstration

### 11.1 Show Schema Isolation

**Explain with diagram:**
```
PostgreSQL Database: trading_ecosystem
├── Schema: audit (audit-correlator)
│   ├── audit_events
│   └── correlations
│
├── Schema: exchange_okx (exchange-OKX)
│   ├── orders
│   ├── trades
│   └── positions
│
└── Schema: exchange_binance (exchange-Binance)
    ├── orders
    ├── trades
    └── positions
```

### 11.2 Show Redis Namespace Isolation

**Explain:**
```
Redis Database 0
├── Namespace: audit:* (audit-correlator)
│   ├── audit:event:12345
│   └── audit:correlation:trace-abc
│
├── Namespace: exchange:OKX:* (exchange-OKX)
│   ├── exchange:OKX:order:order-123
│   └── exchange:OKX:position:BTC-USD
│
└── Namespace: exchange:Binance:* (exchange-Binance)
    ├── exchange:Binance:order:order-456
    └── exchange:Binance:position:ETH-USD
```

## Step 12: Cleanup and Next Steps

### 12.1 Save Dashboard Export

1. In Grafana, go to **Docker Infrastructure** dashboard
2. Click **⚙️** → **JSON Model**
3. Copy the JSON
4. Save to file: `grafana/dashboards/docker-infrastructure.json`

### 12.2 Stop Services

```bash
# Stop all services
docker-compose down

# Or keep running for further exploration
docker-compose stop
```

### 12.3 Next Steps Explanation

**Explain to stakeholders:**

> **✅ Completed (TSE-0001.12.0):**
> - Multi-instance configuration foundation
> - Instance-aware health checks
> - Schema and namespace derivation
> - Grafana dashboard documentation
> - Monitoring foundation established
>
> **⏭️ Next Epic (TSE-0001.13):**
> - Deploy actual multi-instance services
> - Configure Prometheus scraping for all instances
> - Create complete dashboard JSON files
> - Implement automated dashboard provisioning
> - Add business metrics and alerts
>
> **🎯 Goal:**
> Full observability across all trading simulation entities with two complementary views:
> - DevOps view: Infrastructure health
> - Business view: Trading simulation status

## Troubleshooting

### Grafana Not Loading

```bash
# Check Grafana logs
docker-compose logs grafana

# Restart Grafana
docker-compose restart grafana
```

### Prometheus Not Scraping

```bash
# Check Prometheus config
docker-compose exec prometheus cat /etc/prometheus/prometheus.yml

# Reload Prometheus config
curl -X POST http://localhost:9090/-/reload
```

### No Data in Dashboards

1. Verify Prometheus is scraping: http://localhost:9090/targets
2. Test query in Prometheus UI first
3. Check datasource connection in Grafana
4. Verify time range is recent (last 5-15 minutes)

## Demo Script Summary

**Quick 5-Minute Demo:**
1. Show infrastructure running (docker-compose ps)
2. Open Grafana (http://localhost:3000)
3. Show Docker Infrastructure dashboard
4. Explain instance-aware health checks
5. Show audit-correlator instance field
6. Explain multi-instance future (TSE-0001.13)

**Full 15-Minute Demo:**
- All of the above, plus:
- Create a dashboard panel live
- Show Prometheus queries
- Demonstrate schema/namespace derivation
- Show logs with instance context
- Explain architecture diagrams
- Show future multi-instance config

**30-Minute Workshop:**
- Full demo above
- Hands-on: Participants create their own panels
- Explore Grafana features
- Q&A about multi-instance architecture

---

**Epic:** TSE-0001.12.0 - Multi-Instance Infrastructure Foundation
**Status:** Foundation Complete ✅
**Next:** TSE-0001.13 - Multi-Instance Deployment

🤖 Generated with [Claude Code](https://claude.com/claude-code)
