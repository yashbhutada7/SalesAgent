# Open Questions & Risks

Raised by Claude while transcribing the working history. None of these block Stage 2 —
they are things to decide deliberately rather than discover later.

---

## 1. Three competing field schemas 🔴

| Source | Field count |
|---|---|
| The prompt's declared JSON | 18 |
| What the model actually returns | ~27 |
| What the Excel table holds | 27+ (`verification_status`, `notes`, …) |

The Excel node uses **Auto-Map Input Data to Columns**, so mapping is by key name at
runtime. A renamed or dropped key fails silently — no error, just a blank column.

**Recommendation:** make one file the single source of truth for the company schema,
generate the prompt's JSON block from it, and consider switching off auto-map for
explicit field mapping once the schema settles.

## 2. `company_id` is required by the design but never generated 🔴

Stage 2 depends on *"Find matching Company ID → update that row."* But the prompt says
`company_id: leave blank unless explicitly provided`, and nothing in the pipeline mints
one.

**Decide:** where do IDs come from? Options — an Excel formula/column, an n8n Code node
minting a deterministic hash of normalised domain, or a Data Table with an autoincrement
key. Domain-based dedup is probably stronger than name-based, since company names vary
in spelling but domains don't.

## 3. Excel may not survive the target scale 🟠

The vision is thousands of leads with status tracking, follow-up dates, dedup and daily
writes. Excel via Graph API is workable at hundreds of rows; it gets slow and
lock-prone beyond that, and concurrent writes are a real hazard.

**Note:** n8n has native **Data Tables** available on this account. Worth evaluating as
the master store, with Excel kept as an export/reporting surface. Not urgent — but the
migration gets more expensive the longer it waits.

## 4. No research layer exists yet 🟠

The `Company Research AI` node cannot enrich anything — it only reformats supplied
input. Every "unverified" field stays blank forever until a real retrieval step exists.

**Decide:** web-search tool bound to the model, a dedicated search API (Serper/Tavily/
Bing), or an enrichment vendor (Apollo/Clearbit) for firmographics.

## 5. Contact enrichment has legal exposure ⚖️

The target schema includes personal contact data (decision-maker name, business email,
LinkedIn) for prospects in the EU, UK, Switzerland, Norway — all GDPR/UK-GDPR
territory — plus CAN-SPAM (US), CASL (Canada), and the Australian Spam Act.

This does not stop the project. B2B prospecting is lawful in all of these when done
properly. But it needs decisions on: lawful basis for processing (legitimate interest
assessment), source provenance per contact, suppression/opt-out handling, and retention.

**Recommendation:** add `data_source` and `consent_basis` columns to the lead schema now
while it is cheap, rather than retrofitting across thousands of rows. The transcript's
"business email **where legitimately available**" instinct is the right one — worth
making it a hard rule in the enrichment prompt.

## 6. Scale of the ambition vs. what exists 🟡

Built today: a 4-node single-company reformatter.
Described in the brief: 5 lead engines, 7 agents, scoring, personalised pitch
generation, CRM, outreach, follow-up tracking, reply detection, meeting booking.

That gap is fine — the phasing is sound and the "prove Phase 1 first" instinct is
correct. Flagging it only so the roadmap stays honest about distance to travel.

## 7. Scoring model is undefined 🟡

The 0–100 bands exist, but nothing defines how a score is computed. Is it the LLM's
judgement, a deterministic weighted rubric, or a hybrid? An LLM asked for a bare number
will produce inconsistent scores run to run.

**Recommendation:** deterministic rubric over structured signals (ERP match, hiring
signal freshness, country priority, revenue band, multi-entity complexity), with the LLM
supplying the narrative `reason` rather than the number.

## 8. Trigger / scheduling not decided 🟡

Phase 2 says "every morning." No schedule trigger exists yet, and the workflow is
inactive. Also undecided: what happens on re-runs — full re-research, or only rows
where `verification_status = Unverified`?

## 9. No error handling or run visibility 🟡

Single-item manual runs hide this. At batch scale: what happens when the OpenAI call
fails, returns malformed JSON, or Excel rejects a write? Right now, nothing catches it.

**Recommendation:** JSON-parse guard after the AI node, plus an error branch that logs
failures to a sheet rather than dropping records silently.
