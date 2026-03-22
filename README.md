# 🏠 HomeLab

Personal homelab running on a single server — self-hosted services, infrastructure as code, and continuous learning.

---

## 📋 Table of Contents

- [Hardware](#️-hardware)
- [Architecture Overview](#️-architecture-overview)
- [Services](#-services)
- [Network & Security](#-network--security)
- [Storage](#-storage)
- [Roadmap](#-roadmap)
- [Useful Commands](#-useful-commands)

---

## 🖥️ Hardware

**Lenovo ThinkServer TS150**

| Component | Details |
|-----------|---------|
| CPU | Intel Xeon E3-1230v6 — 4 cores / 8 threads @ 3.5 GHz (boost 3.9 GHz) |
| RAM | 16 GB DDR4 ECC |
| Storage | 2× 1 TB HDD (RAID 1) + 1× 1 TB HDD + 1× 500 GB SSD |
| Network | 2× Gigabit Ethernet |
| Hypervisor | **Proxmox VE** |

---

## 🏗️ Architecture Overview

All workloads run on **Proxmox VE** as a mix of VMs and LXC containers.

```
Proxmox VE
├── VM – pfSense          (Firewall / VPN / DynDNS)
├── LXC – docker-infra    (Traefik · Vaultwarden · Home-CA)
├── LXC – docker-prod-photo (WordPress · Immich)
├── LXC – nextcloud       (Nextcloud)
├── LXC – homarr          (Dashboard)
├── LXC – docker-portainer (Portainer → migration Dockhand)
├── LXC – supervision     (Prometheus · Grafana — WIP)
└── VM  – k3s-dev         (Kubernetes dev environment)
```

**Storage pools (ZFS)**

| Pool | Used by |
|------|---------|
| `zfs-vms` | docker-prod-photo, nextcloud |
| `zfs-infra` | docker-infra, homarr, supervision |

---

## 🚀 Services

### Infra (`docker-infra`)

| Service | Role |
|---------|------|
| **Traefik** | Reverse proxy — LAN HTTPS with TLS |
| **Vaultwarden** | Self-hosted password manager (Bitwarden-compatible) |
| **Home-CA** | Internal certificate authority |

### Photo & Media (`docker-prod-photo`)

| Service | Stack | Notes |
|---------|-------|-------|
| **Immich** | PostgreSQL (pgvecto-rs) + Redis | Self-hosted photo/video backup |
| **WordPress** | MariaDB | Personal photo blog |

### Cloud (`nextcloud`)

| Service | Stack |
|---------|-------|
| **Nextcloud** | MariaDB + Redis |

### Dashboard (`homarr`)

| Service | Notes |
|---------|-------|
| **Homarr** | Central service dashboard — integrates Nextcloud, Proxmox, Immich |

### Monitoring (`supervision` — WIP)

| Service | Role |
|---------|------|
| **Prometheus** | Metrics collection |
| **Grafana** | Visualization |

### Kubernetes (`k3s-dev`)

| Component | Details |
|-----------|---------|
| **k3s** | Lightweight Kubernetes — dev/test environment |
| **Traefik** | Ingress controller (bundled) |
| **Provisioning** | Terraform (bpg/proxmox provider) + Ansible |

---

## 🔐 Network & Security

- ✅ **No WAN exposure** — all services are LAN-only (no inbound NAT / port forwarding)
- ✅ **pfSense** — firewall, VPN (WireGuard), DynDNS
- ✅ **TLS everywhere** — internal CA (`Home-CA`) signs all LAN certificates
- ✅ **SSH by key only** — root login disabled, single admin user
- ✅ **No privileged containers** — all LXC/Docker containers run unprivileged
- ✅ **Secrets managed via Vaultwarden** — no plain-text credentials in config files

> All sensitive values (IPs, credentials, certificates) are kept out of this repository.
> See [`.env.example`](.env.example) for the expected environment variables.

---

## 💾 Storage

- **ZFS RAID-1** (`zfs-vms`) — VM and container data
- **ZFS** (`zfs-infra`) — infrastructure services
- **Proxmox snapshots** — regular automated snapshots of all LXCs and VMs
- Critical data paths are documented and included in snapshot policies

---

## 🗺️ Roadmap

> Tracked in the private Notion backlog. Key upcoming items:

| Domain | Item | Priority |
|--------|------|----------|
| Infra | Terraform IaC for LXC provisioning (security as code) | High |
| Infra | Migrate Portainer → Dockhand | Medium |
| Observability | Deploy Prometheus + Grafana stack | High |
| Observability | Uptime Kuma for service availability | High |
| Observability | Loki + Promtail for log aggregation | Medium |
| Security | Migrate TLS to Let's Encrypt (replacing Home-CA) | Medium |
| Automation | Ansible for Traefik config + host onboarding | Medium |
| Infra | Introduce Kubernetes workloads (use-case TBD) | Low |

---

## ⚡ Useful Commands

### Docker

```bash
# Follow logs (all services)
docker compose logs -f

# Follow logs for a specific service
docker compose logs -f <service>

# Restart services
docker compose restart

# Stop / start
docker compose down
docker compose up -d

# Cleanup stopped containers and unused images
docker system prune -a

# Disk usage
docker system df
```

### WireGuard VPN

```bash
# Enable VPN
sudo wg-quick up wg0

# Disable VPN
sudo wg-quick down wg0
```

### Traefik — add a new service

Add these labels to your `docker-compose.yml`:

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

### Weekly (~ 10 min)

- [ ] Check Proxmox global state (CPU / RAM / storage)
- [ ] Verify critical services (Traefik, Vaultwarden, Nextcloud)
- [ ] Review recent logs (Traefik / pfSense)

### Monthly

- [ ] Update LXC base systems (`apt update && apt upgrade`)
- [ ] Pull new Docker images + controlled restart
- [ ] Check certificate validity (Home-CA)
- [ ] Verify Proxmox snapshots + disk capacity

---

## 🛠️ Stack at a glance

![Proxmox](https://img.shields.io/badge/Proxmox-E57000?style=flat&logo=proxmox&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=flat&logo=traefikproxy&logoColor=white)
![Nextcloud](https://img.shields.io/badge/Nextcloud-0082C9?style=flat&logo=nextcloud&logoColor=white)
![Kubernetes](https://img.shields.io/badge/k3s-FFC61C?style=flat&logo=kubernetes&logoColor=black)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat&logo=terraform&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=flat&logo=ansible&logoColor=white)
![pfSense](https://img.shields.io/badge/pfSense-212121?style=flat&logo=pfsense&logoColor=white)

---

*Last updated: March 2026*
