#!/bin/bash
# Manage docker-compose for trading-formation, with optional per-service host
# proxying for in-loop debugging. When proxy.conf flags a service as 1, it is
# excluded from docker-compose and replaced by a socat proxy container that
# forwards <service>:<container_port> -> host.docker.internal:<container_port>,
# so dockerized siblings still reach it transparently.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

COMPOSE_CMD=(docker compose -f "$SCRIPT_DIR/docker-compose.yml" --project-directory "$SCRIPT_DIR")
PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$SCRIPT_DIR")}"
NETWORK_NAME="${PROJECT_NAME}_default"
PROXY_IMAGE="${PROXY_IMAGE:-alpine/socat}"
PROXY_CONF="proxy.conf"

SERVICES=(
    "account-service:ACCOUNT_SERVICE"
    "stock-screener:STOCK_SCREENER"
    "authentication-service:AUTH_SERVICE"
    "bot-service:BOT_SERVICE"
    "reporting-service:REPORTING_SERVICE"
    "storage-service:STORAGE_SERVICE"
    "journal-service:JOURNAL_SERVICE"
)

proxy_container_name() {
    echo "${PROJECT_NAME}-local-proxy-$1"
}

# Returns the container-side port for a service from docker-compose.yml,
# i.e. the right-hand side of "<host>:<container>" in ports:.
lookup_service_port() {
    awk -v svc="$1" '
        $0 ~ "^  " svc ":" { found=1; next }
        found && /^  [^ ]/ { found=0 }
        found && /- .*[0-9]+:[0-9]+/ {
            split($NF, a, ":")
            gsub(/[^0-9]/, "", a[2])
            print a[2]
            exit
        }
    ' docker-compose.yml
}

start_socat_proxy() {
    local service="$1"
    local port="$2"
    local proxy_name
    proxy_name="$(proxy_container_name "$service")"

    docker rm -f "$proxy_name" >/dev/null 2>&1 || true
    docker run -d \
        --name "$proxy_name" \
        --restart unless-stopped \
        --network "$NETWORK_NAME" \
        --network-alias "$service" \
        --add-host host.docker.internal:host-gateway \
        "$PROXY_IMAGE" \
        "tcp-listen:${port},fork,reuseaddr" "tcp:host.docker.internal:${port}" >/dev/null
}

stop_socat_proxy() {
    docker rm -f "$(proxy_container_name "$1")" >/dev/null 2>&1 || true
}

# Populates the global `proxied` array from proxy.conf. Empty if no conf file.
read_proxied_services() {
    proxied=()
    [[ -f "$PROXY_CONF" ]] || return 0
    # shellcheck disable=SC1090
    source "./$PROXY_CONF"
    for entry in "${SERVICES[@]}"; do
        svc="${entry%%:*}"
        var="${entry##*:}"
        val="${!var:-0}"
        if [[ "$val" == "1" ]]; then
            proxied+=("$svc")
        fi
    done
    return 0
}

require_compose_file() {
    if [[ ! -f docker-compose.yml ]]; then
        echo "docker-compose.yml not found. Run './run-services.sh render' first." >&2
        exit 1
    fi
}

bring_up() {
    local build_flag="${1:-}"
    require_compose_file
    read_proxied_services

    if [[ ${#proxied[@]} -eq 0 ]]; then
        echo "Starting all services..."
        "${COMPOSE_CMD[@]}" up ${build_flag} -d
        return
    fi

    local all=() dockerized=()
    for entry in "${SERVICES[@]}"; do all+=("${entry%%:*}"); done
    for s in "${all[@]}"; do
        local skip=0
        for p in "${proxied[@]}"; do
            if [[ "$s" == "$p" ]]; then
                skip=1
                break
            fi
        done
        if [[ $skip -eq 0 ]]; then
            dockerized+=("$s")
        fi
    done

    echo "Dockerized: ${dockerized[*]} frontend"
    echo "Proxied (host): ${proxied[*]}"
    "${COMPOSE_CMD[@]}" up ${build_flag} -d "${dockerized[@]}" frontend

    for svc in "${proxied[@]}"; do
        local port
        port="$(lookup_service_port "$svc")"
        if [[ -z "$port" ]]; then
            echo "WARN: no port found for '$svc' in docker-compose.yml; skipping socat proxy" >&2
            continue
        fi
        "${COMPOSE_CMD[@]}" rm -fs "$svc" >/dev/null 2>&1 || true
        echo "Socat proxy: $svc:$port -> host.docker.internal:$port"
        start_socat_proxy "$svc" "$port"
    done

    echo
    echo "Run each proxied service in its own terminal:"
    for svc in "${proxied[@]}"; do
        echo "  make -C ../trading-backend run-$svc"
    done
}

teardown_proxies() {
    [[ -f "$PROXY_CONF" ]] || return 0
    read_proxied_services
    for svc in "${proxied[@]}"; do stop_socat_proxy "$svc"; done
}

case "${1:-}" in
    start)
        bring_up "--build"
        ;;
    up)
        bring_up ""
        ;;
    kill)
        echo "Stopping containers and tearing down proxies..."
        teardown_proxies
        "${COMPOSE_CMD[@]}" down --remove-orphans
        ;;
    delete)
        echo "Purging containers, images, volumes, and proxies..."
        teardown_proxies
        "${COMPOSE_CMD[@]}" down --volumes --remove-orphans --rmi local
        docker container prune -f
        docker image prune -f
        docker volume prune -f
        echo "Docker purge completed"
        ;;
    render)
        echo "Generating .env files and Makefile from secrets..."
        sudo ansible-playbook playbook.yml --ask-vault-pass
        ;;
    proxy)
        if [[ ! -f "$PROXY_CONF" ]]; then
            {
                echo "# Set a service to 1 to run it on the host (proxy mode)."
                echo "# 'start'/'up' will exclude flagged services from docker-compose and"
                echo "# spin up a socat container so dockerized siblings still reach them."
                echo
                for entry in "${SERVICES[@]}"; do
                    echo "${entry##*:}=0"
                done
            } > "$PROXY_CONF"
            echo "Created $PROXY_CONF."
        fi
        "${EDITOR:-vi}" "$PROXY_CONF"
        ;;
    status)
        read_proxied_services
        if [[ ${#proxied[@]} -eq 0 ]]; then
            echo "No proxied services configured."
        else
            for svc in "${proxied[@]}"; do
                name="$(proxy_container_name "$svc")"
                if docker ps --filter "name=^/${name}$" --filter "status=running" --format '{{.Names}}' | grep -Fxq "$name"; then
                    echo "running:     $name"
                else
                    echo "not running: $name"
                fi
            done
        fi
        ;;
    *)
        cat <<EOF
Usage: $0 <command>

  start    docker compose up --build -d   (proxy.conf flagged services routed via socat)
  up       docker compose up -d           (proxy.conf flagged services routed via socat)
  kill     Stop containers and tear down socat proxies
  delete   Purge containers, images, volumes
  render   Generate .env files and Makefile via ansible-playbook
  proxy    Seed/edit proxy.conf — flag a service as 1 to run it on the host
  status   Show whether each proxied service's socat container is running
EOF
        exit 1
        ;;
esac
