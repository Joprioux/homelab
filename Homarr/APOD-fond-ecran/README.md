# APOD Homarr Wallpaper

Petit repo pour utiliser l'image du jour de la NASA APOD comme fond dans Homarr.

## Ce que ça fait

- récupère l'APOD du jour via l'API dédiée de la NASA
- gère les images et les vidéos
- extrait une frame si l'APOD est une vidéo sans thumbnail
- génère toujours un `apod.jpg`
- produit un fond 1920x1080 avec :
  - fond flou plein écran
  - image nette centrée
- sert l'image via nginx sur `http://<ip-du-lxc>:8088/apod.jpg`

## Arborescence

```text
.
├── .env.example
├── Dockerfile
├── CSS-personnalisé.css
├── docker-compose.yml
├── README.md
└── scripts
    └── update-apod.sh
```

## Installation

### 1. Copier le repo

```bash
git clone 
cd apod-homarr-wallpaper
```

### 2. Créer le fichier `.env`

```bash
cp .env.example .env
nano .env
```

Mettre clé NASA dans `.env` :

```env
NASA_API_KEY=votre_cle_nasa
```

### 3. Lancer le conteneur

```bash
docker compose up -d --build
```

### 4. Générer une première image

```bash
docker exec apod-wallpaper /update-apod.sh
```

### 5. Tester

```bash
curl http://127.0.0.1:8088/apod.jpg --output test.jpg
file test.jpg
```

Un JPEG doit être présent.

## Je conseille de faire un Cron pour mettre à jour automatiquement l'image

Éditer la crontab :

```bash
crontab -e
```

Ajouter :

```cron
5 6 * * * docker exec apod-wallpaper /update-apod.sh >> /home/jo/apod-wallpaper/apod-update.log 2>&1
```

## Dans Homarr

Mettre en fond :

```text
http://<ip-du-lxc>:8088/apod.jpg
```

## Notes

- si l'API NASA est temporairement indisponible, le script garde l'image actuelle
- si l'APOD est en portrait, le rendu reste propre grâce au fond flou + image centrée
