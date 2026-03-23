# trading-formation

Orchestrates frontend + backend services for local development with Docker Compose.

## Setup

1. Copy per-service env examples and fill in real secrets (do not commit `.env`):

   ```bash
   cp account-service/.env.example account-service/.env
   cp stock-screener/.env.example stock-screener/.env
   cp frontend/.env.example frontend/.env
   # or on Windows
   copy account-service\.env.example account-service\.env
   copy stock-screener\.env.example stock-screener\.env
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

   To stop:

   ```bash
   run-services.bat stop
   ./run-services.sh stop
   ```

   To restart:

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
- `account-service`: builds `trading-formation/account-service`
- `stock-screener`: builds `trading-formation/stock-screener`

## Secrets management

- Keep actual secrets in environment variables (`.env`, `.env.backend`, `.env.frontend`)
- Check in `.env.example` only
- `.gitignore` already excludes `.env` and related files

## Ansible Vault secret workflow

1. Ensure `ansible` is installed.
2. Encrypt secrets file:

```bash
cd trading-formation
ansible-vault encrypt ansible/vault.yml
```

3. Populate `ansible/vault.yml` (or use existing placeholders in `ansible/vault.yml`).
4. Run generation playbook (or use the convenience script which does this automatically):

```bash
cd trading-formation
ansible-playbook ansible/playbook.yml --ask-vault-pass
```

5. Then start Docker Compose (or use the convenience script):

```bash
docker compose up --build
```

6. Keep `ansible/vault.yml` encrypted and never commit a plain secrets file.

## Alternative per-service run options

```bash
# individual microservice
cd ../trading-backend
docker build --target builder -t account-service-backend --build-arg SERVICE=account-service .

docker run --rm -p 9000:9000 --env-file ../trading-formation/.env.backend account-service-backend
```
