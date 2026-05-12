#!/bin/bash
set -euo pipefail

# setupduckdns.sh
# Adds DuckDNS dynamic DNS updating to an existing noVNC/TigerVNC setup.
# This script does NOT reinstall VNC. It only keeps your DuckDNS hostname updated
# and prints the access URL for your current noVNC setup.

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root or with sudo privileges."
  exit 1
fi

DUCKDNS_DIR="/etc/duckdns"
DUCKDNS_CONF="$DUCKDNS_DIR/duckdns.conf"
DUCKDNS_UPDATE_SCRIPT="/usr/local/bin/duckdns-update.sh"
DUCKDNS_SERVICE="/etc/systemd/system/duckdns-update.service"
DUCKDNS_TIMER="/etc/systemd/system/duckdns-update.timer"
DUCKDNS_LOG="/var/log/duckdns.log"

get_novnc_port() {
  local port=""
  if systemctl list-unit-files | grep -q '^novnc\.service'; then
    port=$(systemctl show -p ExecStart --value novnc 2>/dev/null | awk -F'--listen ' '{print $2}' | awk '{print $1}' | tr -d '"' || true)
  fi
  if [ -z "${port:-}" ]; then
    port="6080"
  fi
  echo "$port"
}

get_vnc_port() {
  local display="${1:-:1}"
  echo $((5900 + ${display#:}))
}

install_packages() {
  export DEBIAN_FRONTEND=noninteractive
  apt update
  apt install -y curl ca-certificates
}

prompt_duckdns_config() {
  echo "Enter your DuckDNS subdomain (example: myhome for myhome.duckdns.org):"
  read -r DUCKDNS_DOMAIN
  DUCKDNS_DOMAIN="${DUCKDNS_DOMAIN,,}"

  if [ -z "$DUCKDNS_DOMAIN" ]; then
    echo "DuckDNS subdomain cannot be empty."
    exit 1
  fi

  echo "Enter your DuckDNS token:"
  read -rs DUCKDNS_TOKEN
  echo

  if [ -z "$DUCKDNS_TOKEN" ]; then
    echo "DuckDNS token cannot be empty."
    exit 1
  fi
}

write_config() {
  mkdir -p "$DUCKDNS_DIR"
  chmod 700 "$DUCKDNS_DIR"

  cat > "$DUCKDNS_CONF" <<EOF
DUCKDNS_DOMAIN="$DUCKDNS_DOMAIN"
DUCKDNS_TOKEN="$DUCKDNS_TOKEN"
EOF
  chmod 600 "$DUCKDNS_CONF"
}

write_update_script() {
  cat > "$DUCKDNS_UPDATE_SCRIPT" <<'EOF'
#!/bin/bash
set -euo pipefail

CONF_FILE="/etc/duckdns/duckdns.conf"
LOG_FILE="/var/log/duckdns.log"

if [ ! -f "$CONF_FILE" ]; then
  echo "Missing DuckDNS config file: $CONF_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$CONF_FILE"

if [ -z "${DUCKDNS_DOMAIN:-}" ] || [ -z "${DUCKDNS_TOKEN:-}" ]; then
  echo "DuckDNS config is incomplete." >&2
  exit 1
fi

UPDATE_URL="https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip="

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

response="$(curl -fsS "$UPDATE_URL" || true)"
timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

if [ "$response" = "OK" ]; then
  echo "[$timestamp] DuckDNS updated successfully for ${DUCKDNS_DOMAIN}.duckdns.org" >> "$LOG_FILE"
  exit 0
fi

echo "[$timestamp] DuckDNS update failed. Response: ${response:-<empty>}" >> "$LOG_FILE"
exit 1
EOF
  chmod 755 "$DUCKDNS_UPDATE_SCRIPT"
}

write_systemd_units() {
  cat > "$DUCKDNS_SERVICE" <<EOF
[Unit]
Description=DuckDNS dynamic DNS updater
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$DUCKDNS_UPDATE_SCRIPT
EOF

  cat > "$DUCKDNS_TIMER" <<'EOF'
[Unit]
Description=Run DuckDNS updater every 5 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Unit=duckdns-update.service

[Install]
WantedBy=timers.target
EOF
}

enable_systemd_timer() {
  systemctl daemon-reload
  systemctl enable --now duckdns-update.timer
}

fallback_cron() {
  echo "Systemd timers are not available. Using cron fallback."
  CRON_LINE="*/5 * * * * root $DUCKDNS_UPDATE_SCRIPT >/dev/null 2>&1"
  if ! grep -Fq "$DUCKDNS_UPDATE_SCRIPT" /etc/crontab; then
    echo "$CRON_LINE" >> /etc/crontab
  fi
}

run_initial_update() {
  "$DUCKDNS_UPDATE_SCRIPT" || true
}

show_status() {
  local novnc_port vnc_port
  novnc_port="$(get_novnc_port)"
  vnc_port="$(get_vnc_port :1)"

  echo
  echo "DuckDNS is set up for: ${DUCKDNS_DOMAIN}.duckdns.org"
  echo "Update log: $DUCKDNS_LOG"
  echo

  if systemctl is-active --quiet novnc 2>/dev/null; then
    echo "Detected noVNC service."
    echo "Your current noVNC port appears to be: $novnc_port"
    echo "Access it at: http://${DUCKDNS_DOMAIN}.duckdns.org:${novnc_port}"
    echo
  fi

  if systemctl is-active --quiet nginx 2>/dev/null; then
    echo "Nginx is installed, so you may already have or want a reverse proxy."
    echo "If your reverse proxy is configured, you can use: https://${DUCKDNS_DOMAIN}.duckdns.org"
    echo
  fi

  echo "If you use direct VNC instead of noVNC, the default VNC port for :1 is $vnc_port."
}

main() {
  install_packages
  prompt_duckdns_config
  write_config
  write_update_script

  if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
    write_systemd_units
    enable_systemd_timer
  else
    fallback_cron
  fi

  run_initial_update
  show_status
}

main "$@"
