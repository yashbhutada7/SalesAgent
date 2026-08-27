# SalesAgent — Grandeur BD Agent

Working repository for **Grandeur Advisory LLP's** AI Business Development Agent,
built in n8n.

## What this is

An AI agent that continuously finds, qualifies, enriches, scores and prepares B2B leads
for Grandeur's outsourced accounting and finance services — a virtual BD manager, not a
scraper. Every lead must arrive with a reason.

## Documentation

| Doc | Contents |
|---|---|
| [`docs/PROJECT_BRIEF.md`](docs/PROJECT_BRIEF.md) | The vision — ICP, target markets, five lead engines, seven-agent pipeline, scoring, phasing |
| [`docs/WORKFLOW_SPEC.md`](docs/WORKFLOW_SPEC.md) | Current build state — nodes, credentials, Excel schema, next stage |
| [`docs/prompts/company-research.md`](docs/prompts/company-research.md) | The `Company Research AI` prompt, verbatim, plus observed behaviour |
| [`docs/OPEN_QUESTIONS.md`](docs/OPEN_QUESTIONS.md) | Gaps, risks and decisions pending |
| [`docs/DOMAIN_HEALTH.md`](docs/DOMAIN_HEALTH.md) | DNS, SPF/DKIM/DMARC and deliverability state of `grandeuradvisory.com` |
| [`docs/SOURCE_TRANSCRIPT.md`](docs/SOURCE_TRANSCRIPT.md) | Raw source material this spec was derived from |

## Where things stand

**Working:** a 4-node test path proving `company input → AI analysis → structured JSON → Excel row`.

**Next:** replace manual input with an Excel read loop, and *update* matched rows rather
than appending — the duplicate-company hazard.

**Standing rule:** human approval before any outbound communication.
