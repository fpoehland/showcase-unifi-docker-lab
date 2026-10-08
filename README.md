# Showcase: UniFi Staging Lab & IaC Automation

Isolierte Staging-Umgebung für einen UniFi Network Controller auf Docker-Basis inklusive automatisierter Netzwerkkonfiguration (VLANs & Firewall-Regeln) über die REST-API.

---

## Projekt-Ziel & Kernkonzept

Dieses Repository demonstriert die Prinzipien von Infrastructure as Code (IaC), Disposable Infrastructure und Idempotence:
1. Containerisierung: Der UniFi Controller läuft als zustandsbehafteter Service (Stateful Workload) isoliert in Docker Compose mit persistentem Host-Storage.
2. REST-API-Automatisierung: Die gesamte Netzwerktopologie (VLANs 10, 20, 30) sowie Outbound-Firewall-Regeln werden vollautomatisch über Shell-Skripte injiziert.
3. Fail Fast & Recover Faster: Im Falle eines Systemausfalls steht die komplette Umgebung inklusive Netzwerkkonfiguration in unter 2 Minuten wieder identisch zur Verfügung.

---

## Repository-Struktur

showcase-unifi-docker-lab/
├── README.md                          # Projekt-Dokumentation & Quickstart
├── docker-compose.yml                 # Deklarativer Container-Bauplan (UniFi + MongoDB)
├── scripts/
│   ├── 01_setup_unifi_controller.sh   # IaC: Automatische Injektion von VLANs & Firewall-Regeln via REST-API
│   ├── 02_status_unifi.sh             # Telemetrie: Auslesen des Ist-Zustands aus der MongoDB via API
│   └── 03_universal_vlan_reset.sh     # Cleanup: Atomares Löschen aller angelegten Netzwerke per API
└── docs/
    └── k8s-unifi-showcase.yaml        # K8s-Manifest-Gerüst (Ausblick auf Kubernetes Migration)

---

## Schnellstart & Ausführung

### 1. Staging-Umgebung hochfahren
docker compose up -d

### 2. Infrastruktur per REST-API konfigurieren (IaC)
./scripts/01_setup_unifi_controller.sh
./scripts/02_status_unifi.sh

### 3. Automatisierter Reset
./scripts/03_universal_vlan_reset.sh

---

## Technische Kernfeatures

* Strukturiertes API-Logging & Error Handling: Skripte verarbeiten HTTP-Statuscodes und JSON-Payloads via jq für präzises Live-Feedback auf der Konsole (z. B. api.err.VlanUsed).
* Idempotenz: Mehrfache Ausführungen des Setup-Skripts führen nicht zu Duplikaten oder Fehlzuständen.
* Persistent Volumes: Audits und Datenbanken werden persistent im Host-Volume gespeichert.
