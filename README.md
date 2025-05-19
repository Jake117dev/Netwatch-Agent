# Netwatch-Agent
Modularer Agent zur Netzwerküberwachung und Verteidigung

# NetWatch-Agent – Modulare Netzwerkverteidigung mit Agentenstruktur

**Projektleiter:** [Jake117dev](https://github.com/Jake117dev)  
**Ziel:** Aufbau eines autonomen, modularen Sicherheits-Agents zur Erkennung, Reaktion und Abwehr von Netzwerkbedrohungen – in Echtzeit, mit KI-Perspektive, auf Raspberry Pi-Basis.

---

## ⚙️ Funktionen (Stand: MVP/Modulphase 1)

- Agentenzentrale (Controller) für modulare Sicherheits-Tools
- Backup-System mit ntfy-Status, Hash-Check & Dropbox-Upload (Pi 5)
- RAID-10-Datenserver mit automatischer Überwachung (Pi 4)
- Temperaturüberwachung + Notabschaltung (Temp-Guard)
- Live-Statusmeldungen über ntfy.sh (auch mobil empfangbar)
- Struktur für spätere Modulverknüpfung mit KI (LLaMA etc.)

---

## 🧠 Vision

> *"Ich will kein einzelnes Skript – ich will ein System, das selbstständig denkt und handelt."*

Langfristig wird der Agent mit einem LLM verknüpft,  
das aus der eigenen Umgebung lernt, Module erstellt, filtert und einsetzt –  
eine selbstreparierende, lernende Verteidigungsinstanz mit Admin-Schnittstelle.

---

## 📁 Projektstruktur

```bash
├── scripts/
│   ├── pi_dropbox_backup.sh
│   ├── temp-guard.sh
│   └── raid-agent.sh
├── services/
│   ├── temp-guard.service
│   └── raid-agent.service (optional)
├── docs/
│   ├── setup-guide.md
│   ├── backup-workflow.md
│   └── raid-overview.md
├── .gitignore
├── LICENSE
└── README.md
