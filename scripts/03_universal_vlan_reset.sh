#!/bin/bash
# UNIVERSAL_VLAN_RESET_01.SH
# Ziel: Vollständiger Teardown (Löscht alle Staging-VLANs & Firewall-Regeln)

CONTROLLER_URL="https://127.0.0.1:8443"
COOKIE_FILE="/tmp/unifi_cookie.txt"
USERNAME="praktikant"
PASSWORD="freitag13"
SITE="default"

cleanup() {
    rm -f "$COOKIE_FILE"
}
trap cleanup EXIT SIGINT SIGTERM

echo "=== Universeller Reset gestartet ==="

LOGIN_RESP=$(curl -k -s -c "$COOKIE_FILE" -H "Content-Type: application/json" \
  -X POST -d "{\"username\":\"$USERNAME\", \"password\":\"$PASSWORD\"}" \
  "$CONTROLLER_URL/api/login")

if ! echo "$LOGIN_RESP" | grep -q '"rc":"ok"'; then
    echo " -> ERROR: Login fehlgeschlagen!"
    exit 1
fi

echo "[2/4] Frage Netzwerke ab und lösche Staging-VLANs..."
ALL_NETWORKS=$(curl -k -s -b "$COOKIE_FILE" -H "Content-Type: application/json" \
  -X GET "$CONTROLLER_URL/api/s/$SITE/rest/networkconf")

TARGET_IDS=$(echo "$ALL_NETWORKS" | jq -r '.data[] | select(.name != "LAN") | ._id')

if [ -n "$TARGET_IDS" ]; then
    for ID in $TARGET_IDS; do
        echo " -> Lösche Netzwerk-ID: $ID..."
        DELETE_RESP=$(curl -k -s -b "$COOKIE_FILE" -H "Content-Type: application/json" \
          -X DELETE "$CONTROLLER_URL/api/s/$SITE/rest/networkconf/$ID")

        if echo "$DELETE_RESP" | grep -q '"rc":"ok"'; then
            echo "    [OK] Netzwerk gelöscht."
        fi
    done
fi

echo "[3/4] Frage Firewall-Regeln ab und lösche benutzerdefinierte Regeln..."
ALL_RULES=$(curl -k -s -b "$COOKIE_FILE" -H "Content-Type: application/json" \
  -X GET "$CONTROLLER_URL/api/s/$SITE/rest/firewallrule")

RULE_IDS=$(echo "$ALL_RULES" | jq -r '.data[] | select(.rule_index >= 2000) | ._id')

if [ -n "$RULE_IDS" ]; then
    for R_ID in $RULE_IDS; do
        echo " -> Lösche Firewall-Regel ID: $R_ID..."
        DELETE_RESP=$(curl -k -s -b "$COOKIE_FILE" -H "Content-Type: application/json" \
          -X DELETE "$CONTROLLER_URL/api/s/$SITE/rest/firewallrule/$R_ID")

        if echo "$DELETE_RESP" | grep -q '"rc":"ok"'; then
            echo "    [OK] Firewall-Regel gelöscht."
        fi
    done
fi

echo "[4/4] Logout..."
curl -k -s -b "$COOKIE_FILE" -H "Content-Type: application/json" \
  -X POST "$CONTROLLER_URL/api/logout" >/dev/null 2>&1

echo "[OK] Cleanup vollständig abgeschlossen. Controller ist im Urzustand."