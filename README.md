# trading-formation

Orchestrates frontend + backend services for local development with Docker Compose.

## Setup

1. Copy per-service env examples and fill in real secrets (do not commit `.env`):

   ```bash
   cp backend/account-service/.env.example backend/account-service/.env
   cp backend/stock-screener/.env.example backend/stock-screener/.env
   cp backend/authentication-service/.env.example backend/authentication-service/.env
   cp frontend/.env.example frontend/.env
   # or on Windows
   copy backend\account-service\.env.example backend\account-service\.env
   copy backend\stock-screener\.env.example backend\stock-screener\.env
   copy backend\authentication-service\.env.example backend\authentication-service\.env
   copy frontend\.env.example frontend\.env
   ```

2. Build and run everything in one command:
   
   ```bash
   docker compose up --build
   ```

   Or use the convenience script:

   ```bash
   # On Windows
   run-services.bat start

   # On Linux/Mac
   ./run-services.sh start
   ```

   To pause services (containers remain):

   ```bash
   run-services.bat stop
   ./run-services.sh stop
   ```

   To delete all services and containers:

   ```bash
   run-services.bat delete
   ./run-services.sh delete
   ```

   To restart (rebuild and restart):

   ```bash
   run-services.bat restart
   ./run-services.sh restart
   ```

3. Access:
   - Frontend: http://localhost:3000
   - Account Service: http://localhost:9000
   - Stock Screener: http://localhost:8080

---

## Services

- `frontend`: builds `trading-formation/frontend` (Next.js)
- `account-service`: builds `trading-formation/backend/account-service`
- `stock-screener`: builds `trading-formation/backend/stock-screener`
- `authentication-service`: builds `trading-formation/backend/authentication-service`

## Secrets management

- Keep actual secrets in environment variables (`.env`, `.env.backend`, `.env.frontend`)
- Check in `.env.example` only
- `.gitignore` already excludes `.env` and related files

## Ansible Vault secret workflow

1. Ensure `ansible` is installed.
2. Encrypt secrets file:

```bash
cd trading-formation
ansible-vault encrypt secrets.yml
```

3. Populate `secrets.yml` (or use existing placeholders in `secrets.yml`).
4. Run generation playbook (or use the convenience script which does this automatically):

```bash
cd trading-formation
ansible-playbook playbook.yml --ask-vault-pass
```

To generate env for only one service:

```bash
cd trading-formation
ansible-playbook playbook.yml --ask-vault-pass --tags account-service
ansible-playbook playbook.yml --ask-vault-pass --tags stock-screener
ansible-playbook playbook.yml --ask-vault-pass --tags frontend
```

Env content is now defined inline in these Ansible files:

- `trading-backend/cmd/account-service/formation.yml`
- `trading-backend/cmd/stock-screener/formation.yml`
- `trading-frontend/formation.yml`

5. Then start Docker Compose (or use the convenience script):

```bash
docker compose up --build
```

6. Keep `secrets.yml` encrypted and never commit a plain secrets file.

## Alternative per-service run options

```bash
# individual microservice
cd ../trading-backend
docker build --target builder -t account-service-backend --build-arg SERVICE=account-service .

docker run --rm -p 9000:9000 --env-file ../trading-formation/.env.backend account-service-backend
```
