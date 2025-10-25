# feat(epic-TSE-0002): Add topology configuration generation and volume mounting

## Summary

Adds topology configuration generation script and Docker volume mounting to provide audit-correlator with initial network structure. This enables the TopologyService to start with pre-populated nodes and edges, solving the "No topology data available" issue in the UI.

**Problem**: audit-correlator's TopologyService started with empty in-memory repositories, resulting in no data for the UI visualization.

**Solution**:
1. Python script to parse docker-compose.yml and generate topology.json
2. Mount config directory as read-only volume in audit-correlator container
3. Generated config includes all 7 trading ecosystem services and 11 connections

## What Changed

### Configuration Generation (`scripts/`)

- **`generate-topology-config.py`** (259 lines) - New script:
  - Parses `docker-compose.yml` using PyYAML
  - Extracts service information (containers, ports, IPs)
  - Maps container names to service types
  - Defines known service connections (edges)
  - Generates `config/topology.json` with nodes and edges
  - Categories: simulator, monitoring, trading, orchestration
  - Executable: `chmod +x`

### Generated Configuration (`config/`)

- **`topology.json`** - Auto-generated:
  - 7 nodes (trading ecosystem services)
  - 11 edges (service connections)
  - Port mappings (gRPC + HTTP)
  - Internal Docker network IPs
  - Service categories and metadata

### Docker Compose (`docker-compose.yml`)

- **audit-correlator service** - Enhanced volumes:
  ```yaml
  volumes:
    - ./volumes/audit-correlator/data:/app/data
    - ./volumes/audit-correlator/logs:/app/logs
    - ./config:/app/config:ro  # NEW: Mount topology config (read-only)
  ```

## Generated Topology Structure

### Services (7 nodes):
1. **Audit Correlator** (audit-correlator-go) - Monitoring
2. **Custodian Komainu** (custodian-simulator-go) - Simulator
3. **Exchange OKX** (exchange-simulator-go) - Simulator
4. **Market Data Coinmetrics** (market-data-simulator-go) - Simulator
5. **Risk Monitor LH** (risk-monitor-py) - Monitoring
6. **Trading Engine LH** (trading-system-engine-py) - Trading
7. **Test Coordinator** (test-coordinator-py) - Orchestration

### Connections (11 edges):
- Risk Monitor → Trading Engine (monitors)
- Trading Engine → Exchange (trades_via)
- Trading Engine → Custodian (custodies_via)
- Market Data → Trading Engine (provides_data_to)
- Audit Correlator → All Services (audits) - 5 connections
- Test Coordinator → Trading Engine, Risk Monitor (tests) - 2 connections

## Usage

### Generate Configuration

```bash
# From orchestrator-docker directory:
python3 scripts/generate-topology-config.py

# Output:
# ✅ Generated topology configuration: config/topology.json
#    Nodes: 7
#    Edges: 11
```

### Deployment

```bash
# 1. Generate config (if not already done):
python3 scripts/generate-topology-config.py

# 2. Rebuild audit-correlator to pick up volume mount:
docker-compose build audit-correlator

# 3. Restart service:
docker-compose up -d audit-correlator

# 4. Verify topology loaded:
docker logs trading-ecosystem-audit-correlator | grep topology

# Expected output:
# {"msg":"Loading topology configuration","config_path":"/app/config/topology.json"}
# {"msg":"Parsed topology configuration","nodes":7,"edges":11}
# {"msg":"Successfully loaded topology configuration"}
```

## Configuration Format

The script generates JSON in this structure:

```json
{
  "version": "1.0",
  "generated_at": "startup",
  "nodes": [
    {
      "id": "node-audit-correlator",
      "name": "Audit Correlator",
      "service_type": "audit-correlator-go",
      "category": "monitoring",
      "status": "LIVE",
      "version": "1.0.0",
      "endpoints": {
        "grpc": "localhost:50052",
        "http": "localhost:8082",
        "internal_ip": "172.20.0.80"
      },
      "health": {
        "cpu_percent": 0.0,
        "memory_mb": 0.0,
        "total_requests": 0,
        "total_errors": 0,
        "error_rate": 0.0
      }
    }
  ],
  "edges": [
    {
      "id": "edge-risk-monitor-lh-to-trading-engine-lh",
      "source_id": "node-risk-monitor-lh",
      "target_id": "node-trading-engine-lh",
      "protocol": "gRPC",
      "relationship": "monitors",
      "status": "ACTIVE",
      "metrics": {
        "latency_p50_ms": 10.0,
        "latency_p99_ms": 50.0,
        "throughput_rps": 100.0,
        "error_rate": 0.001
      }
    }
  ]
}
```

