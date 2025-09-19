#!/bin/bash

# Trading Ecosystem Infrastructure Management Script
# Simplified commands for common infrastructure operations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Change to project directory
cd "$PROJECT_DIR"

show_help() {
    cat << EOF
Trading Ecosystem Infrastructure Manager

Usage: $0 <command> [options]

Commands:
    start           Start all infrastructure services
    stop            Stop all services (keeps volumes)
    restart         Restart all services
    clean           Stop services and remove volumes (complete cleanup)
    status          Show service status
    validate        Run infrastructure validation
    logs [service]  Show logs (all services or specific service)
    health          Quick health check of all services

Examples:
    $0 start                    # Start all services
    $0 logs                     # Show all logs
    $0 logs redis               # Show Redis logs only
    $0 validate                 # Run full validation
    $0 clean                    # Complete cleanup

Services: redis, postgres, service-registry, prometheus, grafana, jaeger, otel-collector
EOF
}

case "${1:-}" in
    start)
        echo "🚀 Starting Trading Ecosystem Infrastructure..."
        docker-compose up -d
        echo "✅ Infrastructure started. Run '$0 validate' to check health."
        ;;

    stop)
        echo "🛑 Stopping infrastructure services..."
        docker-compose down
        echo "✅ Services stopped (volumes preserved)"
        ;;

    restart)
        echo "🔄 Restarting infrastructure services..."
        docker-compose restart
        echo "✅ Services restarted"
        ;;

    clean)
        echo "🧹 Cleaning up infrastructure (removes volumes)..."
        docker-compose down -v
        echo "✅ Complete cleanup finished"
        ;;

    status)
        echo "📊 Infrastructure Service Status:"
        docker-compose ps
        ;;

    validate)
        echo "🔍 Running infrastructure validation..."
        "$SCRIPT_DIR/validate-infrastructure.sh"
        ;;

    logs)
        if [ -n "${2:-}" ]; then
            echo "📝 Showing logs for service: $2"
            docker-compose logs -f "$2"
        else
            echo "📝 Showing logs for all services (Ctrl+C to exit)"
            docker-compose logs -f
        fi
        ;;

    health)
        echo "🏥 Quick health check..."
        echo -n "Redis: "
        if redis-cli -h localhost -p 6379 --no-auth-warning -u "redis://healthcheck:health-pass@localhost:6379" ping >/dev/null 2>&1; then
            echo "✅ OK"
        else
            echo "❌ FAIL"
        fi

        echo -n "PostgreSQL: "
        if pg_isready -h localhost -p 5432 -U postgres >/dev/null 2>&1; then
            echo "✅ OK"
        else
            echo "❌ FAIL"
        fi

        echo -n "Service Registry: "
        if curl -f http://localhost:8080/health >/dev/null 2>&1; then
            echo "✅ OK"
        else
            echo "❌ FAIL"
        fi

        echo -n "Prometheus: "
        if curl -f http://localhost:9090/-/healthy >/dev/null 2>&1; then
            echo "✅ OK"
        else
            echo "❌ FAIL"
        fi

        echo -n "Grafana: "
        if curl -f http://localhost:3000/api/health >/dev/null 2>&1; then
            echo "✅ OK"
        else
            echo "❌ FAIL"
        fi
        ;;

    help|--help|-h)
        show_help
        ;;

    *)
        echo "❌ Unknown command: ${1:-}"
        echo
        show_help
        exit 1
        ;;
esac