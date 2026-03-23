#!/bin/bash
# Script to manage Docker Compose services for trading-formation

case "$1" in
    start)
        echo "Starting services with build..."
        docker compose up --build -d
        ;;
    stop)
        echo "Pausing services..."
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
    *)
        echo "Usage: $0 {start|stop|delete|restart}"
        echo "  start   - Build and start services in detached mode"
        echo "  stop    - Pause services (containers remain)"
        echo "  delete  - Stop and remove all services"
        echo "  restart - Stop, rebuild, and restart services"
        exit 1
        ;;
esac