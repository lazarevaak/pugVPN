CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS servers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  endpoint TEXT NOT NULL,
  public_key TEXT NOT NULL,
  subnet TEXT NOT NULL,
  dns_servers TEXT NOT NULL,
  mtu INTEGER NOT NULL,
  awg_jc INTEGER NOT NULL,
  awg_jmin INTEGER NOT NULL,
  awg_jmax INTEGER NOT NULL,
  awg_s1 INTEGER NOT NULL,
  awg_s2 INTEGER NOT NULL,
  awg_s3 INTEGER NOT NULL,
  awg_s4 INTEGER NOT NULL,
  awg_h1 INTEGER NOT NULL,
  awg_h2 INTEGER NOT NULL,
  awg_h3 INTEGER NOT NULL,
  awg_h4 INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sessions (
  token TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS devices (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  server_id TEXT NOT NULL REFERENCES servers(id) ON DELETE RESTRICT,
  name TEXT NOT NULL,
  public_key TEXT NOT NULL,
  address TEXT NOT NULL,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (server_id, public_key),
  UNIQUE (server_id, address)
);

CREATE TABLE IF NOT EXISTS peers (
  id TEXT PRIMARY KEY,
  device_id TEXT NOT NULL UNIQUE REFERENCES devices(id) ON DELETE CASCADE,
  server_id TEXT NOT NULL REFERENCES servers(id) ON DELETE RESTRICT,
  public_key TEXT NOT NULL,
  allowed_ip TEXT NOT NULL,
  provisioning_mode TEXT NOT NULL,
  provisioning_state TEXT NOT NULL,
  last_error TEXT,
  provisioned_at TIMESTAMPTZ,
  last_heartbeat_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS heartbeats (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  server_id TEXT NOT NULL REFERENCES servers(id) ON DELETE RESTRICT,
  is_connected BOOLEAN NOT NULL,
  latency_ms INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit_logs (
  id TEXT PRIMARY KEY,
  event_type TEXT NOT NULL,
  severity TEXT NOT NULL,
  user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
  request_id TEXT,
  client_ip TEXT,
  target_type TEXT,
  target_id TEXT,
  details TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS sessions_user_id_idx ON sessions (user_id);
CREATE INDEX IF NOT EXISTS sessions_expires_at_idx ON sessions (expires_at);
CREATE INDEX IF NOT EXISTS devices_user_server_idx
  ON devices (user_id, server_id)
  WHERE revoked_at IS NULL;
CREATE INDEX IF NOT EXISTS heartbeats_device_idx
  ON heartbeats (device_id, created_at DESC);
CREATE INDEX IF NOT EXISTS audit_logs_event_created_idx
  ON audit_logs (event_type, created_at DESC);
CREATE INDEX IF NOT EXISTS audit_logs_target_idx
  ON audit_logs (target_type, target_id, created_at DESC);
CREATE INDEX IF NOT EXISTS audit_logs_client_ip_idx
  ON audit_logs (client_ip, created_at DESC);
