# OpenVPN Access Server with Admin Bootstrap

Thin wrapper image around the official `openvpn/openvpn-as` image that bootstraps a local admin user after Access Server starts.

## What it does

- keeps the official OpenVPN Access Server startup flow
- waits until the internal Access Server agent is ready
- creates or updates an admin user from environment variables
- optionally runs only once per persisted `/openvpn` data volume

## Files

- `Dockerfile` — wrapper image definition
- `entrypoint.sh` — starts the official entrypoint, then bootstraps admin
- `.env.example` — example configuration
- `.gitignore` — ignores secrets and local artifacts

## Environment variables

### Priority order

For every supported variable, values are resolved in this order:

1. `*_FILE` secret file path
2. direct environment variable
3. built-in default

Example:
- `OPENVPN_ADMIN_PASSWORD_FILE=/run/secrets/openvpn_admin_password`
- otherwise `OPENVPN_ADMIN_PASSWORD=...`
- otherwise default if one exists

### Supported variables

#### Required for bootstrap

- `OPENVPN_ADMIN_USERNAME`
  - default: `admin`

- `OPENVPN_ADMIN_PASSWORD`
  - default: empty
  - if empty, bootstrap is skipped

#### Optional

- `OPENVPN_BOOTSTRAP_ADMIN`
  - default: `true`
  - set to `false` to disable bootstrap logic completely

- `OPENVPN_BOOTSTRAP_TIMEOUT_SECONDS`
  - default: `120`
  - how long to wait for Access Server readiness

- `OPENVPN_BOOTSTRAP_ONCE`
  - default: `true`
  - `true`: bootstrap only once per persisted data volume
  - `false`: re-apply password and admin role on every start

### Secret file variants

You can use these file-backed variants instead of direct values:

- `OPENVPN_ADMIN_USERNAME_FILE`
- `OPENVPN_ADMIN_PASSWORD_FILE`
- `OPENVPN_BOOTSTRAP_ADMIN_FILE`
- `OPENVPN_BOOTSTRAP_TIMEOUT_SECONDS_FILE`
- `OPENVPN_BOOTSTRAP_ONCE_FILE`

## Build

```bash
docker build -t openvpn-as-with-admin-bootstrap .