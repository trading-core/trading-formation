#!/bin/bash
# Script to manage Docker Compose services for trading-formation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_CMD=(docker compose -f "$SCRIPT_DIR/docker-compose.yml" --project-directory "$SCRIPT_DIR")

case "$1" in
    start)
        echo "Starting services with build..."
        "${COMPOSE_CMD[@]}" up --build -d
        ;;
    up)
        echo "Starting services without build..."
        "${COMPOSE_CMD[@]}" up -d
        ;;
    kill)
        echo "Stopping and removing containers..."
        "${COMPOSE_CMD[@]}" down --remove-orphans
        ;;
    delete)
        echo "Purging project containers, images, and volumes..."
        "${COMPOSE_CMD[@]}" down --volumes --remove-orphans --rmi local
        docker container prune -f
        docker image prune -f
        docker volume prune -f
        echo "Docker purge completed"
        ;;
    config)
        echo "Generating service configuration files..."
        sudo ansible-playbook playbook.yml --ask-vault-pass
        ;;
    *)
        echo "Usage: $0 {start|up|kill|delete|config}"
        echo "  start  - Build and start services in detached mode"
        echo "  up     - Start services in detached mode without building"
        echo "  kill   - Stop and remove containers"
        echo "  delete - Purge containers, images, and volumes"
        echo "  config - Generate service configuration files from encrypted secrets"
        exit 1
        ;;
esac