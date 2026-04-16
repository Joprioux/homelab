FROM nginx:alpine

RUN apk add --no-cache curl jq ffmpeg

COPY scripts/update-apod.sh /update-apod.sh
RUN chmod +x /update-apod.sh

CMD ["nginx", "-g", "daemon off;"]
