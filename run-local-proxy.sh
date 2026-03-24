#!/bin/bash
# Run Docker Compose with one service proxied to a locally running process.
# Example:
#   ./run-local-proxy.sh start stock-screener 8080
# This will stop/remove the Docker stock-screener service and create a proxy
# container reachable as "stock-screener" from other containers, forwarding
# to host.docker.internal:8080.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$SCRIPT_DIR")}"
NETWORK_NAME="${PROJECT_NAME}_default"
PROXY_IMAGE="${PROXY_IMAGE:-alpine/socat}"

usage() {
    echo "Usage: $0 {start|stop|status} <service-name> [local-port] [service-port]"
    echo "  start  - Start compose, replace service with local proxy"
    echo "           local-port: port your local service listens on"
    echo "           service-port: port expected by other containers (defaults to local-port)"
    echo "  stop   - Remove proxy and restore the dockerized service"
    echo "  status - Show whether proxy container is running"
    exit 1
}

proxy_container_name() {
    local service="$1"
    echo "${PROJECT_NAME}-local-proxy-${service}"
}

service_exists() {
    local service="$1"
    docker compose config --services | grep -Fxq "$service"
}

ensure_network() {
    if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
        docker compose up -d
    fi
}

start_proxy() {
    local service="$1"
    local local_port="$2"
    local service_port="${3:-$2}"
    local proxy_name
    proxy_name="$(proxy_container_name "$service")"

    if ! service_exists "$service"; then
        echo "Error: service '$service' does not exist in docker-compose.yml"
        exit 1
    fi

    echo "Starting compose services..."
    docker compose up --build -d

    echo "Stopping/removing dockerized service '$service'..."
    docker compose stop "$service" || true
    docker compose rm -f "$service" || true

    docker rm -f "$proxy_name" >/dev/null 2>&1 || true

    ensure_network

    echo "Starting proxy '$proxy_name': $service:$service_port -> host.docker.internal:$local_port"
    docker run -d \
        --name "$proxy_name" \
        --restart unless-stopped \
        --network "$NETWORK_NAME" \
        --network-alias "$service" \
        --add-host host.docker.internal:host-gateway \
        "$PROXY_IMAGE" \
        tcp-listen:${service_port},fork,reuseaddr tcp:host.docker.internal:${local_port} >/dev/null

    echo "Proxy active. Containers can call '$service:$service_port' and reach your local process."
}

stop_proxy() {
    local service="$1"
    local proxy_name
    proxy_name="$(proxy_container_name "$service")"

    if ! service_exists "$service"; then
        echo "Error: service '$service' does not exist in docker-compose.yml"
        exit 1
    fi

    echo "Removing proxy '$proxy_name'..."
    docker rm -f "$proxy_name" >/dev/null 2>&1 || true

    echo "Restoring dockerized service '$service'..."
    docker compose up -d "$service"
}

status_proxy() {
    local service="$1"
    local proxy_name
    proxy_name="$(proxy_container_name "$service")"

    if docker ps --filter "name=^/${proxy_name}$" --filter "status=running" --format '{{.Names}}' | grep -Fxq "$proxy_name"; then
        echo "running: $proxy_name"
    else
        echo "not running: $proxy_name"
        exit 1
    fi
}

ACTION="${1:-}"
SERVICE="${2:-}"
LOCAL_PORT="${3:-}"
SERVICE_PORT="${4:-}"

case "$ACTION" in
    start)
        if [ -z "$SERVICE" ] || [ -z "$LOCAL_PORT" ]; then
            usage
        fi
        start_proxy "$SERVICE" "$LOCAL_PORT" "$SERVICE_PORT"
        ;;
    stop)
        if [ -z "$SERVICE" ]; then
            usage
        fi
        stop_proxy "$SERVICE"
        ;;
    status)
        if [ -z "$SERVICE" ]; then
            usage
        fi
        status_proxy "$SERVICE"
        ;;
    *)
        usage
        ;;
esac
