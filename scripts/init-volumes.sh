#!/bin/bash
#
# Initialize Docker volumes for named service instances
# Creates data and logs directories with proper permissions
#
# Usage: ./scripts/init-volumes.sh
#

set -e

# Service instances to initialize
SERVICES=(
    "audit-correlator"      # Singleton
    "test-coordinator"      # Singleton
    "exchange-okx"          # Multi-instance example (lowercase for DNS-safe)
    "custodian-komainu"     # Multi-instance example (lowercase for DNS-safe)
    "market-data-coinmetrics"  # Multi-instance example (lowercase for DNS-safe)
    "trading-engine-lh"     # Multi-instance example (lowercase for DNS-safe)
    "risk-monitor-lh"       # Multi-instance example (lowercase for DNS-safe)
)

echo "Initializing Docker volumes for service instances..."
echo "=================================================="

for service in "${SERVICES[@]}"; do
    echo ""
    echo "Creating volumes for: ${service}"

    # Create data directory
    mkdir -p "./volumes/${service}/data"
    chmod 777 "./volumes/${service}/data"
    echo "  ✓ Created data volume: ./volumes/${service}/data"

    # Create logs directory
    mkdir -p "./volumes/${service}/logs"
    chmod 777 "./volumes/${service}/logs"
    echo "  ✓ Created logs volume: ./volumes/${service}/logs"
done

echo ""
echo "=================================================="
echo "Volume initialization complete!"
echo ""
echo "Directory structure:"
tree -L 2 ./volumes/ || find ./volumes/ -maxdepth 2 -type d

echo ""
echo "Next steps:"
echo "1. Start services: docker-compose up -d"
echo "2. Check logs: docker-compose logs -f [service-name]"
echo "3. Verify volumes: docker-compose exec [service-name] ls -la /app"
