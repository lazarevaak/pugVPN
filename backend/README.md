# pug_vpn_backend (Dart Frog + Postgres)

Backend API for the Flutter VPN client:
- login/token
- devices registration
- VPN server list
- client config issue (`amneziawg`)
- optional peer provisioning on real VPN server (`off` / `local` / `ssh`)
- session heartbeat

The backend now persists data in `Postgres`. On startup it automatically:
- applies SQL migrations from `backend/migrations`
- seeds one demo user
- upserts one server definition from env/secrets
- enforces login rate limiting
- runs server preflight before config issuance

## 1) Install tools

```bash
dart pub global activate dart_frog_cli
```

Add pub cache bin to `PATH` if needed:

```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
```

## 2) Local run with Postgres

Start Postgres first:

```bash
docker run --name pugvpn-postgres \
  -e POSTGRES_DB=pugvpn \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -d postgres:17-alpine
```

Then run the API:

```bash
cd backend
cp .env.example .env
cp secrets.json.example secrets.json
dart pub get
export $(grep -v '^#' .env | xargs)
dart_frog dev --host 0.0.0.0 --port 8080
```

Important env vars:

```bash
export PUGVPN_DATABASE_URL="postgresql://postgres:postgres@127.0.0.1:5432/pugvpn?sslmode=disable"
export PUGVPN_DEMO_EMAIL="demo@pugvpn.app"
export PUGVPN_DEMO_PASSWORD="demo1234"
export PUGVPN_PASSWORD_HASH_ITERATIONS="150000"
export PUGVPN_AUTH_RATE_LIMIT_WINDOW_MINUTES="15"
export PUGVPN_AUTH_RATE_LIMIT_MAX_ATTEMPTS="8"
export PUGVPN_PREFLIGHT_TCP_TIMEOUT_MS="3000"

export PUGVPN_SERVER_ID="srv_fi_1"
export PUGVPN_SERVER_NAME="Finland #1"
export PUGVPN_SERVER_LOCATION="FI"
export PUGVPN_SERVER_ENDPOINT="$(jq -r '.server_endpoint' secrets.json)"
export PUGVPN_SERVER_PUBLIC_KEY="$(jq -r '.server_public_key' secrets.json)"
export PUGVPN_SERVER_SUBNET="10.77.77"
export PUGVPN_SERVER_DNS="1.1.1.1,8.8.8.8"
export PUGVPN_SERVER_MTU="1000"
export PUGVPN_AWG_JC="7"
export PUGVPN_AWG_JMIN="40"
export PUGVPN_AWG_JMAX="250"
export PUGVPN_AWG_S1="53"
export PUGVPN_AWG_S2="71"
export PUGVPN_AWG_S3="29"
export PUGVPN_AWG_S4="17"
export PUGVPN_AWG_H1="19485731"
export PUGVPN_AWG_H2="58291473"
export PUGVPN_AWG_H3="73194582"
export PUGVPN_AWG_H4="26518497"
```

## 2a) Run API in Docker Compose

```bash
cd backend
cp .env.example .env
cp secrets.json.example secrets.json
# edit .env and secrets.json for your server/public key/settings

docker compose up -d --build
docker compose logs -f postgres
docker compose logs -f backend
```

Healthcheck:

```bash
curl http://127.0.0.1:8080/health
```

## 3) Database model

Schema is versioned via SQL migrations in `backend/migrations`. Applied versions are tracked in `schema_migrations`.

- `users`: accounts allowed to log in
- `servers`: VPN nodes visible to clients
- `sessions`: bearer tokens with expiry
- `devices`: one row per issued device/public key
- `peers`: provisioning/provision status per device
- `heartbeats`: connection status samples
- `audit_logs`: security and operational audit trail

Address allocation is now global per server, not per user. That avoids IP collisions between different users on the same VPN node.

## 4) Demo credentials

- email: `demo@pugvpn.app`
- password: `demo1234`