## Testing

```bash
# 1. Generate config
python3 scripts/generate-topology-config.py
# ✅ Creates config/topology.json

# 2. Verify JSON is valid
python3 -m json.tool config/topology.json > /dev/null
# ✅ No output = valid JSON

# 3. Check node count
cat config/topology.json | grep -c '"id": "node-'
# Expected: 7

# 4. Check edge count
cat config/topology.json | grep -c '"id": "edge-'
# Expected: 11

# 5. Deploy and verify
docker-compose up -d audit-correlator
docker logs trading-ecosystem-audit-correlator | grep "Successfully loaded"
# ✅ Should see: "Successfully loaded topology configuration"
```

## Integration with audit-correlator-go

This feature complements audit-correlator-go changes:
- **This PR**: Generates config and mounts volume
- **audit-correlator PR**: Loads config and populates repositories

Both PRs must be deployed together for topology to appear in UI.

## Architecture Impact

✅ **Configuration as Code**:
- Topology derived from docker-compose.yml (single source of truth)
- Regenerate anytime docker-compose changes
- No manual configuration maintenance

✅ **Docker Best Practices**:
- Read-only volume mount (`:ro`) for security
- Config lives outside container
- Easy to update without rebuilding image

✅ **Service Discovery Foundation**:
- Static config provides baseline topology
- Future: Dynamic service discovery can augment/override
- Graceful transition path from static → dynamic

## Future Enhancements

**Phase 1** (This PR): Static configuration generation ✅
- Parse docker-compose.yml
- Generate topology.json
- Mount as volume

**Phase 2** (Future): Dynamic augmentation
- Service discovery overrides for status
- Real-time metrics collection
- Health check integration

**Phase 3** (Future): Auto-regeneration
- Watch docker-compose.yml for changes
- Trigger regeneration on modify
- Signal audit-correlator to reload

## Problem Solved

**Original Issue**: "No topology data available" in UI

**Root Cause**: audit-correlator had no initial data to serve

**Solution Verification**:
```bash
# After deployment:
curl -X POST http://localhost:8082/audit.v1.TopologyService/GetTopologyStructure \
  -H "Content-Type: application/json" \
  -d '{"request_id": "test"}'

# Response includes 7 nodes and 11 edges ✅
```

## Related Work

- **Depends On**:
  - docker-compose.yml service definitions - ✅ existing

- **Requires (audit-correlator-go)**:
  - Topology config loader implementation
  - Service startup integration
  - See audit-correlator-go PR

- **Enables**:
  - ✅ **Immediate**: UI shows actual network topology
  - ✅ **Immediate**: D3.js visualization with service graph
  - Future: Baseline for dynamic discovery
  - Future: CI/CD topology validation

## Epic Context

**Epic**: TSE-0002 - Network Topology Visualization
**Type**: Feature (configuration generation)
**Status**: ✅ Ready for deployment

This provides the configuration layer for topology visualization.

## Branch Information

- **Branch**: `feature/epic-TSE-0002-topology-config-generation`
- **Base**: `main`
- **Type**: `feature` (new functionality)
- **Epic**: TSE-0002
- **Milestone**: Configuration infrastructure

## Checklist

- [x] Script parses docker-compose.yml successfully
- [x] Generated JSON is valid
- [x] All 7 trading services included
- [x] All 11 known connections defined
- [x] Port mappings extracted correctly
- [x] Internal IPs included
- [x] Docker volume mount added (read-only)
- [x] Script is executable (`chmod +x`)
- [x] PR documentation complete
- [x] Branch name follows `feature/epic-XXX-description` format
- [x] Ready for deployment with audit-correlator-go
