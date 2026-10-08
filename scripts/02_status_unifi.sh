#!/bin/bash
# STATUS_UNIFI_D1.SH
# Ziel: Ist-Zustand der VLANs und Firewall-Regeln am Controller abfragen

CONTROLLER_URL="https://127.0.0.1:8443"
COOKIE_FILE="/tmp/status_cookie.txt"
USERNAME="praktikant"
PASSWORD="freitag13"
SITE="default"

cleanup() {
    rm -f "$COOKIE_FILE"
}
trap cleanup EXIT SIGINT SIGTERM

LOGIN_RESP=$(curl -k -s -c "$COOKIE_FILE" -H "Content-Type: application/json" \
  -X POST -d "{\"username\":\"$USERNAME\", \"password\":\"$PASSWORD\"}" \
  "$CONTROLLER_URL/api/login")

if ! echo "$LOGIN_RESP" | grep -q '"rc":"ok"'; then
    echo " -> ERROR: Login fehlgeschlagen!"
    exit 1
fi

echo "=========================================================================="
echo "               STAGING-LAB D1: UNIFI CONTROLLER STATUS                    "
echo "=========================================================================="

echo -e "\n[+] AKTIVE NETZWERKE / VLANs:"
NETWORKS_JSON=$(curl -k -s -b "$COOKIE_FILE" -H "Content-Type: application/json" \
  -X GET "$CONTROLLER_URL/api/s/$SITE/rest/networkconf")

echo "$NETWORKS_JSON" | jq -r '
  ["NAME", "VLAN-ID", "SUBNET", "OBJECT-ID"],
  ["--------------------", "-------", "-----------------", "------------------------"],
  (.data[] | [.name, (.vlan // "1 (Native)"), (.ip_subnet // "N/A"), ._id])
  | @tsv' | column -t -s $'\t'

echo -e "\n[+] AKTIVE FIREWALL-REGELN:"
RULES_JSON=$(curl -k -s -b "$COOKIE_FILE" -H "Content-Type: application/json" \
  -X GET "$CONTROLLER_URL/api/s/$SITE/rest/firewallrule")

echo "$RULES_JSON" | jq -r '
  ["RULE-INDEX", "RULESET", "NAME", "ACTION", "OBJECT-ID"],
  ["----------", "-------", "--------------------", "------", "------------------------"],
  (.data[] | [.rule_index, .ruleset, .name, .action, ._id])
  | @tsv' | column -t -s $'\t'

echo "=========================================================================="