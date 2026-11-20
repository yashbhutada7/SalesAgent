#!/usr/bin/env bash
# One-time setup: create .env with a fresh encryption key, start n8n.
set -euo pipefail
cd "$(dirname "$0")/.."
command -v docker >/dev/null || { echo "Docker is not installed: https://docs.docker.com/get-docker/"; exit 1; }
if [ ! -f .env ]; then
  cp .env.example .env
  key=$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')
  sed -i.bak "s/^N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=${key}/" .env && rm -f .env.bak
  echo "Created .env with a new encryption key. Back this file up somewhere safe."
fi
mkdir -p backup/workflows && chmod -R a+rwX backup  # container runs as uid 1000
docker compose up -d
echo "n8n is starting at http://localhost:5678 (first start takes ~30s)."
