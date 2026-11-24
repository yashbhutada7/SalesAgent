#!/usr/bin/env bash
# Pull every workflow from n8n Cloud via its public API into backup/workflows/*.json.
# Needs N8N_CLOUD_URL and N8N_CLOUD_API_KEY in .env, plus curl and jq.
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a
: "${N8N_CLOUD_URL:?set N8N_CLOUD_URL in .env}" "${N8N_CLOUD_API_KEY:?set N8N_CLOUD_API_KEY in .env}"
out=backup/workflows; mkdir -p "$out"
cursor=""; n=0
while :; do
  url="${N8N_CLOUD_URL%/}/api/v1/workflows?limit=100${cursor:+&cursor=$cursor}"
  page=$(curl -fsS -H "X-N8N-API-KEY: $N8N_CLOUD_API_KEY" "$url")
  while read -r wf; do
    id=$(jq -r .id <<<"$wf")
    # Keep only fields the importer needs; import everything INACTIVE so nothing
    # sends email until the cloud copies are switched off (no double sends).
    jq '{id,name,nodes,connections,settings,staticData,pinData:(.pinData//{}),active:false}' <<<"$wf" > "$out/$id.json"
    echo "  exported $(jq -r .name <<<"$wf") ($id)"; n=$((n+1))
  done < <(jq -c '.data[]' <<<"$page")
  cursor=$(jq -r '.nextCursor // empty' <<<"$page"); [ -z "$cursor" ] && break
done
echo "$n workflows saved to $out"
