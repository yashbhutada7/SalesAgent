# Build Log

## 2026-08-25 — Company Intake / dedup brick (built, not executed, not published)

### Decisions locked with owner

| Rule | Decision |
|---|---|
| Company ID format | `Grand 001`, `Grand 002` … `Grand 1000` — sequential, zero-padded to 3, widens past 999 |
| Company uniqueness | **Never duplicated.** One row per company, forever |
| Company match key | normalized domain (`Company Key` column) — invisible, drives dedup |
| Opportunity ID format | `001`, `002` … `1000` — sequential, zero-padded to 3, no prefix |
| Opportunity identity | one per **company + opportunity type** |
| Re-engagement | same company+type resurfacing → row updated; email allowed again only after **≥30 days** since last outreach |
| Freshness window | action/outreach stage considers only opportunities generated/refreshed in the **last 72 hours** |

**How 72h and 30d reconcile:** Monitoring re-detects an opportunity → stamps its timestamp to now →
pulls it back into the 72h "fresh activity" window. The 30-day gate then decides whether it may be emailed again.
72h = *is there something to act on*; 30d = *are we allowed to email again*.

### Why a hybrid key (match key + display ID)

Sequential IDs are not derivable from company data — you cannot recompute `Grand 007` from "ABC Ltd".
So the ID itself cannot be the dedup key. Correct design:

- **Match key (invisible):** normalized domain → decides "seen before or new"
- **Display ID (visible):** `Grand NNN`, assigned once on creation, reused forever

This is what guarantees the same company never gets two Company IDs.

### Changes applied to `Grandeur BD Agent V1` (jIghxNOFdVshn2d3)

**New — `Get Existing Companies`** (Excel, table `getRows`, `returnAll: true`)
- `alwaysOutputData: true` — required so the very first company (empty table → 0 rows) still runs
- `executeOnce: true` — independent fetch, must not multiply per input item

**New — `Assign Company ID`** (Code, `runOnceForAllItems`)
- normalizes `Website` → domain (strips scheme, `www.`, path/query/fragment)
- matches against existing `Company Key` (falls back to `Website`)
- **match →** reuse existing `Company ID`, preserve original `First Discovered`
- **no match →** `max(trailing number) + 1` → `Grand NNN` (width ≥ 3, grows automatically)
- stamps `Last Researched`, sets `Is New Company`
- strips any stray `=` prefix from incoming field names (defensive)

**Changed — `Test Append` → renamed `Upsert Company`**
- was: table **append** to `tblCompanies` (blind insert, and receiving *opportunity* data)
- now: worksheet **upsert** on `Companies`, `columnToMatchOn: "Company ID"`, auto-map
- Table resource has no update/upsert — worksheet resource does. This is the mechanism.

**Fixed — `Normalize Research Output`**
- `=Finance Team Size` → `Finance Team Size`
- `=ERP` → `ERP`
- (these two never reached their Excel columns before)

**Fixed — `Map Opportunity Output`**
- `Company ID` now reads `$('Assign Company ID').first().json['Company ID']`
  instead of the model-echoed `company_id` — guarantees opportunities link to the real `Grand NNN`

### Wiring — before → after

```
BEFORE (broken):
Normalize → Opportunity Research → Map Opportunity Output → Append Opportunities → Test Append
                                                                                    ↑ Companies table
                                                                                      fed OPPORTUNITY data

AFTER:
Normalize Research Output
  → Get Existing Companies
  → Assign Company ID
       ├→ Upsert Company        → Companies    (worksheet upsert, match Company ID)
       └→ Opportunity Research → Map Opportunity Output → Append Opportunities → Opportunities
```

### Gotcha recorded for future edits

`setNodeParameter` **cannot index into arrays** — a path like
`/parameters/assignments/assignments/17/name` silently creates a junk nested
`parameters` key instead of editing the array element. Use
`updateNodeParameters` with `replace: true` and the full array instead.
(Hit this once; corrected in a follow-up revision.)

### Owner prerequisites — still outstanding

- [ ] Add **`Company Key`** column to the `Companies` sheet (holds the normalized domain)
- [ ] Add **`Opportunity Type`** presence check — needed for the Opportunity dedup twin
- [ ] Outlook OAuth credential (for the outreach stage)
- [ ] Verify the run before publishing — nothing has been executed

### Next build items

- [ ] **Opportunity dedup twin**: `Get Existing Opportunities` → `Assign Opportunity ID`
      (match on Company ID + Opportunity Type, sequential `001`) → worksheet upsert on Opportunities
- [ ] 72h freshness filter + 30-day re-engagement gate
- [ ] Signals + Sources writes
- [ ] Suppression check, then outreach draft → approve → Outlook send

---

## 2026-08-25 — Opportunity dedup twin (built, not executed, not published)

### Verified before building

Owner added the **`Company Key`** column — Companies now has 40 columns and the
`Finance Team Size` / `ERP` headers read correctly (typo fix confirmed live).
Opportunities confirmed at exactly the 22 expected columns.

