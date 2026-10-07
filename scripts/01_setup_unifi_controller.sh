#!/bin/bash
# SETUP_UNIFI_CONTROLLER_D1.SH
# Ziel: Automatisiertes Anlegen der Praxis-Netzwerke & TI-Firewall-Regeln (IHK-Labor D1)

CONTROLLER_URL="https://127.0.0.1:8443"
COOKIE_FILE="/tmp/cookie.txt"
USERNAME="praktikant"
PASSWORD="freitag13"
SITE="default"

cleanup() {
    if [ -f "$COOKIE_FILE" ]; then
        curl -k -s -b "$COOKIE_FILE" -H "Content-Type: application/json" \
             -X POST "$CONTROLLER_URL/api/logout" >/dev/null 2>&1
        rm -f "$COOKIE_FILE"
    fi
}
trap cleanup EXIT SIGINT SIGTERM

create_network() {
    local name="$1"
    local vlan="$2"
    local subnet="$3"

    echo " -> Erstelle Netzwerk: $name (VLAN $vlan, Subnet $subnet)..."

    local resp=$(curl -k -s -b "$COOKIE_FILE" \
      -H "Content-Type: application/json" \
      -X POST \
      -d '{ "name": "'"$name"'", "purpose": "corporate", "ip_subnet": "'"$subnet"'", "vlan": "'"$vlan"'", "vlan_enabled": true, "dhcpd_enabled": false }' \
      "$CONTROLLER_URL/api/s/$SITE/rest/networkconf")

    if echo "$resp" | grep -q '"rc":"ok"'; then
        local id=$(echo "$resp" | jq -r '.data[0]._id')
        echo "    [OK] Erfolg! Objekt-ID (_id): $id"
    else
        echo "    [ERROR] Netzwerk $name konnte nicht angelegt werden!"
        echo "$resp" | jq .
    fi
}

create_firewall_rule() {
    echo " -> Erstelle TI-Outbound-Firewall-Regel (WAN_OUT)..."

    local resp=$(curl -k -s -b "$COOKIE_FILE" \
      -H "Content-Type: application/json" \
      -X POST \
      -d '{ "ruleset": "WAN_OUT", "rule_index": "2001", "name": "Allow-TI-Outbound", "action": "accept", "enabled": true, "protocol": "all", "logging": true }' \
      "$CONTROLLER_URL/api/s/$SITE/rest/firewallrule")

    if echo "$resp" | grep -q '"rc":"ok"'; then
        local id=$(echo "$resp" | jq -r '.data[0]._id')
        echo "    [OK] Erfolg! Firewall-Regel ID: $id"
    else
        echo "    [ERROR] Firewall-Regel konnte nicht angelegt werden!"
        echo "$resp" | jq .
    fi
}

echo "=== Staging-Lab D1 Setup gestartet ==="

LOGIN_RESPONSE=$(curl -k -s -c "$COOKIE_FILE" \
  -H "Content-Type: application/json" \
  -X POST \
  -d "{\"username\":\"$USERNAME\", \"password\":\"$PASSWORD\"}" \
  "$CONTROLLER_URL/api/login")

if echo "$LOGIN_RESPONSE" | grep -q '"rc":"ok"'; then
    echo " -> Login erfolgreich!"
else
    echo " -> [ERROR] Login fehlgeschlagen!"
    exit 1
fi

create_network "Praxis-LAN-10" "10" "10.10.0.1/24"
create_network "TI-Gateway-20" "20" "10.20.0.1/24"
create_network "eKT-TI-Netzwerk_30" "30" "192.168.30.1/24"

create_firewall_rule

echo "[+] Setup erfolgreich abgeschlossen!"