# pug_vpn_backend (Dart Frog)

MVP backend for Flutter VPN client:
- login/token
- devices registration
- VPN server list
- client config issue (`amneziawg`)
- optional peer provisioning on real VPN server (`off` / `local` / `ssh`)
- session heartbeat

## 1) Install tools

```bash
dart pub global activate dart_frog_cli
```

Add pub cache bin to PATH (if needed):

```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
```

## 2) Run API

```bash
cd backend
dart pub get
export PUGVPN_SERVER_ID="srv_fi_1"
export PUGVPN_SERVER_NAME="Finland #1"
export PUGVPN_SERVER_LOCATION="FI"
# endpoint/key from secrets.json
export PUGVPN_SERVER_ENDPOINT="$(jq -r '.server_endpoint' secrets.json)"
export PUGVPN_SERVER_PUBLIC_KEY="$(jq -r '.server_public_key' secrets.json)"
export PUGVPN_SERVER_SUBNET="10.77.77"
export PUGVPN_SERVER_DNS="1.1.1.1,8.8.8.8"
export PUGVPN_SERVER_MTU="1200"
export PUGVPN_AWG_JC="4"
export PUGVPN_AWG_JMIN="64"
export PUGVPN_AWG_JMAX="512"
export PUGVPN_AWG_S1="32"
export PUGVPN_AWG_S2="40"
export PUGVPN_AWG_S3="24"
export PUGVPN_AWG_S4="16"
export PUGVPN_AWG_H1="11111111"
export PUGVPN_AWG_H2="22222222"
export PUGVPN_AWG_H3="33333333"
export PUGVPN_AWG_H4="44444444"
dart_frog dev --port 8080
```

## 2a) Run API in Docker

```bash
cd backend
cp .env.example .env
cp secrets.json.example secrets.json
# edit .env for your server/public key/settings

docker compose up -d --build
docker compose logs -f backend
```

Healthcheck:

```bash
curl http://127.0.0.1:8080/health
```

If you use `PUGVPN_PROVISION_MODE=ssh` inside container:
- mount host SSH keys by uncommenting the `volumes` section in
  `docker-compose.yml`;
- set `PUGVPN_PROVISION_SSH_KEY_PATH` in `.env` to container path
  (for example `/root/.ssh/pugvpn_waicore`).

You can keep sensitive endpoint/key values outside `.env` in `secrets.json`:

```json
{
  "server_endpoint": "YOUR_SERVER_IP_OR_DOMAIN:443",
  "server_public_key": "YOUR_SERVER_PUBLIC_KEY",
  "provision_ssh_host": "YOUR_SERVER_IP_OR_DOMAIN"
}
```

File path is configurable via `PUGVPN_SECRETS_FILE` (default: `secrets.json`).

## 3) Endpoints

- `GET /` - API info
- `GET /health` - healthcheck
- `POST /auth/login`
- `POST /devices`
- `GET /vpn/servers`
- `POST /vpn/config`
- `POST /session/heartbeat`

## Demo credentials

- email: `demo@pugvpn.app`
- password: `demo1234`

## Notes

- Storage is in-memory for fast MVP bootstrap.
- For production, replace store with Postgres and move token logic to JWT.
- Client private key is generated on-device; backend returns config template with
  `PrivateKey = <CLIENT_PRIVATE_KEY_FROM_DEVICE>`.

### Peer provisioning modes

Set `PUGVPN_PROVISION_MODE`:
- `off` (default): backend only returns config.
- `local`: backend appends peer to server config locally and restarts interface.
  Works when backend runs on VPN server with enough permissions.
- `ssh`: backend provisions peer via SSH.

For `ssh` mode, set:

```bash
export PUGVPN_PROVISION_MODE="ssh"
export PUGVPN_PROVISION_SSH_HOST="$(jq -r '.provision_ssh_host' secrets.json)"
export PUGVPN_PROVISION_SSH_USER="root"
export PUGVPN_PROVISION_SSH_PORT="22"
export PUGVPN_PROVISION_SSH_KEY_PATH="/path/to/private_key"
# optional; default awg0
export PUGVPN_PROVISION_INTERFACE="awg0"
```

## 4) Quick API flow

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

## 5) Flutter wiring (next step)

- Replace fake delay in client with real HTTP calls:
  - login -> store access token
  - load server list
  - request `/vpn/config`
  - pass `vpn_conf` / `amneziawg_conf` to platform VPN plugin
    (Android/iOS native APIs)
