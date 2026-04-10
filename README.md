# 🏠 HomeLab

Homelab personnel tournant sur un serveur unique — services auto-hébergés, infrastructure as code, et apprentissage continu.

---

## 🎯 Pourquoi ce projet ?

Ce homelab est né de deux envies qui se rejoignent naturellement : **mettre en pratique mes cours** d'infrastructure et de systèmes, et **concrétiser ma passion pour la photographie**.

Plutôt que de travailler sur des exercices abstraits, j'ai préféré construire quelque chose de réel, qui pourrait un jour me servir professionnellement. L'idée à terme : **monter mon auto-entreprise de photographie** et disposer d'une plateforme entièrement auto-hébergée pour **livrer les photos à mes clients** — sans dépendre de services tiers, avec une maîtrise totale de mes données et de mon image de marque.

Ce projet est donc à la fois un terrain d'entraînement technique et la première brique d'une infrastructure pro future.

---

## 📋 Table des matières

* [Matériel](#%EF%B8%8F-matériel)
* [Architecture](#%EF%B8%8F-architecture)
* [Services](#-services)
* [Réseau & Sécurité](#-réseau--sécurité)
* [Stockage](#-stockage)
* [Feuille de route](#%EF%B8%8F-feuille-de-route)
* [Commandes utiles](#-commandes-utiles)

---

## 🖥️ Matériel

**Lenovo ThinkServer TS150**

| Composant | Détails |
| --- | --- |
| CPU | Intel Xeon E3-1230v6 — 4 cœurs / 8 threads @ 3,5 GHz (boost 3,9 GHz) |
| RAM | 16 Go DDR4 ECC |
| Stockage | 2× 1 To HDD (RAID 1) + 1× 1 To HDD + 1× 500 Go SSD |
| Réseau | 2× Gigabit Ethernet |
| Hyperviseur | **Proxmox VE** |

---

## 🏗️ Architecture

Toutes les charges de travail tournent sur **Proxmox VE**, sous forme de VMs et de conteneurs LXC.

```
Proxmox VE
├── VM  – pfSense            (Pare-feu / VPN / DynDNS)
├── LXC – docker-infra       (Traefik · Vaultwarden · Home-CA)
├── LXC – docker-prod-photo  (WordPress · Immich)
├── LXC – nextcloud          (Nextcloud)
├── LXC – homarr             (Tableau de bord)
├── LXC – docker-portainer   (Portainer → migration Dockhand)
├── LXC – supervision        (Prometheus · Grafana — en cours)
└── VM  – k3s-dev            (Environnement de développement Kubernetes)
```

**Pools de stockage (ZFS)**

| Pool | Utilisé par |
| --- | --- |
| `zfs-vms` | docker-prod-photo, nextcloud |
| `zfs-infra` | docker-infra, homarr, supervision |

---

## 🚀 Services

### Infra (`docker-infra`)

| Service | Rôle |
| --- | --- |
| **Traefik** | Reverse proxy — HTTPS LAN avec TLS |
| **Vaultwarden** | Gestionnaire de mots de passe auto-hébergé (compatible Bitwarden) |
| **Home-CA** | Autorité de certification interne |

### Photo & Médias (`docker-prod-photo`)

| Service | Stack | Notes |
| --- | --- | --- |
| **Immich** | PostgreSQL (pgvecto-rs) + Redis | Sauvegarde photos/vidéos auto-hébergée |
| **WordPress** | MariaDB | Blog photo personnel |

### Cloud (`nextcloud`)

| Service | Stack |
| --- | --- |
| **Nextcloud** | MariaDB + Redis |

### Tableau de bord (`homarr`)

| Service | Notes |
| --- | --- |
| **Homarr** | Dashboard central — intègre Nextcloud, Proxmox, Immich |

### Supervision (`supervision` — en cours)

| Service | Rôle |
| --- | --- |
| **Prometheus** | Collecte de métriques |
| **Grafana** | Visualisation |

### Kubernetes (`k3s-dev`)

| Composant | Détails |
| --- | --- |
| **k3s** | Kubernetes léger — environnement de dev/test |
| **Traefik** | Contrôleur Ingress (inclus) |
| **Provisionnement** | Terraform (provider bpg/proxmox) + Ansible |

---

## 🔐 Réseau & Sécurité

* ✅ **Aucune exposition WAN** — tous les services sont en LAN uniquement (pas de NAT entrant)
* ✅ **pfSense** — pare-feu, VPN (WireGuard), DynDNS
* ✅ **TLS partout** — CA interne (`Home-CA`) signe tous les certificats LAN
* ✅ **SSH par clé uniquement** — connexion root désactivée, un seul utilisateur admin
* ✅ **Pas de conteneurs privilégiés** — tous les conteneurs LXC/Docker tournent sans privilèges
* ✅ **Secrets gérés via Vaultwarden** — aucune credential en clair dans les fichiers de configuration

> Toutes les valeurs sensibles (IPs, credentials, certificats) sont exclues de ce dépôt par le biais d'un git ignore


---

## 💾 Stockage

* **ZFS RAID-1** (`zfs-vms`) — données des VMs et conteneurs
* **ZFS** (`zfs-infra`) — services d'infrastructure
* **Snapshots Proxmox** — snapshots automatisés réguliers de tous les LXC et VMs
* Les chemins critiques sont documentés et inclus dans les politiques de snapshot

---

## 🗺️ Feuille de route

> Suivi dans le backlog Notion privé. Principaux éléments à venir :

| Domaine | Élément | Priorité |
| --- | --- | --- |
| Infra | Terraform IaC pour le provisionnement LXC (security as code) | Haute |
| Infra | Migration Portainer → Dockhand | Moyenne |
| Observabilité | Déploiement stack Prometheus + Grafana | Haute |
| Sécurité | Migration TLS vers Let's Encrypt (remplacement Home-CA) | Moyenne |
| Automatisation | Ansible pour la config Traefik + onboarding des hôtes | Moyenne |
| Infra | Introduire des workloads Kubernetes (cas d'usage à définir) | Basse |

---

## ⚡ Commandes utiles

### Docker

```bash
# Suivre les logs (tous les services)
docker compose logs -f

# Suivre les logs d'un service spécifique
docker compose logs -f <service>

# Redémarrer les services
docker compose restart

# Arrêter / démarrer
docker compose down
docker compose up -d

# Nettoyer les conteneurs arrêtés et images inutilisées
docker system prune -a

# Utilisation du disque
docker system df
```

### VPN WireGuard

```bash
# Activer le VPN
sudo wg-quick up wg0

# Désactiver le VPN
sudo wg-quick down wg0
```

### Traefik — ajouter un nouveau service

Ajouter ces labels dans ton `docker-compose.yml` :

```yaml
services:
  myapp:
    image: myapp:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.home.local`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls=true"
    networks:
      - web

networks:
  web:
    external: true
```

---

## 📅 Maintenance

### Hebdomadaire (~10 min)

* Vérifier l'état global de Proxmox (CPU / RAM / stockage)
* Contrôler les services critiques (Traefik, Vaultwarden, Nextcloud)
* Consulter les logs récents (Traefik / pfSense)

### Mensuelle

* Mettre à jour les systèmes de base des LXC (`apt update && apt upgrade`)
* Tirer les nouvelles images Docker + redémarrage contrôlé
* Vérifier la validité des certificats (Home-CA)
* Contrôler les snapshots Proxmox + capacité disque

---

## 🛠️ Stack en un coup d'œil

[![Proxmox](https://img.shields.io/badge/Proxmox-E57000?style=flat&logo=proxmox&logoColor=white)](https://www.proxmox.com)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)](https://www.docker.com)
[![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=flat&logo=traefikproxy&logoColor=white)](https://traefik.io)
[![Nextcloud](https://img.shields.io/badge/Nextcloud-0082C9?style=flat&logo=nextcloud&logoColor=white)](https://nextcloud.com)
[![Kubernetes](https://img.shields.io/badge/k3s-FFC61C?style=flat&logo=kubernetes&logoColor=black)](https://k3s.io)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat&logo=terraform&logoColor=white)](https://www.terraform.io)
[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=flat&logo=ansible&logoColor=white)](https://www.ansible.com)
[![pfSense](https://img.shields.io/badge/pfSense-212121?style=flat&logo=pfsense&logoColor=white)](https://www.pfsense.org)

---

*Dernière mise à jour : mars 2026*