### Changes applied

**New — `Get Existing Opportunities`** (Excel, table `getRows`, `returnAll: true`,
`alwaysOutputData: true`, `executeOnce: true`)

**New — `Assign Opportunity ID`** (Code, `runOnceForAllItems`)
- match key = `Company ID` + `Opportunity Type` (both normalized: trimmed, lowercased,
  whitespace collapsed)
- **match →** reuse existing `Opportunity ID`, preserve original `First Detected`
- **no match →** `max(trailing number) + 1` → `001`, `002` … widening past `999`
- stamps `Last Verified` = today, sets `Is New Opportunity`
- empty `Opportunity Type` (score 0 / nothing verified) falls back to the literal
  `(none)` — so "monitoring, no opportunity yet" becomes **one** row per company that
  keeps updating, instead of a new duplicate row on every run

**Changed — `Append Opportunities` → renamed `Upsert Opportunity`**
- was: table **append** (new row every run)
- now: worksheet **upsert** on `Opportunities`, `columnToMatchOn: "Opportunity ID"`, auto-map

### Wiring now

```
Manual Trigger → Test Company Input → Company Research AI → Normalize Research Output
  → Get Existing Companies → Assign Company ID
       ├→ Upsert Company                                    → Companies
       └→ Opportunity Research → Map Opportunity Output
            → Get Existing Opportunities → Assign Opportunity ID
            → Upsert Opportunity                            → Opportunities
```

Both dedup paths now satisfy the locked rules: one company row ever (`Grand NNN`),
one opportunity row per company+type (`001`), re-runs update rather than duplicate.

### Remaining gap for the outreach rules

The 22 Opportunities columns carry `First Detected` and `Last Verified` — enough for the
**72-hour freshness** filter (`Last Verified` within 72h).

The **30-day re-engagement gate** needs a last-contacted timestamp. Two options:
- add a `Last Outreach Date` column to `Opportunities`, or
- derive it from the `Outreach` sheet (join on Opportunity ID, take max date) — better
  normalized, matches the architecture, no new column on Opportunities

Decision pending with owner.

### Next build items

- [ ] 72h freshness filter + 30-day re-engagement gate (needs the decision above)
- [ ] Signals + Sources writes (evidence/traceability layer)
- [ ] Suppression check → outreach draft → human approval → Outlook send
- [ ] Owner: Outlook OAuth credential

---

## 2026-08-25 — Dedup verified live ✅

Owner ran the workflow twice. **One row in Companies, one row in Opportunities** after
both runs. Dedup confirmed working: companies never duplicate, opportunities update in
place. Foundation is sound.

## 2026-08-25 — Contact Discovery (built, not executed, not published)

Built because outreach cannot exist without a recipient and `Contacts` was empty.
Required no new credentials — reuses the existing OpenAI and Excel credentials.

### Nodes added

**`Contact Research AI`** (OpenAI v2.3, web search on, plain-text format)
- finds finance decision makers: CFO → Finance Director → Controller → VP Finance →
  Head of Finance/Accounting → Finance Manager → Accounting Manager → (Founder/CEO only
  for small companies with no finance leader)
- returns at most 3, most relevant first, as `{ "contacts": [ ... ] }`

**Anti-fabrication rules baked into the prompt** (the compliance-critical part):
- never invent, guess, construct or **pattern-match** an email
  (explicitly forbids `firstname.lastname@domain` inference)
- only an email explicitly published in a reliable public source
- blank email is stated to be **correct and expected**
- no invented people, no similarly-named different companies
- generic inboxes (`info@`, `sales@`, `support@`, `contact@`) rejected as decision makers
- no fabricated LinkedIn URLs, phones or source IDs
- empty `contacts` array declared a valid, preferred answer over any invention
- placeholder/invalid website → return empty array

**`Get Existing Contacts`** (Excel table `getRows`, `returnAll`, `alwaysOutputData`, `executeOnce`)

**`Assign Contact IDs`** (Code, `runOnceForAllItems`)
- dedup key: `Company ID` + (`Email` if present, else `Name`), normalized
- match → reuse existing `Contact ID`; new → sequential `001`, `002` …
- increments the running max **within** a batch, so several new contacts in one run get
  distinct ids
- defaults applied: `Email Verification Status` → `Unverified`, `Contact Confidence` →
  `Unknown`, `Do Not Contact` → `No`
- returns **zero items** when nothing verifiable → nothing is written downstream
  (correct n8n empty-list behavior, no synthetic rows)

**`Upsert Contact`** (Excel worksheet upsert on `Contacts`, match `Contact ID`, auto-map)

### Wiring

```
Assign Opportunity ID
  ├→ Upsert Opportunity                                   → Opportunities
  └→ Contact Research AI → Get Existing Contacts
       → Assign Contact IDs → Upsert Contact              → Contacts
```

### ID convention note

`Contact ID` follows the same sequential zero-padded pattern as Opportunity ID
(`001`, `002` …), consistent with the established convention. Flagged to owner as an
assumption that can be changed now while the table is empty.

