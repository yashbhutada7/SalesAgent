#!/usr/bin/env bash
# Nightly-safe backup of workflows + (encrypted) credentials from the local n8n.
set -euo pipefail
cd "$(dirname "$0")/.."
stamp=$(date +%Y%m%d-%H%M)
docker exec grandeur-n8n sh -c "mkdir -p /backup/$stamp && n8n export:workflow --all --separate --output=/backup/$stamp/workflows && (n8n export:credentials --all --separate --output=/backup/$stamp/credentials || echo no-credentials-yet)"
echo "Backup written to backup/$stamp (credentials stay encrypted with the key in .env)."
