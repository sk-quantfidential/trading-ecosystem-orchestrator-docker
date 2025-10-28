#!/usr/bin/env python3
"""
Generate topology configuration from docker-compose.yml

Extracts service information and generates a topology.json file
that audit-correlator can load on startup.
"""

import yaml
import json
import sys
from pathlib import Path
from typing import Dict, List, Any


def extract_service_type(container_name: str) -> str:
    """Extract service type from container name."""
    # Remove 'trading-ecosystem-' prefix
    name = container_name.replace('trading-ecosystem-', '')

    # Map to service types
    type_mapping = {
        'audit-correlator': 'audit-correlator-go',
        'custodian-komainu': 'custodian-simulator-go',
        'exchange-okx': 'exchange-simulator-go',
        'market-data-coinmetrics': 'market-data-simulator-go',
        'risk-monitor-lh': 'risk-monitor-py',
        'trading-engine-lh': 'trading-system-engine-py',
        'test-coordinator': 'test-coordinator-py',
    }

    return type_mapping.get(name, name)


def extract_service_category(service_type: str) -> str:
    """Categorize service by type."""
    if 'simulator' in service_type or 'custodian' in service_type or 'exchange' in service_type or 'market-data' in service_type:
        return 'simulator'
    elif 'monitor' in service_type or 'audit' in service_type:
        return 'monitoring'
    elif 'trading' in service_type or 'engine' in service_type:
        return 'trading'
    elif 'coordinator' in service_type:
        return 'orchestration'
    elif 'infra' in service_type:
        return 'infrastructure'
    else:
        return 'other'


def parse_docker_compose(compose_file: Path) -> Dict[str, Any]:
    """Parse docker-compose.yml and extract service topology."""
    with open(compose_file, 'r') as f:
        compose = yaml.safe_load(f)

    services = compose.get('services', {})
    nodes = []
    edges = []

    # Service types that are part of the trading ecosystem (not infrastructure)
    trading_services = [
        'audit-correlator',
        'custodian-komainu',
        'exchange-okx',
        'market-data-coinmetrics',
        'risk-monitor-lh',
        'trading-engine-lh',
        'test-coordinator',
    ]

    service_mapping = {}  # container_name -> node_id

    # Extract nodes (services)
    for service_name, service_config in services.items():
        container_name = service_config.get('container_name', f'trading-ecosystem-{service_name}')

        # Only include trading ecosystem services
        short_name = container_name.replace('trading-ecosystem-', '')
        if short_name not in trading_services:
            continue

        node_id = f"node-{short_name}"
        service_type = extract_service_type(container_name)
        category = extract_service_category(service_type)

        # Extract port mappings
        ports = service_config.get('ports', [])
        grpc_port = None
        http_port = None

        for port_mapping in ports:
            if isinstance(port_mapping, str):
                # Format: "host:container" or "host_ip:host:container"
                parts = port_mapping.split(':')
                if len(parts) >= 2:
                    host_port = parts[-2]
                    container_port = parts[-1].split('/')[0]  # Remove /tcp if present

                    # Heuristic: ports 8xxx are HTTP, 50xxx are gRPC
                    if container_port.startswith('50') or container_port == '50051':
                        grpc_port = int(host_port)
                    elif container_port.startswith('8') or container_port == '8080':
                        http_port = int(host_port)

        # Extract network IP
        networks = service_config.get('networks', {})
        ip_address = None
        if isinstance(networks, dict):
            for network_name, network_config in networks.items():
                if isinstance(network_config, dict):
                    ip_address = network_config.get('ipv4_address')
                    break

        node = {
            'id': node_id,
            'name': short_name.replace('-', ' ').title(),
            'service_type': service_type,
            'category': category,
            'status': 'LIVE',  # Default to LIVE on startup
            'version': '1.0.0',
            'endpoints': {
                'grpc': f'localhost:{grpc_port}' if grpc_port else None,
                'http': f'localhost:{http_port}' if http_port else None,
                'internal_ip': ip_address,
            },
            'health': {
                'cpu_percent': 0.0,
                'memory_mb': 0.0,
                'total_requests': 0,
                'total_errors': 0,
                'error_rate': 0.0,
            }
        }

        nodes.append(node)
        service_mapping[short_name] = node_id

    # Define edges (service connections)
    # These are the known communication patterns in the trading ecosystem
    edge_definitions = [
        # Risk monitor connects to trading engine
        ('risk-monitor-lh', 'trading-engine-lh', 'gRPC', 'monitors'),

        # Trading engine connects to exchange
        ('trading-engine-lh', 'exchange-okx', 'gRPC', 'trades_via'),

        # Trading engine connects to custodian
        ('trading-engine-lh', 'custodian-komainu', 'gRPC', 'custodies_via'),

        # Market data flows to trading engine
        ('market-data-coinmetrics', 'trading-engine-lh', 'gRPC', 'provides_data_to'),

        # Audit correlator monitors all services
        ('audit-correlator', 'risk-monitor-lh', 'gRPC', 'audits'),
        ('audit-correlator', 'trading-engine-lh', 'gRPC', 'audits'),
        ('audit-correlator', 'exchange-okx', 'gRPC', 'audits'),
        ('audit-correlator', 'custodian-komainu', 'gRPC', 'audits'),
        ('audit-correlator', 'market-data-coinmetrics', 'gRPC', 'audits'),

        # Test coordinator orchestrates tests
        ('test-coordinator', 'trading-engine-lh', 'gRPC', 'tests'),
        ('test-coordinator', 'risk-monitor-lh', 'gRPC', 'tests'),
    ]

    for source_name, target_name, protocol, relationship in edge_definitions:
        if source_name in service_mapping and target_name in service_mapping:
            edge_id = f"edge-{source_name}-to-{target_name}"
            edge = {
                'id': edge_id,
                'source_id': service_mapping[source_name],
                'target_id': service_mapping[target_name],
                'protocol': protocol,
                'relationship': relationship,
                'status': 'ACTIVE',
                'metrics': {
                    'latency_p50_ms': 10.0,
                    'latency_p99_ms': 50.0,
                    'throughput_rps': 100.0,
                    'error_rate': 0.001,
                }
            }
            edges.append(edge)

    return {
        'version': '1.0',
        'generated_at': 'startup',
        'nodes': nodes,
        'edges': edges,
    }


def main():
    """Generate topology configuration."""
    script_dir = Path(__file__).parent
    orchestrator_dir = script_dir.parent
    compose_file = orchestrator_dir / 'docker-compose.yml'
    output_file = orchestrator_dir / 'config' / 'topology.json'

    if not compose_file.exists():
        print(f"Error: {compose_file} not found", file=sys.stderr)
        sys.exit(1)

    # Ensure config directory exists
    output_file.parent.mkdir(exist_ok=True)

    # Parse and generate topology
    topology = parse_docker_compose(compose_file)

    # Write output
    with open(output_file, 'w') as f:
        json.dump(topology, f, indent=2)

    print(f"✅ Generated topology configuration: {output_file}")
    print(f"   Nodes: {len(topology['nodes'])}")
    print(f"   Edges: {len(topology['edges'])}")

    # Print summary
    print("\n📊 Services:")
    for node in topology['nodes']:
        print(f"   - {node['name']} ({node['service_type']}) - {node['category']}")


if __name__ == '__main__':
    main()
