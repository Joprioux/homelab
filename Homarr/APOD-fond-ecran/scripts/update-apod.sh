#!/bin/sh
set -eu

API_KEY="${NASA_API_KEY}"
OUT_DIR="/usr/share/nginx/html"
TMP_DIR="/tmp/apod"
TMP_JSON="$TMP_DIR/apod.json"
TMP_SRC="$TMP_DIR/source"
TMP_FRAME="$TMP_DIR/frame.jpg"
TMP_FINAL="$TMP_DIR/apod_new.jpg"
FINAL_IMG="$OUT_DIR/apod.jpg"

TARGET_WIDTH=1920
TARGET_HEIGHT=1080

mkdir -p "$OUT_DIR" "$TMP_DIR"

echo "==> Récupération APOD metadata"

if ! curl --retry 5 --retry-delay 10 --retry-all-errors -fsSL   "https://api.nasa.gov/planetary/apod?api_key=${API_KEY}&thumbs=True"   -o "$TMP_JSON"; then
  echo "Erreur: impossible de récupérer les métadonnées APOD"
  echo "On conserve l'image actuelle si elle existe"
  exit 0
fi

if jq -e '.error' "$TMP_JSON" >/dev/null 2>&1; then
  echo "Erreur API NASA :"
  jq -r '.error.message // .msg // "Erreur inconnue"' "$TMP_JSON"
  echo "On conserve l'image actuelle si elle existe"
  exit 0
fi

MEDIA_TYPE=$(jq -r '.media_type // empty' "$TMP_JSON")

if [ -z "$MEDIA_TYPE" ]; then
  echo "media_type absent"
  echo "On conserve l'image actuelle si elle existe"
  exit 0
fi

render_wallpaper() {
  INPUT_FILE="$1"

  ffmpeg -y -i "$INPUT_FILE"     -filter_complex "[0:v]scale=${TARGET_WIDTH}:${TARGET_HEIGHT}:force_original_aspect_ratio=increase,boxblur=24:12,crop=${TARGET_WIDTH}:${TARGET_HEIGHT},eq=brightness=-0.12:saturation=0.95[bg]; [0:v]scale=w=${TARGET_WIDTH}*0.60:h=${TARGET_HEIGHT}*0.60:force_original_aspect_ratio=decrease[fg]; [bg][fg]overlay=(W-w)/2:(H-h)/2"     -q:v 2 "$TMP_FINAL" >/dev/null 2>&1
}

case "$MEDIA_TYPE" in
  image)
    SRC_URL=$(jq -r '.hdurl // .url // empty' "$TMP_JSON")
    if [ -z "$SRC_URL" ] || [ "$SRC_URL" = "null" ]; then
      echo "Aucune URL image trouvée"
      exit 0
    fi

    echo "==> Téléchargement image : $SRC_URL"
    curl --retry 5 --retry-delay 10 --retry-all-errors -fsSL "$SRC_URL" -o "$TMP_SRC"

    echo "==> Génération du wallpaper"
    render_wallpaper "$TMP_SRC"
    ;;

  video)
    THUMB_URL=$(jq -r '.thumbnail_url // empty' "$TMP_JSON")
    VIDEO_URL=$(jq -r '.url // empty' "$TMP_JSON")

    if [ -n "$THUMB_URL" ] && [ "$THUMB_URL" != "null" ]; then
      echo "==> Téléchargement thumbnail : $THUMB_URL"
      curl --retry 5 --retry-delay 10 --retry-all-errors -fsSL "$THUMB_URL" -o "$TMP_SRC"

      echo "==> Génération du wallpaper"
      render_wallpaper "$TMP_SRC"

    elif [ -n "$VIDEO_URL" ] && [ "$VIDEO_URL" != "null" ]; then
      echo "==> Téléchargement vidéo : $VIDEO_URL"
      curl --retry 5 --retry-delay 10 --retry-all-errors -fsSL "$VIDEO_URL" -o "$TMP_SRC"

      echo "==> Extraction frame"
      ffmpeg -y -i "$TMP_SRC" -ss 00:00:02 -vframes 1 "$TMP_FRAME" >/dev/null 2>&1

      echo "==> Génération du wallpaper"
      render_wallpaper "$TMP_FRAME"
    else
      echo "Aucune source exploitable pour la vidéo"
      exit 0
    fi
    ;;

  *)
    echo "media_type non supporté : $MEDIA_TYPE"
    exit 0
    ;;
esac

if [ ! -s "$TMP_FINAL" ]; then
  echo "Image finale absente ou vide"
  echo "On conserve l'image actuelle si elle existe"
  exit 0
fi

mv "$TMP_FINAL" "$FINAL_IMG"

echo "==> Image finale générée"
ls -lh "$FINAL_IMG"