### Expected first-run behaviour

The test fixture uses `https://example.com`, which the prompt treats as a placeholder —
so **zero contacts is the correct result** and proves the guardrail works. Real contacts
require a real company website.

### Next build items

- [ ] Suppression check (Clients / Competitors / Do Not Contact) — before any draft
- [ ] Outreach draft → `Outreach` with `Approval Status = Pending Approval`
- [ ] 72h freshness filter (`Last Verified`) + 30-day gate (`max(Sent Date)` per Opportunity ID)
- [ ] Sender workflow: scheduled → `Approved` + no `Sent Date` → Outlook send → stamp `Sent Date`
- [ ] Owner: `Subject` column on Outreach, `Last Outreach Date` on Opportunities, Outlook credential

---

## 2026-08-25 — Outreach drafting chain (built, not executed, not published)

### Nodes added

**`Get Outreach History`** (Excel table `getRows` on Outreach/`Table6`, `returnAll`,
`alwaysOutputData`, `executeOnce`)

**`Check Outreach Eligibility`** (Code) — all four business rules in one gate:

| Rule | Constant | Behaviour |
|---|---|---|
| Contactable decision maker | — | prefers `Primary Decision-Maker = Yes` with a non-empty `Email`; falls back to any contact with an email; skips anyone flagged `Do Not Contact = Yes` |
| Opportunity quality | `MIN_SCORE = 50` | below 50 → not eligible |
| **72-hour freshness** | `FRESH_HOURS = 72` | `Last Verified` must be within 72h |
| **30-day re-engagement** | `REENGAGE_DAYS = 30` | `max(Sent Date)` for this Opportunity ID must be ≥30 days ago |
| Duplicate-draft guard | — | blocks if a Pending Approval draft with no `Sent Date` already exists |

Outputs `Eligible` (bool) plus a human-readable `Ineligible Reason`, and carries the
contact/company/opportunity context forward. It deliberately emits **one item either
way** rather than an empty list, so the reason is visible in the n8n UI when nothing
gets drafted — much easier to debug than a silent skip.

**`Eligible?`** (IF v2.3) — true branch only. False branch intentionally unwired: an
ineligible opportunity stops there without burning an OpenAI call.

**`Outreach Draft AI`** (OpenAI v2.3, no web search — writes only from verified input)

Prompt design:
- **Subject derived from the body**, as requested: the prompt instructs writing the body
  first, then a subject that honestly describes what the body actually says
- Subject rules: 4–8 words, references the specific signal or service, sentence case,
  no clickbait/fake urgency/`Re:` tricks, no spam trigger words (free, guarantee, act
  now, limited time, urgent, offer, discount, cheap, risk-free), no emojis, no
  exclamation marks, must make sense to someone who has never heard of Grandeur
- Body rules: 90–130 words, plain and human, opens on the actual verified signal,
  concrete about the service, low-friction close, no bullets/headers/emojis, no
  signature (sender adds it)
- Banned filler: "I hope this email finds you well", "reaching out", "circle back",
  "touch base", "synergy", "game-changer", "revolutionary", "just following up",
  "quick question"
- Anti-fabrication: no invented facts, systems, case studies, client names, statistics
  or promised outcomes; no naming other Grandeur clients; thin evidence → write shorter,
  never pad with invention

**`Build Outreach Row`** (Code) — parses the draft, assigns a sequential `Outreach ID`
(`001`, `002` …), sets `Approval Status = Pending Approval`, `Draft Status = Drafted`,
`Outreach Status = Draft`, `Channel = Email`, records recipient + signal in `Notes`.
Returns zero items if subject or body came back empty, so a malformed draft never
reaches Excel.

**`Upsert Outreach`** (Excel worksheet upsert on Outreach, match `Outreach ID`, auto-map)

### Wiring

```
Upsert Contact → Get Outreach History → Check Outreach Eligibility → Eligible?
  └─(true)→ Outreach Draft AI → Build Outreach Row → Upsert Outreach → Outreach
```

### Forward-compatible with the missing columns

`Subject` (Outreach) and `Last Outreach Date` (Opportunities) do not exist yet. Excel
auto-map ignores keys with no matching header, so the workflow runs fine and simply
drops those values. They begin persisting the moment the owner adds the headers —
no workflow change needed. See `docs/OWNER_SETUP.md`.

### Tunable constants

`MIN_SCORE = 50`, `FRESH_HOURS = 72`, `REENGAGE_DAYS = 30` are declared at the top of
`Check Outreach Eligibility` — single place to change any threshold.

### Next build items

- [ ] Suppression check (Clients / Competitors / Suppression sheets have no tables yet)
- [ ] Sender workflow: Schedule → read `Approval Status = Approved` + empty `Sent Date`
      → Outlook send → stamp `Sent Date`, `Outreach Status = Sent`, and
      `Last Outreach Date` on the Opportunity
- [ ] Signals + Sources writes
- [ ] Owner: `Subject` column, `Last Outreach Date` column, Outlook credential
