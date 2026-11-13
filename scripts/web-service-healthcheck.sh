
#!/usr/bin/env bash

# Ubuntu Web Service Health Check
# Infrastructure Troubleshooting Lab
#
# Read-only diagnostics for Apache web servers.
# No configuration changes are performed.

set -u

SERVICE="apache2"
TARGET="http://127.0.0.1/"
PORT="80"

section() {
    printf '\n========================================\n'
    printf '%s\n' "$1"
    printf '========================================\n'
}

section "SYSTEM INFORMATION"
date -Is
hostname
uname -sr

if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo "OS: $PRETTY_NAME"
fi

section "APACHE SERVICE STATUS"

if ! command -v systemctl >/dev/null 2>&1; then
    echo "systemctl unavailable"
elif systemctl is-active --quiet "$SERVICE"; then
    echo "[PASS] Apache is running"
else
    echo "[WARN] Apache is not running"
fi

if command -v systemctl >/dev/null 2>&1; then
    echo "Enabled state:"
    systemctl is-enabled "$SERVICE" 2>&1 || true
fi

section "LISTENING TCP PORTS"

if command -v ss >/dev/null 2>&1; then
    ss -lnt
    echo
    if ss -lntH | awk '{print $4}' | grep -Eq ":${PORT}$"; then
        echo "[PASS] TCP port $PORT has a listener"
    else
        echo "[WARN] No TCP listener found on port $PORT"
    fi
else
    echo "[WARN] ss utility unavailable"
fi

section "LOCAL HTTP TEST"

if command -v curl >/dev/null 2>&1; then
    HTTP_CODE=$(curl -sS -o /dev/null \
        -w '%{http_code}' \
        --max-time 10 "$TARGET")
    CURL_STATUS=$?

    if [[ $CURL_STATUS -ne 0 ]]; then
        echo "[FAIL] HTTP request failed (curl exit: $CURL_STATUS)"
    elif [[ "$HTTP_CODE" =~ ^2 ]]; then
        echo "[PASS] HTTP $HTTP_CODE"
    elif [[ "$HTTP_CODE" =~ ^3 ]]; then
        echo "[INFO] HTTP $HTTP_CODE (redirect)"
    else
        echo "[WARN] HTTP $HTTP_CODE"
    fi
else
    echo "[WARN] curl unavailable"
fi

section "APACHE CONFIGURATION"

if command -v apache2ctl >/dev/null 2>&1; then
    apache2ctl configtest 2>&1 || true
    echo
    echo "Virtual host configuration:"
    apache2ctl -S 2>&1 || true
else
    echo "[WARN] apache2ctl unavailable"
fi

section "FIREWALL STATUS"

if command -v ufw >/dev/null 2>&1; then
    ufw status 2>&1 || true
fi

echo
echo "iptables INPUT rules (if accessible):"
if command -v iptables >/dev/null 2>&1; then
    iptables -S INPUT 2>&1 || true
else
    echo "iptables unavailable"
fi

section "RECENT APACHE LOGS"

if command -v journalctl >/dev/null 2>&1; then
    journalctl -u "$SERVICE" -n 15 --no-pager 2>&1 || true
fi

section "HEALTH CHECK COMPLETE"

echo "Diagnostics only. No configuration changes were made."
echo "Review warnings and verify external connectivity separately."
