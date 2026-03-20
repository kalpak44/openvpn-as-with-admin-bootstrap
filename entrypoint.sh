#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[openvpn-bootstrap] $*"
}

# -----------------------------
# Variable priority
# Highest priority first:
# 1) *_FILE secret-backed vars
# 2) direct env vars
# 3) built-in defaults
# -----------------------------
resolve_value() {
  local var_name="$1"
  local default_value="${2:-}"
  local file_var_name="${var_name}_FILE"

  local direct_value="${!var_name:-}"
  local file_path="${!file_var_name:-}"

  if [[ -n "$file_path" ]]; then
    if [[ ! -f "$file_path" ]]; then
      log "ERROR: ${file_var_name} points to missing file: $file_path"
      exit 1
    fi
    cat "$file_path"
    return 0
  fi

  if [[ -n "$direct_value" ]]; then
    printf '%s' "$direct_value"
    return 0
  fi

  printf '%s' "$default_value"
}

OPENVPN_ADMIN_USERNAME="$(resolve_value OPENVPN_ADMIN_USERNAME admin)"
OPENVPN_ADMIN_PASSWORD="$(resolve_value OPENVPN_ADMIN_PASSWORD '')"
OPENVPN_BOOTSTRAP_ADMIN="$(resolve_value OPENVPN_BOOTSTRAP_ADMIN true)"
OPENVPN_BOOTSTRAP_TIMEOUT_SECONDS="$(resolve_value OPENVPN_BOOTSTRAP_TIMEOUT_SECONDS 120)"
OPENVPN_BOOTSTRAP_ONCE="$(resolve_value OPENVPN_BOOTSTRAP_ONCE true)"

MARKER_FILE="/openvpn/etc/admin_user_bootstrapped"
SACLI_DIR="/usr/local/openvpn_as/scripts"
SACLI="${SACLI_DIR}/sacli"

bootstrap_admin_user() {
  if [[ "${OPENVPN_BOOTSTRAP_ADMIN,,}" != "true" ]]; then
    log "Admin bootstrap disabled"
    return 0
  fi

  if [[ -z "$OPENVPN_ADMIN_PASSWORD" ]]; then
    log "OPENVPN_ADMIN_PASSWORD is empty; skipping admin bootstrap"
    return 0
  fi

  if [[ "${OPENVPN_BOOTSTRAP_ONCE,,}" == "true" && -f "$MARKER_FILE" ]]; then
    log "Bootstrap marker exists; skipping admin bootstrap"
    return 0
  fi

  log "Waiting for Access Server agent to become ready..."

  local waited=0
  while (( waited < OPENVPN_BOOTSTRAP_TIMEOUT_SECONDS )); do
    if cd "$SACLI_DIR" && "$SACLI" VPNStatus >/dev/null 2>&1; then
      log "Access Server is ready"
      break
    fi
    sleep 2
    waited=$((waited + 2))
  done

  if ! cd "$SACLI_DIR" || ! "$SACLI" VPNStatus >/dev/null 2>&1; then
    log "ERROR: Access Server was not ready within ${OPENVPN_BOOTSTRAP_TIMEOUT_SECONDS}s"
    return 1
  fi

  log "Configuring admin user '${OPENVPN_ADMIN_USERNAME}'"

  "$SACLI" --user "$OPENVPN_ADMIN_USERNAME" --new_pass "$OPENVPN_ADMIN_PASSWORD" SetLocalPassword
  "$SACLI" --user "$OPENVPN_ADMIN_USERNAME" --key "prop_superuser" --value "true" UserPropPut
  "$SACLI" --user "$OPENVPN_ADMIN_USERNAME" --key "type" --value "user_connect" UserPropPut || true

  if [[ "${OPENVPN_BOOTSTRAP_ONCE,,}" == "true" ]]; then
    mkdir -p "$(dirname "$MARKER_FILE")"
    touch "$MARKER_FILE"
    log "Bootstrap marker written to $MARKER_FILE"
  fi

  log "Admin bootstrap completed"
}

log "Starting original OpenVPN Access Server entrypoint"
/docker-entrypoint.sh "$@" &
main_pid=$!

bootstrap_admin_user || log "Bootstrap failed; server will continue running"

log "Handing over to main process"
wait "$main_pid"