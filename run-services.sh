#!/bin/bash
# Script to manage Docker Compose services for trading-formation

case "$1" in
    start)
        echo "Starting services with build..."
        docker compose up --build -d
        ;;
    stop)
        echo "Stopping services..."
        docker compose stop
        ;;
    delete)
        echo "Deleting services..."
        docker compose down
        ;;
    restart)
        echo "Restarting services..."
        docker compose down
        docker compose up --build -d
        ;;
    config)
        echo "Generating service configuration files..."
        sudo ansible-playbook playbook.yml --ask-vault-pass
        ;;
    *)
        echo "Usage: $0 {start|stop|delete|restart|config}"
        echo "  start   - Build and start services in detached mode"
        echo "  stop    - Stop services (containers remain)"
        echo "  delete  - Stop and remove all services"
        echo "  restart - Stop, rebuild, and restart services"
        echo "  config  - Generate service configuration files from encrypted secrets"
        exit 1
        ;;
esac