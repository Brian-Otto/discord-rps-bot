#!/usr/bin/env bash
set -e

echo "Discord bot setup"

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from .env.example - fill in your APP_ID, DISCORD_TOKEN, PUBLIC_KEY, DOMAIN, then re-run this script."
  exit 1
fi

source .env
for var in APP_ID DISCORD_TOKEN PUBLIC_KEY DOMAIN PORT; do
  if [ -z "${!var}" ]; then
    echo "Error: $var is empty in .env - please set it."
    exit 1
  fi
done

echo "Building and starting bot container..."
docker compose up -d --build

echo "Waiting for bot to be ready..."
RETRIES=0
MAX_RETRIES=30
until docker compose exec -T bot node -e "require('http').get('http://localhost:$PORT', () => process.exit(0)).on('error', () => process.exit(1))" 2>/dev/null; do
  RETRIES=$((RETRIES+1))
  if [ "$RETRIES" -ge "$MAX_RETRIES" ]; then
    echo "Error: bot did not become ready in time."
    docker compose logs bot
    exit 1
  fi
  sleep 2
done
docker compose exec bot npm run register

echo "Bot is running on 127.0.0.1:$PORT"
echo "Make sure Caddy is configured and reloaded for: https://$DOMAIN/interactions"