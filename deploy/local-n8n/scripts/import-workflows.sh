#!/usr/bin/env bash
# Load backup/workflows/*.json into the local n8n. Workflows arrive inactive.
set -euo pipefail
cd "$(dirname "$0")/.."
docker exec grandeur-n8n n8n import:workflow --separate --input=/backup/workflows
echo "Imported. Next: reconnect credentials in the editor, test, then activate."
