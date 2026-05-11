# Deployment Scripts

These scripts manage building and deploying the trading stack to `kduong-server`.

## Prerequisites

- SSH access to `kduong-server` (configured via `~/.ssh/config`)
- `.env` files and `docker-compose.yml` rendered locally via `./run-services.sh render`

## Workflow

### After `render` (or when secrets change)

```bash
./scripts/sync-envs.sh
```

Pushes `docker-compose.yml` and all `.env` files to the server. These are not committed to git.

### To build and deploy

```bash
# 1. Push and watch in one command — notifies via Windows desktop when done
./scripts/watch-build.sh --push

# 2. Deploy once notified
./scripts/deploy.sh
```

Or if you want to watch a build already in progress:

```bash
./scripts/watch-build.sh
```

### If the build fails

```bash
ssh kduong-server 'cat /opt/trading-core/.build.log'
```

## Scripts

| Script | Description |
|--------|-------------|
| `sync-envs.sh` | SCP `docker-compose.yml` and `.env` files to server |
| `watch-build.sh` | Poll build status and notify on completion |
| `deploy.sh` | Run `docker compose up -d` on server with pre-built images |
