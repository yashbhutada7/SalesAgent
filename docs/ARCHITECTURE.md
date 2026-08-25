# Grandeur AI BD Agent — System Architecture

Endorsed 2026-08-25. This is a **BD intelligence system**, not "a workflow that
researches companies." Reviewed and technically validated against the live n8n instance.

## Core data model — three separate concepts

| Concept | Question it answers | Table | Cardinality |
|---|---|---|---|
| **Company** | Who is the business? | `Companies` | one row per company (unique) |
| **Signal** | What happened? (evidence) | `Signals` | many per company |
| **Opportunity** | Why does what happened create a Grandeur opportunity? | `Opportunities` | many per company |

> One company → many opportunities → each backed by dated signals from real sources.
> Never lose OP-002 just because OP-001 exists. This separation is the whole point.

## Workbook = the database (12 sheets, verified live)

`Companies` · `Opportunities` · `Contacts` · `Signals` · `Outreach` · `Responses` ·
`Suppression` · `Clients` · `Competitors` · `Sources` · `Settings` · `Learning`
(plus `Dashboard`)

- **Sources** — every meaningful claim traces to Source ID + URL + date. Keeps the agent
  from being "a fancy hallucination machine."
- **Suppression** — client / competitor / do-not-contact / already-contacted. Checked
  **before** outreach is generated, not after.
- **Learning** — outcome log that feeds back into scoring over time.

## Deterministic ID rules (locked)

- **Company ID** = `COM-` + normalized domain (strip scheme/`www`/path, lowercase).
  Domain beats name — spellings vary, domains don't.
- **Opportunity ID** = deterministic per **company + opportunity_type**
  (e.g. `OP-<companyslug>-netsuite`). Re-runs update the same opportunity; a new type
  creates a new row. **Decision: one opportunity per company + type.**

## ⚙️ Key technical finding — how dedup/update actually works in this node

Verified against `n8n-nodes-base.microsoftExcel` v2.2:

- **Table** resource ops: `append`, `get_rows`, `lookup`, `get_columns`, `add_table`,
  `delete_table`, `convert_to_range` — **no update, no upsert.** (This is why nothing can
  currently be updated; the current build only appends.)
- **Worksheet** resource has **`upsert`**: `columnToMatchOn` (key column) + auto-map →
  updates the matching row, inserts if absent (`updateAll` option available).

**Therefore:** dedup + "create/update" = **worksheet upsert**, matched on the
deterministic key column.

- Company create/update → worksheet upsert on `Companies`, match `Company ID`
- Opportunity create/update → worksheet upsert on `Opportunities`, match `Opportunity ID`

## Storage ceiling (honest constraint)

Excel worksheet-upsert re-scans the used range per write and is **not concurrency-safe**.
- Fine for **V1 → low thousands** with **serial** processing (batchSize 1, no overlapping schedules).
- Before routinely processing 1,000s repeatedly, migrate the **transactional core** to
  **n8n Data Tables** or **Postgres/Supabase**; keep Excel as the human dashboard/export.

## Other honest constraints

- **Contact discovery / verified emails** is the weak link — LLM web-search yield is low
  and unreliable. Real coverage needs an enrichment provider (Apollo/Hunter/Clearbit).
  Highest compliance surface (GDPR/CASL/CAN-SPAM); Suppression + human approval are the controls.
- **Scoring** should be a **deterministic rubric** (consistent run-to-run); the LLM writes
  the narrative reason, not the number.
- **Learning loop** is a feedback loop (log outcomes → feed aggregates into scoring
  prompt / retune rubric), **not** auto-ML.
- **Response management** needs an inbound email trigger (Outlook/Gmail/IMAP).

## Target: 7 modular sub-workflows (not one 50-node monster)

Connected via the Execute Sub-workflow node.

1. **Company Intake** — Lead input → Normalize → Company ID → dedup → create/update Company
2. **Company Research** — Research AI → verify → normalize → update Company → Sources
3. **Opportunity Discovery** *(currently building)* — Opportunity Research → qualify →
   dedup → create/update Opportunity → create Signal → Sources
4. **Contact Discovery** — find decision makers → verify → primary/backup → Contacts
5. **Outreach** — Suppression check → contact check → personalized draft → **human approval** → send → Outreach
6. **Response Management** — inbound → AI classify intent → recommended action → human decision
7. **Monitoring** — check Next Research Date → fresh signals → new/updated Opportunity → update Company

## Boundaries

- **Claude (via n8n MCP):** node logic, prompts, expressions, wiring, dedup, sub-workflow
  splitting, validation. Never executes/publishes without owner OK.
- **Owner (n8n UI):** OAuth credentials, Excel column/table *structure*, going live.

## Current live state — MAIN `Grandeur BD Agent V1` (jIghxNOFdVshn2d3)

```
Manual Trigger → Test Company Input → Company Research AI (39-field, web search)
  → Normalize Research Output (39 cols)
  → Opportunity Research (22-field, web search, json_schema)
  → Map Opportunity Output (22 cols)
  → Append Opportunities  → Opportunities/tblOpportunities  ✅ (auto-map, verified 22/22)
  → Test Append           → Companies/tblCompanies          ❌ receives opportunity data
```

### Open build items
- [ ] **Company Intake/dedup + fix Companies write**: generate `Company ID` (domain) →
      worksheet **upsert** on Companies (match `Company ID`), replacing mis-wired `Test Append`.
- [ ] **Opportunity dedup**: generate `Opportunity ID` (company + type) → worksheet
      **upsert** on Opportunities (match `Opportunity ID`), replacing plain append.
- [ ] Fix `=Finance Team Size` / `=ERP` name typos in Normalize (block 2 Companies columns).
- [ ] Signals + Sources writes (evidence/traceability layer).
- [ ] Email-on-approval (Outreach) — draft-before-approve + Outlook send (needs Outlook credential).
