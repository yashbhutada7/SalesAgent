# Self-hosted n8n for the Grandeur BD Agent

Runs the BD agent on our own machine instead of n8n Cloud. Tested 2026-11-20 on
n8n 2.48.6: starts, passes `/healthz`, runs in IST, imports workflows, backs up.

## What it saves, honestly

- **Saves:** the n8n Cloud subscription, and the Cloud run limits (300 s per run,
  60 s per Code step) that broke the Findymail backfill.
- **Does not save:** OpenAI usage (about $8/day, measured in `docs/BUILD_LOG.md`).
  That is billed by OpenAI wherever n8n runs.

## Requirements

- A machine that is **on 24/7**. If it sleeps, research, sending, follow-ups and
  reply detection all stop. The send window is 15:00–02:00 IST, so an office PC
  that is shut down at night will miss most of the US day.
- Docker (Docker Desktop on Windows/Mac), `curl`, `jq`.

## Steps

| # | Step | Command / action |
|---|------|------------------|
| 1 | Install and start | `./scripts/install.sh` → http://localhost:5678, create the owner login |
| 2 | Pull workflows from Cloud | Put `N8N_CLOUD_URL` + `N8N_CLOUD_API_KEY` in `.env`, then `./scripts/export-from-cloud.sh` |
| 3 | Load them locally | `./scripts/import-workflows.sh` (all arrive **inactive**) |
| 4 | Recreate credentials | OpenAI key, Findymail key, Microsoft Excel + Outlook OAuth (needs an Azure app registration; redirect URL `http://localhost:5678/rest/oauth2-credential/callback`) |
| 5 | Test | Run each workflow manually once |
| 6 | Cut over | **Deactivate the Cloud workflows first**, then activate locally. Both live at once = duplicate emails to prospects. |
| 7 | Back up | `./scripts/backup.sh` (schedule it daily). Keep `.env` safe: without its encryption key the saved credentials can't be read. |
