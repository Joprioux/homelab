# HomeLab

Dépôt de référence de mon homelab personnel, hébergé sur Proxmox et organisé en conteneurs LXC Docker.  
L'objectif est de maintenir une infrastructure reproductible, documentée et orientée bonnes pratiques DevOps.

---

## Architecture globale

```
Proxmox (bare-metal)
├── pfSense (VM)              → Firewall / VPN / DynDNS     — 10.0.0.1
├── LXC docker-infra          → Traefik + Vaultwarden        — 10.0.0.51
├── LXC nextcloud             → Nextcloud                    — 10.0.0.52
├── LXC docker-prod-photo     → WordPress + Immich           — 10.0.0.53
├── LXC homarr                → Homarr dashboard + APOD      — 10.0.0.54
├── LXC supervision           → Prometheus + Grafana         — 10.0.0.60
└── VM k3s-dev                → Kubernetes (test)            — 10.0.0.100
```

Tous les services sont **LAN only** (aucune exposition WAN) et accessibles via Traefik avec TLS signé par une CA interne (Home-CA).

---

## Structure du dépôt

```
homelab/
├── docker-infra/
│   ├── traefik/              → Reverse proxy LAN + TLS
│   └── vaultwarden/          → Password manager (compatible Bitwarden)
├── docker-prod-photo/        → WordPress (MariaDB) + Immich (PostgreSQL + Redis)
├── nextcloud/                → Nextcloud (MariaDB + Redis)
├── homarr/
│   ├── docker-compose.yml    → Dashboard central
│   └── apod/                 → Fond d'écran NASA APOD (Nginx + script cron)
├── supervision/              → Prometheus + Grafana + Blackbox Exporter
└── .gitignore
```

Chaque stack contient :
- `docker-compose.yml` — définition des services (secrets externalisés via `.env`)
- `.env.example` — template des variables d'environnement (à copier en `.env`)

---

## Déploiement d'une stack

```bash
# 1. Copier le template de variables
cp .env.example .env

# 2. Renseigner les valeurs dans .env
nano .env

# 3. Démarrer la stack
docker compose up -d

# 4. Vérifier l'état des conteneurs
docker compose ps
```

---

## Gestion des secrets

Les credentials ne sont **jamais** committés. Chaque stack utilise un fichier `.env` local (gitignored).  
Un fichier `.env.example` est fourni dans chaque dossier pour documenter les variables attendues.


---

## Stacks

### `docker-infra` — LXC 10.0.0.51

| Service      | Image                    | Port | Rôle                            |
|--------------|--------------------------|------|---------------------------------|
| Traefik      | `traefik:latest`         | 80/443 | Reverse proxy LAN + TLS       |
| Vaultwarden  | `vaultwarden/server`     | 8000 | Password manager self-hosted   |

Config Traefik attendue sur l'hôte sous `/opt/traefik/` (non versionné — contient les certs).

---

### `docker-prod-photo` — LXC 10.0.0.53

| Service                   | Image                            | Port | Rôle                        |
|---------------------------|----------------------------------|------|-----------------------------|
| WordPress                 | `wordpress:latest`               | 8080 | Site photo                  |
| MariaDB                   | `mariadb:latest`                 | —    | BDD WordPress               |
| Immich Server             | `immich-app/immich-server`       | 2342 | Gestion médiathèque photo   |
| Immich Machine Learning   | `immich-app/immich-machine-learning` | — | Reconnaissance faciale/IA  |
| PostgreSQL (pgvecto-rs)   | `tensorchord/pgvecto-rs:pg16`    | —    | BDD Immich                  |
| Redis                     | `redis:latest`                   | —    | Cache Immich                |

---

### `nextcloud` — LXC 10.0.0.52

| Service    | Image              | Port | Rôle                  |
|------------|--------------------|------|-----------------------|
| Nextcloud  | `nextcloud:latest` | 8080 | Cloud personnel       |
| MariaDB    | `mariadb:10.11`    | —    | BDD Nextcloud         |
| Redis      | `redis:alpine`     | —    | Cache session         |

---

### `homarr` — LXC 10.0.0.54

| Service | Image                            | Port | Rôle                             |
|---------|----------------------------------|------|----------------------------------|
| Homarr  | `ghcr.io/homarr-labs/homarr`    | 7575 | Dashboard central des services   |
| APOD    | `nginx` + script cron            | 8088 | Fond d'écran NASA APOD quotidien |

Intégrations actives : Nextcloud · Proxmox · Immich

---

### `supervision` — LXC 10.0.0.60

| Service           | Image                        | Port | Rôle                          |
|-------------------|------------------------------|------|-------------------------------|
| Prometheus        | `prom/prometheus`            | 9090 | Collecte métriques            |
| Grafana           | `grafana/grafana`            | 3000 | Visualisation + alerting      |
| Blackbox Exporter | `prom/blackbox-exporter`     | 9115 | Supervision uptime services   |

Accessible via Traefik : `https://grafana.home` · `https://prometheus.home`

---

## Sécurité

- Aucun service exposé sur le WAN
- Pas de NAT entrant / port forwarding
- TLS sur tous les services (certificats Home-CA)
- SSH par clé uniquement, accès root désactivé
- Conteneurs non-privilégiés
- Secrets externalisés (jamais en dur dans les compose)

---

## Observabilité

- **Prometheus** — métriques système et services
- **Grafana** — dashboards et alerting
- **Blackbox Exporter** — health check HTTP/TCP
- **Logs** — consultables via `docker compose logs -f <service>`

---

## Stack technique

![Proxmox](https://img.shields.io/badge/Proxmox-E57000?style=flat&logo=proxmox&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=flat&logo=traefikproxy&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white)
![Nextcloud](https://img.shields.io/badge/Nextcloud-0082C9?style=flat&logo=nextcloud&logoColor=white)

---

*Homelab en évolution continue — K8S (quand la ram sera moins chère 🥸), Terraform et Ansible en développement*
