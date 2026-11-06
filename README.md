# Showcase: UniFi Staging Lab & IaC Automation

Isolierte Staging-Umgebung für einen UniFi Network Controller auf Docker-Basis inklusive automatisierter Netzwerkkonfiguration (VLANs & Firewall-Regeln) über die REST-API.

---

## Projekt-Ziel & Kernkonzept

Dieses Repository demonstriert die Prinzipien von Infrastructure as Code (IaC), Disposable Infrastructure und Idempotence:
1. Containerisierung: Der UniFi Controller läuft als zustandsbehafteter Service (Stateful Workload) isoliert in Docker Compose mit persistentem Host-Storage.
2. REST-API-Automatisierung: Die gesamte Netzwerktopologie (VLANs 10, 20, 30) sowie Outbound-Firewall-Regeln werden vollautomatisch über Shell-Skripte injiziert.
3. Fail Fast & Recover Faster: Im Falle eines Systemausfalls steht die komplette Umgebung inklusive Netzwerkkonfiguration in unter 2 Minuten wieder identisch zur Verfügung.

---

## Architektur-Entscheidungen & Evaluierung (MacVlan-Staging)

Da für die Skriptentwicklung im Projekt keine physische Original-UniFi-Hardware zur Verfügung stand, wurde ein vollständig isoliertes, virtualisiertes Docker Staging Lab aufgebaut, um die Praxisstruktur zu emulieren und die API-Ansteuerung gefahrlos zu validieren.

### Evaluierte Option: Das MacVlan-Lab (Infrastruktur-Emulation)
Um die Netzwerkumgebung einer Arztpraxis inklusive dedizierter Staging-Clients auf Layer 2 und Layer 3 exakt nachzubilden, wurde eine Multi-Container-Umgebung mittels network-archive/docker-compose.vlan.yml und einem MacVlan-Netzwerk aufgesetzt.

* **Vorteil:** Jeder simulierte Client erhält eine eigene, echte IP-Adresse direkt im Netzwerksegment des Virtualisierungs-Hosts, was eine realistische IP-Zuweisung und Broadcast-Simulation ermöglicht.
* **Erkenntnis & Richtungswechsel:** Während der Testläufe führte das skriptbasierte Einpflegen von statischen Routen über den API-Endpunkt /rest/routing in der virtuellen Container-Umgebung ohne adoptierte physische Hardware zu reproduzierbaren HTTP Status 500 (Internal Server Error)-Blockern. Die Analyse der Server-Logs ergab eine strikte Koppelung dieses Endpunkts an physische Data-Plane-Hardware.

### Finale Implementierung: Control-Plane-Abstraktion via /rest/networkconf
Aus dieser Erkenntnis heraus wurde ein strategischer Richtungswechsel vollzogen. Da das primäre Projektziel in der logischen Netztrennung (VLAN-Segmentierung) lag, wurde die Logik auf den Control-Plane-Endpunkt /rest/networkconf` umgestellt. Dieser operiert direkt auf der Controller-Datenbank, erfordert keine physische Hardware-Präsenz im Staging-Lab und lieferte umgehend den Status HTTP 200 OK.

*Die Konfigurationsdaten des hochentwickelten MacVlan-Ansatzes wurden als wertvolles "Lessons Learned"-Artefakt im Verzeichnis /network-archive konserviert, um das tiefere Verständnis von Netzwerk-Infrastrukturen im DevOps-Kontext zu demonstrieren.*

---

## Repository-Struktur

showcase-unifi-docker-lab/
├── README.md                          # Projekt-Dokumentation & Quickstart
├── docker-compose.yml                 # Deklarativer Container-Bauplan (UniFi + MongoDB)
├── scripts/
│   ├── 01_setup_unifi_controller.sh   # IaC: Automatische Injektion von VLANs & Firewall-Regeln via REST-API
│   ├── 02_status_unifi.sh             # Telemetrie: Auslesen des Ist-Zustands aus der MongoDB via API
│   └── 03_universal_vlan_reset.sh     # Cleanup: Atomares Löschen aller angelegten Netzwerke per API
├── network-archive/
│   └── docker-compose.vlan.yml        # Archiv: Erweitertes Layer-2 MacVlan-Staging-Lab (Lessons Learned)
└── docs/
    └── k3s-manifest.yaml              # K8s-Manifest-Gerüst (Ausblick auf Kubernetes Migration)

---

## Schnellstart & Ausführung

### 1. Staging-Umgebung hochfahren
```bash
docker compose up -d
```

### 2. Infrastruktur per REST-API konfigurieren (IaC)
```bash
chmod +x scripts/*.sh
./scripts/01_setup_unifi_controller.sh
./scripts/02_status_unifi.sh
```

### 3. Automatisierter Reset
```bash
./scripts/03_universal_vlan_reset.sh
```

---

## Technische Kernfeatures

* **Strukturiertes API-Logging & Error Handling:** Skripte verarbeiten HTTP-Statuscodes und JSON-Payloads via jq für präzises Live-Feedback auf der Konsole (z. B. api.err.VlanUsed).
* **Idempotenz:** Mehrfache Ausführungen des Setup-Skripts führen nicht zu Duplikaten oder Fehlzuständen.
* **Persistent Volumes:** Audits und Datenbanken werden persistent im Host-Volume gespeichert.

