#!/bin/bash
# Script to manage Docker Compose services for trading-formation

case "$1" in
    start)
        echo "Starting services with build..."
        docker compose up --build -d
        ;;
    kill)
        echo "Stopping and removing containers..."
        docker compose down
        ;;
    delete)
        echo "Purging Docker containers, images, and volumes..."
        docker compose down
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
        echo "Usage: $0 {start|kill|delete|config}"
        echo "  start  - Build and start services in detached mode"
        echo "  kill   - Stop and remove containers"
        echo "  delete - Purge containers, images, and volumes"
        echo "  config - Generate service configuration files from encrypted secrets"
        exit 1
        ;;
esac