Override with `PUGVPN_DEMO_EMAIL` / `PUGVPN_DEMO_PASSWORD`.

## 5) Peer provisioning modes

Set `PUGVPN_PROVISION_MODE`:
- `off` (default): backend only returns config.
- `local`: backend appends peer to server config locally and restarts interface.
- `ssh`: backend provisions peer via SSH.

For `ssh` mode:

```bash
export PUGVPN_PROVISION_MODE="ssh"
export PUGVPN_PROVISION_SSH_HOST="$(jq -r '.provision_ssh_host' secrets.json)"
export PUGVPN_PROVISION_SSH_USER="root"
export PUGVPN_PROVISION_SSH_PORT="22"
export PUGVPN_PROVISION_SSH_KEY_PATH="/path/to/private_key"
export PUGVPN_PROVISION_INTERFACE="awg0"
```

If you run in Docker and use `ssh` provisioning:
- keep the SSH key volume mounted in `docker-compose.yml`
- set `PUGVPN_PROVISION_SSH_KEY_PATH` to the in-container path, for example `/root/.ssh/pugvpn_waicore`

Sensitive endpoint/key values can stay in `secrets.json`:

```json
{
  "server_endpoint": "YOUR_SERVER_IP_OR_DOMAIN:443",
  "server_public_key": "YOUR_SERVER_PUBLIC_KEY",
  "provision_ssh_host": "YOUR_SERVER_IP_OR_DOMAIN"
}
```

Secret sources are loaded in this order:
- `PUGVPN_SECRETS_JSON`
- `PUGVPN_SECRETS_COMMAND`
- `PUGVPN_SECRETS_FILE`

Example external secret command:

```bash
export PUGVPN_SECRETS_COMMAND='op read "op://vault/item/secrets_json"'
```

`PUGVPN_SECRETS_FILE` defaults to `secrets.json`.

## 6) Endpoints

- `GET /`
- `GET /health`
- `POST /auth/login`
- `POST /auth/logout`
- `GET /me`
- `GET /devices`
- `POST /devices`
- `DELETE /devices/:id`
- `POST /devices/:id/reissue`
- `DELETE /sessions/:token`
- `GET /vpn/servers`
- `POST /vpn/config`
- `POST /session/heartbeat`

## 7) Quick API flow

```bash
# 1) Login
curl -X POST http://127.0.0.1:8080/auth/login \
  -H "content-type: application/json" \
  -d '{"email":"demo@pugvpn.app","password":"demo1234"}'

# 2) Get servers
curl http://127.0.0.1:8080/vpn/servers \
  -H "authorization: Bearer <TOKEN>"

# 3) Request VPN config
curl -X POST http://127.0.0.1:8080/vpn/config \
  -H "authorization: Bearer <TOKEN>" \
  -H "content-type: application/json" \
  -d '{
    "server_id":"srv_fi_1",
    "device_name":"iPhone 15",
    "device_public_key":"CLIENT_PUBLIC_KEY_EXAMPLE"
  }'
```

## 8) Notes

- Client private key is still generated on-device; backend returns a config template with `PrivateKey = <CLIENT_PRIVATE_KEY_FROM_DEVICE>`.
- Token storage is now persistent, but token format is still opaque random bearer strings, not JWT.
- The backend seeds one server from env on startup. You can insert more rows into `servers` directly in Postgres if needed.
- Passwords are now stored with PBKDF2-SHA256. Legacy salted-SHA256 hashes are upgraded on successful login.
- `POST /vpn/config` now refuses to issue config when endpoint reachability, provisioning readiness, or IP capacity checks fail.
- Repeated config requests with the same `public_key` are idempotent. `DELETE /devices/:id` revokes the peer, and `POST /devices/:id/reissue` replaces the key on the same device/IP.
- `GET /me` returns the current user and active sessions. `POST /auth/logout` revokes the current bearer token. `DELETE /sessions/:token` revokes one specific active session.
