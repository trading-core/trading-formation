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
# 1. Push changes — triggers a background Docker build on the server
git push server main

# 2. Watch for completion (fires a Windows desktop notification when done)
./scripts/watch-build.sh

# 3. Deploy once notified
./scripts/deploy.sh
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
