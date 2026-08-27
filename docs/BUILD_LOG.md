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

---

## 2026-08-25 — Outreach Sender workflow (built, NOT activated)

Owner completed all three prerequisites: `Subject` column on Outreach,
`Last Outreach Date` on Opportunities, and the Outlook credential
(`Microsoft Outlook account`, `NmkBgylCa1gGZEob`, `microsoftOutlookOAuth2Api`).
Route 1 chosen: delegated OAuth with **Send As** on `accounting@grandeuradvisory.com`.

### New workflow — `Grandeur BD Agent - Outreach Sender` (`sEaRV2WFAshZ9uFu`)

Built as a **separate** workflow so the research pipeline stays untouched and sending
can never fire as a side effect of research.

```
Daily Send Window (09:00)
  → Get Outreach Rows      (Outreach/Table6, returnAll, executeOnce)
  → Get Contacts           (tblContacts, returnAll, executeOnce)
  → Build Send Queue       (Code — the gate)
  → Send Outreach Email    (Outlook, from accounting@grandeuradvisory.com)
       ├─(success)→ Mark Outreach Sent → Stamp Opportunity Last Outreach
       └─(error)  → Mark Send Failed
```

### `from` address

Set on the send node as `additionalFields.from = accounting@grandeuradvisory.com`.
Microsoft enforces this against real mailbox rights — it works because Send As was
delegated. `bodyContentType` is `Text` (the draft prompt produces plain text, not HTML)
and `saveToSentItems` is on, so sent mail lands in the Sent Items folder.

### Send Queue gate — five conditions, all must pass

1. `Approval Status` = `approved` (case-insensitive)
2. `Sent Date` empty — never re-sends
3. `Subject` **and** `Draft/Message` both non-empty
4. Contact resolves by `Contact ID` and has an `Email` containing `@`
5. Contact `Do Not Contact` ≠ `yes`

Anything failing is silently skipped, not sent. Emits zero items when nothing qualifies,
so the chain stops cleanly on quiet days.

### Error handling

`Send Outreach Email` uses `onError: continueErrorOutput` with 3 retries, 2s apart.
Failures route to **`Mark Send Failed`**, which writes `Outreach Status = Send Failed`
plus the error message and date into `Notes` — a failed send is visible in the sheet
rather than lost.

### Post-send stamping

- **Outreach row:** `Sent Date`, `Outreach Status = Sent`, `Draft Status = Sent`
- **Opportunity row:** `Last Outreach Date` — the cached half of the "Both" design,
  which closes the 30-day re-engagement loop back in `Check Outreach Eligibility`

Both use `dataMode: define` (explicit column list) rather than auto-map, so only the
intended columns are touched and nothing else on the row is overwritten.

### ⚠️ Deliberately left INACTIVE

The workflow is created but not activated and not published. Activating it is what makes
it start sending real email on a schedule — an owner decision, never an automatic one.

### Next build items

- [ ] Suppression check (Clients / Competitors / Suppression sheets have no tables yet)
- [ ] Signals + Sources writes
- [ ] Response Management (inbound email trigger → classify intent)
- [ ] Follow-up scheduling (`Follow-Up Date` / `Follow-Up Plan` columns exist, unused)

---

## 2026-08-25 — First real send ✅ + three bugs found in the execution data

Owner ran the sender and **received the email**. Confirmed working: Outlook send,
delegated `from: accounting@grandeuradvisory.com`, and `Mark Outreach Sent`
(`Outreach Status = Sent`, `Draft Status = Sent`).

Initial runs (75, 76) sent nothing — root cause was **Excel table boundaries**, not the
workflow: `Get Outreach Rows` returned zero rows and `Get Contacts` returned an all-blank
row, because the manually typed data sat outside the table ranges. Resolved by seeding
via `table: append` (workflow `Grandeur BD Agent - Seed Test Data`, `7dN9nrQnhEm1HXbE`),
which always writes inside the range.

Inspecting execution 78 surfaced three genuine defects:

### 🔴 1. Excel strips leading zeros from IDs

Queue showed `"Outreach ID": "1"`, `"Opportunity ID": "1"`, `"Contact ID": "1"` — not
`001`. Excel parses `001` as the number 1. (`Grand 001` survived: letters force text.)
Breaks both the agreed ID format and any string comparison.

**Fix:** an `idKey()` canonicaliser in both `Build Send Queue` and
`Check Outreach Eligibility` — pure-digit values collapse to their integer form, so
`"001"`, `"1"` and `1` all match. Matching is now format-independent.

**Owner option (for display):** format `Opportunity ID`, `Contact ID` and `Outreach ID`
columns as **Text** in Excel *before* data lands, to preserve the padded `001` look.
Matching works either way.

### 🔴 2. Excel returns dates as serial numbers — this silently disabled the 30-day gate

`Sent Date` came back as `46259`, not `2026-08-25`. The original code did
`new Date(value)`, which reads 46259 as 46 seconds past epoch → 1970. **The 30-day
re-engagement gate would never have fired**, and the 72-hour freshness check was equally
unreliable.

**Fix:** a `toDate()` helper that detects Excel serials (numeric, 20000–90000) and
converts via `(serial - 25569) * 86400000`, falling back to normal date parsing.
Applied to both `Last Verified` and `Sent Date`.

This is the most consequential bug found so far — it was invisible because the gate
failed *open* on the freshness side and *closed* on nothing.

### 🟠 3. Blank row inserted into Opportunities

`Stamp Opportunity Last Outreach` found no Opportunity matching `001` (the existing
Opportunities row predates the dedup build and has an empty ID), and the `upsert`
therefore **inserted a blank row**. Owner to delete it. Will not recur once the research
workflow runs with `Assign Opportunity ID` in place.

### Also fixed: contacts-source defect (previously flagged)

`Check Outreach Eligibility` read contacts only from the current run's
`Assign Contact IDs` output, so outreach was skipped whenever discovery found nobody new
— even with good contacts already in the sheet.

**Fix:** new **`Get Company Contacts`** node reads `tblContacts`; eligibility filters it
by Company ID and selects Primary → Backup → any usable contact. The outreach branch is
now sourced from `Assign Opportunity ID` rather than `Upsert Contact`, so it evaluates
even when contact discovery returns zero items. Adds `Contacts Found For Company` to the
output for debugging.

**Design consequence:** for a brand-new company, contacts discovered in the same run may
not yet be readable when outreach evaluates, so outreach happens on the *next* pass.
Acceptable — and arguably healthier, since it puts a cycle between discovery and contact.

### Wiring now

```
Assign Opportunity ID
  ├→ Upsert Opportunity                                        → Opportunities
  ├→ Contact Research AI → Get Existing Contacts
  │    → Assign Contact IDs → Upsert Contact                   → Contacts
  └→ Get Company Contacts → Get Outreach History
       → Check Outreach Eligibility → Eligible?
            └─(true)→ Outreach Draft AI → Build Outreach Row → Upsert Outreach
```

---

## 2026-08-25 — Re-run guard verified ✅ + Suppression and Signals built

### Re-run guard confirmed (execution 79)

Second sender run sent nothing — correctly. The execution shows the row **was** read
(`Sent Date: 46259`, `Outreach Status: Sent`) and `Build Send Queue` returned `[]`, so
`Send Outreach Email` never fired. The system cannot double-email a prospect.

That run also confirmed both fixes were needed: IDs came back as **numbers**
(`Outreach ID: 1`, `Opportunity ID: 1`, `Contact ID: 1`) and `Sent Date` as the serial
`46259` — exactly the two failure modes now handled.

### All remaining tables verified present

| Sheet | Table | Table ID |
|---|---|---|
| Signals | `tblSignals` | `{00000000-000C-0000-FFFF-FFFF03000000}` |
| Suppression | `tblSuppression` | `{00000000-000C-0000-FFFF-FFFF06000000}` |
| Clients | `tblClients` | `{00000000-000C-0000-FFFF-FFFF07000000}` |
| Sources | `tblSources` | `{00000000-000C-0000-FFFF-FFFF09000000}` |

**tblSuppression:** Suppression ID · Type · Company ID · Contact ID · Name/Company ·
Reason · Date Added · Permanent · Notes

**tblClients:** Record ID · Company Name · Company ID · Client Status · Date Added · Notes

**tblSignals:** Signal ID · Company ID · Opportunity ID · Signal Type ·
Signal Description · Signal Strength · First Detected · Last Verified ·
Expected Deadline · Evidence · Source ID · Verification Status · Confidence · Status

**tblSources:** Source ID · Company ID · Opportunity ID · Signal ID · Source Type ·
Source Name · Original URL · Date Discovered · Date Verified · Source Status ·
What It Supports · Notes

### Suppression check — enforced BEFORE any draft is generated

New `Get Suppression List` and `Get Clients` nodes feed `Check Outreach Eligibility`,
which now blocks on:

| Rule | Effect |
|---|---|
| Company ID present in `tblSuppression` | blocked, with the stored `Reason` surfaced |
| Company ID in `tblClients` and status not former/inactive/churned/past | blocked as an existing client |
| Contact ID present in `tblSuppression` | that contact excluded from selection |
| Contact `Do Not Contact = Yes` | that contact excluded (existing rule) |

Contact selection order is now **Primary → Backup → any usable**, where "usable" means a
real email, not do-not-contact, and not suppressed.

Debug counters added to the output: `Suppression Entries Checked`,
`Client Records Checked`, `Contacts Found For Company`.

Critically, suppression runs **before** `Outreach Draft AI` — a suppressed company never
even reaches the drafting step, so no OpenAI spend and no draft that could be approved by
mistake.

### Signals evidence layer

```
Assign Opportunity ID → Get Existing Signals → Assign Signal ID → Upsert Signal
```

- Deduped on **Company ID + Opportunity ID**, sequential `Signal ID` (`001`, `002` …)
- Reuses the existing `Signal ID` and preserves `First Detected` on re-detection;
  refreshes `Last Verified`
- Copies `Signal Type` (from Opportunity Type), `Signal Description` (Primary Signal),
  `Signal Strength`, `Expected Deadline`, `Evidence` (Evidence Summary)
- **Writes nothing** when `Primary Signal` is empty or `Signal Strength` is `None` —
  no evidence row for a non-opportunity

### ⚠️ Sources table not yet populated — needs a prompt change

`tblSources` exists and is correctly shaped, but `Opportunity Research` does not currently
return structured source data — its JSON has `evidence_summary` (prose) and no
`source_url` / `source_name` fields. The prompt also forbids fabricating URLs, correctly.

To populate Sources properly the Opportunity Research prompt must be extended to return
an explicit `sources` array (name, URL, type, what it supports). That is a prompt change
plus a new write branch — deliberately not done silently, since it alters a prompt that
is currently working.

### Current node count: 28 (main workflow)

### Remaining build items

- [ ] Sources population (needs the Opportunity Research prompt change above)
- [ ] Response Management (inbound Outlook trigger → classify intent → Responses sheet)
- [ ] Follow-up scheduling (`Follow-Up Date` / `Follow-Up Plan` columns exist, unused)
- [ ] Learning loop (outcome logging → feeds scoring)

---

## 2026-08-25 — First real-company run (execution 80) ✅

Self-test against **Grandeur Advisory** (`grandeuradvisory.com`). Only company name and
website were supplied — country, industry, company type and revenue were left blank
deliberately, so the research stage had to *discover* them rather than echo input.

### Research quality — genuine, sourced discovery

From name + website alone it verified:

| Field | Discovered |
|---|---|
| Legal Name | `GRANDEUR ADVISORS LLP` — caught that the legal name differs from the trading name |
| Country / State / City | India / Maharashtra / Pune |
| Company Type | Limited Liability Partnership |
| Industry | Financial Services |
| Ownership | Privately Held |
| Employee Count | 15 (LinkedIn reported), band 11-50 |
| ERP | NetSuite, Odoo |
| Accounting Software | NetSuite, QuickBooks, Xero, Zoho |
| Technology Stack | + Tipalti, Bill, MineralTree, Vend |
| Company Status | Active |
| Verification Status | **Verified** |

`Notes` cited three real sources: the official site, the LinkedIn company page, and the
ZaubaCorp registry record (LLPIN ACB-3005). No fabricated URLs.

### Judgement — the part that actually matters

The agent was handed a company that is **hiring accountants and runs NetSuite** — the
textbook shape of a hot prospect under naive scoring. It correctly refused:

- **ICP Fit: Low** · **Priority: Low** · **Opportunity Score: 0** · **Signal Strength: None**
- Reason: *"the researched company is Grandeur Advisory/Grandeur Advisors itself rather
  than an external prospective customer… no verified evidence shows that it is seeking an
  external finance/accounting provider"*
- Evidence Summary explicitly separated **internal hiring** from a **buying signal**

This is exactly the discrimination the whole design depends on. Scoring is reasoning about
commercial intent, not pattern-matching keywords.

### Guardrails all held

| Guard | Result |
|---|---|
| `Assign Contact IDs` | **zero items** — no contacts written, no invented emails |
| `Assign Signal ID` | **zero items** — no evidence row, correct with Signal Strength `None` |
| `Check Outreach Eligibility` | `Eligible: false` — *"No contactable decision maker with a verified email \| Opportunity score 0 is below the 50 outreach threshold"* |
| `Outreach Draft AI` | never ran — no wasted spend, no draft that could be approved by mistake |

Two independent gates blocked it. The plain-English `Ineligible Reason` made diagnosis
instant.

### 🔴 Bug found and fixed — empty Company Name reaching the draft prompt

`Check Outreach Eligibility` read `Company Name` from the **opportunity** item, which only
carries the 22 opportunity fields — so it resolved to `""`. Any generated email would have
addressed a blank company.

**Fix:** company-level fields now come from `Assign Company ID`. Also added
`Company Website`, `Company Country` and `Company Industry` to the output so the draft
prompt has richer, verified context.

### 🟠 Bug found and fixed — false revenue band from an unknown revenue

Supplying revenue `0` produced `Revenue Band: "Under $1M"` — an unverified claim recorded
as fact, which violates the never-invent rule.

**Fix:** `Assign Company ID` now clears `Revenue`, `Revenue Band` and `Revenue Type` when
no revenue was verified. Unknown stays blank.

### Note on IDs

The run assigned `Grand 001` with `Is New Company: true`, meaning the Companies table was
empty at read time (earlier test rows had been cleared). The seeded test rows in
Contacts/Outreach still reference `Grand 001`, which now resolves to Grandeur Advisory
rather than the old BluePeak fixture — harmless test-data drift, worth clearing before
real use.

### Verdict

Research, qualification, dedup, evidence-suppression and the outreach gates all work on
real data. The pipeline's most important property — **refusing to manufacture an
opportunity that isn't there** — is demonstrated, not assumed.

---

## 2026-08-26 — Verve Advisory: first opportunity above threshold ✅ (execution 82)

First run against a genuine external prospect. Only name + website supplied.

### Company research

| Field | Discovered |
|---|---|
| Legal Name | VERVE ADVISORY PRIVATE LIMITED |
| CIN | U74140PN2020PTC191886, incorporated 11 July 2020 |
| Location | Pune, Maharashtra, India |
| Type / Ownership | Private Limited Company / Privately Held |
| Employees | 120+ (company reported), band 51-200 |
| Company ID | **Grand 002** — correctly incremented |
| Verification Status | Verified |
| **ICP Fit / Priority** | **Medium / Medium** |

Sources: verveadvisory.in, LinkedIn company page, IndiaFilings MCA record, Tofler record.

### 🎯 The most important behaviour in the whole project so far

`ERP`, `Accounting Software` and `Technology Stack` came back **blank**, with this note:

> *"The official website describes Outsourced Accounting, NetSuite Accounting and Offshore
> Staffing as company services; these are service offerings and are not evidence that Verve
> itself uses NetSuite or outsources its own accounting."*

The agent saw "NetSuite" prominently on the site and **refused to record it as Verve's own
ERP**, because it is a service they *sell*, not a tool they *use*. A naive scraper would
have tagged Verve as a NetSuite shop and scored it hot. This is the single clearest proof
that qualification is reasoning about meaning rather than matching keywords.

It also discriminated between prospects: **Medium** for Verve vs **Low** for Grandeur
itself — same industry, different commercial relationship.

### Opportunity — first one to clear the threshold

| Field | Value |
|---|---|
| Opportunity ID | **002** |
| Type | Finance Team Expansion |
| Signal Strength | Medium |
| **Opportunity Score** | **52** — first score above the 50 gate |
| Urgency | Near Term |
| Grandeur Service | Finance Operations |
| Status | Monitoring |

Evidence cited four named openings (Research Analyst – Finance & Taxation, Sr Executive
Finance, Accounts Intern, Financial Modelling Analyst) plus a named recent hire announced
on LinkedIn — and still concluded, correctly, that no explicit *buying* signal exists, so
the status is Monitoring rather than Active.

### Signals layer fired for the first time

`Signal 001` written to `tblSignals`: type, description, strength, evidence, dates, all
linked to `Grand 002` / Opportunity `002`. Evidence layer confirmed working end to end.

### The binding constraint, now proven empirically

`Check Outreach Eligibility` returned exactly **one** blocking reason:

> `No contactable decision maker with a verified email`

The score gate **passed** (52 ≥ 50). Freshness passed. Suppression passed. Duplicate-draft
passed. `Contacts Found For Company: 0`.

A legitimate, scored, evidenced opportunity was produced — and could not be acted on for
one reason only: **no contact data**. This is direct evidence for the recommendation to
buy enrichment (Apollo/Hunter/Lusha) before building any further intake capacity.
More leads upstream of a broken contact step produce more leads nobody can contact.

### 🔴 Process failure on my side — three repeats of the same mistake

Two earlier "fixes" (empty Company Name in drafts, false Revenue Band) **never applied**.
`setNodeParameter` resolves its JSON Pointer against the node's `parameters` object, so a
path of `/parameters/jsCode` silently created a nested junk `parameters.parameters` key
and the real code was untouched. The tool reported `appliedOperations` success both times.

I had already hit and documented this exact gotcha, then repeated it twice more — once on
the array path, once on `jsCode`, and once when switching the test company (which caused a
wasted run researching Grandeur instead of Verve).

**Rule adopted:** never use `setNodeParameter`. Always `updateNodeParameters` with
`replace: true`, and **always verify by reading the node back** rather than trusting the
success response.

Both fixes have now been reapplied and verified live:
- `Check Outreach Eligibility` parameter keys are `jsCode, language, mode` (junk key gone),
  references `Assign Company ID`, and emits `Company Website` / `Country` / `Industry`
- `Assign Company ID` contains the `!Number(out['Revenue'])` guard clearing Revenue,
  Revenue Band and Revenue Type

### Bonus: repeat-company behaviour verified (execution 81)

The wasted run accidentally proved the Monitoring path: re-researching Grandeur returned
`Is New Company: false` and `Is New Opportunity: false`, reused `Grand 001`, updated in
place, and surfaced a **new** signal the first pass missed (AICTE internship dated
2026-06-25) plus a fourth source. Re-research refreshes rather than duplicates.

---

## 2026-08-26 — Target-country gate

Owner ruled **India out of scope** (raised via Verve Advisory, an Indian company that had
just scored 52 and cleared the quality gate). Handled as a **general rule**, not a one-off
suppression entry, so the whole class of error is closed permanently.

### Implementation

A `COUNTRY_ALIASES` map in `Check Outreach Eligibility` covering the 23 markets from the
brief — USA · UK · Australia · Germany · Canada · Singapore · UAE · Netherlands · Ireland ·
New Zealand · France · Switzerland · Belgium · Sweden · Denmark · Norway · Spain · Italy ·
Hong Kong · Japan · South Korea · Saudi Arabia · Qatar — with common variants
(`United States` / `US` / `America`, `England` / `Scotland` / `Wales` /
`Northern Ireland` → UK, `Dubai` / `Abu Dhabi` → UAE, `Holland` → Netherlands, `KSA` →
Saudi Arabia, and so on).

Blocking behaviour:
- Country outside the list → `"India is outside Grandeur target markets"`
- Country blank/unverified → blocked conservatively, since target market cannot be confirmed
- Adds `Target Market` to the output (resolved market name, or `OUT OF SCOPE`)

**Scope of the gate:** it blocks **outreach only**. Out-of-market companies are still
researched, scored, and monitored — the data stays useful, but no draft is ever generated
and no email can ever be sent. This also means no OpenAI spend on drafting for
out-of-scope companies.

Verve Advisory (`Grand 002`) is now permanently un-emailable via this rule despite its
score of 52. An explicit `tblSuppression` row remains available if a hard,
country-independent block is ever wanted.

### Enrichment provider research — n8n native node availability

Checked which providers have first-class n8n nodes (materially easier than raw HTTP):

| Provider | Native node | Operations |
|---|---|---|
| **Hunter** | ✅ `n8n-nodes-base.hunter` | `domainSearch`, `emailFinder`, `emailVerifier` |
| **Dropcontact** | ✅ `n8n-nodes-base.dropcontact` | `contact:enrich` (from name + website) |
| **Clearbit** | ✅ `n8n-nodes-base.clearbit` | `person:enrich`, `company:enrich`, `company:autocomplete` |
| **Apollo** | ❌ none | would require HTTP Request |

**Hunter is the recommended primary.** Its three operations map exactly onto the gap:
Contact Research AI already finds the *person and title* reliably; Hunter's `emailFinder`
turns name + domain into an address, and `emailVerifier` confirms deliverability before
anything is written as `Verified`. That keeps the never-invent rule intact — a verifier
result is evidence, not a guess.

Dropcontact is the alternative where EU/GDPR posture matters most (French company,
computes rather than resells a scraped database).

---

## 2026-08-26 — Hunter email enrichment (built, needs credential)

Closes the single constraint every run has hit. Decision taken with owner: when Hunter
cannot fully verify an address, **still use it but flag `Unverified`** so it reaches the
approval queue and the human decides per lead.

### Chain

```
Assign Contact IDs → Prepare Enrichment → Hunter Find Email → Apply Enrichment → Upsert Contact
```

**`Prepare Enrichment`** (Code) — derives the company domain from `Website` (strips
scheme/`www`/path) and splits the discovered `Name` into first/last for Hunter's API.

**`Hunter Find Email`** (`n8n-nodes-base.hunter`, `emailFinder`) — `onError:
continueRegularOutput` with 2 retries, so a miss or API hiccup never kills the run.

**`Apply Enrichment`** (Code, `runOnceForEachItem` for correct item pairing) —
- **never overwrites** an email the research stage already verified
- confidence **≥ 90** → `Verified`; below → written but `Unverified`
- no address → `Email` blank, status `Unverified`
- appends provenance to `Notes`: *"Email found via Hunter (confidence 94)"*
- strips the temporary `Enrich *` helper fields before the Excel write

`VERIFIED_SCORE = 90` is a single tunable constant.

### Not yet attached

The node has **no credential bound** — `hunterApi` must be created by the owner
(see `docs/OWNER_SETUP.md` §5). Deliberately not stubbed with a synthesised credential ID.

### Design note

This preserves the never-invent rule rather than weakening it. The earlier prompt
explicitly forbids the model from *guessing* or pattern-matching an address
(`firstname.lastname@domain`). Hunter does not guess either — it returns addresses it has
actually observed, with a confidence score. An address now enters the system as evidence
with a recorded source, not as a model's invention.

### Node count: 31 (main workflow)

---

## 2026-08-26 — LHH run: Hunter works, contact bottleneck solved (executions 83, 84)

### Execution 83 — country gate verified, and a third qualification insight

`Company Country: USA` → `Target Market: USA`. First clean pass through the country gate.
**Grand 003**. Industry discovered as *"Talent solutions, recruitment, leadership
development, coaching, career mobility and outplacement"*.

Scored **0**, with this reasoning:

> *"Recent LHH finance/accounting job postings found in search results are **recruitment
> assignments for LHH clients** rather than evidence that LHH is expanding its own finance
> team."*

LHH is a recruitment firm, so its site carries dozens of finance vacancies — advertised
**on behalf of clients**. A keyword matcher scores that red hot. Third consecutive case of
the agent making a distinction that would fool a naive system:

| Company | The trap | What it saw |
|---|---|---|
| Grandeur | Hiring accountants + runs NetSuite | internal hiring ≠ buying signal |
| Verve | "NetSuite" throughout the site | a service they *sell*, not a tool they *use* |
| LHH | Dozens of finance job posts | postings **for clients**, not their own team |

### 🔴 Architectural flaw found: the enrichment chain could never execute

`Hunter Find Email` had **no run data at all**. Not a config fault — a wiring one.

`Assign Contact IDs` returns **zero items** when the model cannot verify a named person.
In n8n a node receiving zero items does not execute, so the entire enrichment chain
downstream was silently skipped. Hunter could never have fired for any company.

Worse, the design was circular: `emailFinder` requires a first and last name, but the
missing thing *was* the names.

### Fix: Hunter domainSearch as the primary contact source

```
Contact Research AI → Hunter Domain Search → Get Existing Contacts → Assign Contact IDs → Upsert Contact
```

`Hunter Domain Search` queries the company domain directly, filtered to
`seniority: [senior, executive]` and `department: [finance, executive, management]`,
returning names, titles **and** addresses together — no name needed first. It sits
*before* the merge, so it always runs. `alwaysOutputData` and `continueRegularOutput`
keep a miss from stopping the chain.

`Assign Contact IDs` rewritten to merge both sources: Hunter's address wins, the model's
research fills in detail, candidates are ranked (finance department and CFO/Controller/
Finance Director titles score highest), then sequential IDs are assigned with the existing
dedup.

**Cost:** one credit per company instead of one per contact.

### Execution 84 — it worked

`Contacts Found For Company: 10`. Real addresses written to `tblContacts`, e.g.
`erika.ruth@lhh.com` (VP), `bernice.alexander@lhh.com` (VP),
`patience.matiwane@lhh.com` (GM) — each with LinkedIn URL, confidence 85, and provenance
in `Notes`.

Eligibility dropped from two blockers to **one**:

> `Opportunity score 0 is below the 50 outreach threshold`

**The contact bottleneck — the single constraint on every prior run — is solved.**

### 🟠 Quality problem found in the same result, and fixed

Every contact Hunter returned was a **generic VP or General Manager** — department
`executive` / `management`, **not one in finance**. The ranking fell back to seniority and
marked a non-finance VP as `Primary Decision-Maker: Yes`.

Emailing an unspecified VP at a 10,000-person firm about outsourced accounting is
spray-and-pray: it gets ignored and it costs sender reputation. Volume was never the goal.

**Fix:** a `financeRelevant()` test (department contains finance, or title matches
CFO / finance / financial / controller / accounting / treasury / FP&A / bookkeeping).
Eligibility now **requires** a finance-relevant contact and reports the shortfall
honestly:

> `No finance decision maker identified (10 non-finance contacts on file)`

New debug counters: `Reachable Contacts`, `Finance Contacts`.

The contacts are still stored — they are real, useful company intelligence — they just
cannot be the recipient of a finance pitch.

### Note on Hunter data quality

Confidence came back at **85** for all ten, below the `VERIFIED_SCORE = 90` threshold, so
all were written `Unverified` — correct per the owner's decision, and they still surface
for approval. One address carried `verification.status: "accept_all"`, meaning the domain
accepts any address — a known deliverability caveat worth remembering when reviewing.

### LHH verdict

Correctly **not a prospect right now**. The agent cited Adecco Group's Q2 2026 results
(LHH revenue flat) and Ranjit de Sousa's May 2026 appointment as LHH President, and found
no finance-related buying signal in either. The system is working; LHH simply is not
in-market today. It stays in the database and will be re-checked by the monitoring path.

---

## 2026-08-26 — Prospect Discovery engine + first draft written to Outreach ✅

### New workflow — `Grandeur BD Agent - Prospect Discovery` (`iEZAsjljfX0jXF83`)

The missing first stage of the architecture: the system now finds its own prospects.

A web-search discovery step with the exclusions learned from three rejected companies
encoded directly in the prompt — no accounting firms, CPA firms, outsourcing/BPO
providers, consultancies, recruitment agencies, and specifically *"companies whose
finance job postings are recruitment listings placed on behalf of clients rather than
their own hiring"* (the LHH lesson). Every candidate must carry a real source URL, and
an empty array is an accepted answer.

**First run returned five real US mid-market prospects**, each with a live URL:

| Company | Signal |
|---|---|
| **Aescape** (149 staff) | Accounting Manager, NetSuite required, already uses a third-party accounting firm |
| **Afresh** | Controller; 70% revenue growth; wants to automate AP/AR and compress close |
| **Clair** | Accounting Manager; multi-entity consolidation + ERP implementation |
| **GC AI** | First Controller; 10x growth — but moving accounting *in-house from* an outsourced bookkeeper |
| **Fi** | Accounting Manager, NY |

GC AI is worth noting as a counter-example: strong on paper, but a company *exiting*
outsourcing is arguably a negative signal. A naive scorer would rank it top.

### Contact discovery rebuilt twice

**Problem 1 — the enrichment chain could never execute.** `Assign Contact IDs` emits zero
items when no named person is verified, and an n8n node with zero input does not run, so
Hunter sat permanently downstream of a dead branch. The design was also circular:
`emailFinder` needs the names that were missing.

**Fix:** `Hunter Domain Search` (domainSearch) placed *before* the merge, so it always
runs. Verified on LHH: **10 real addresses** written.

**Problem 2 — domain search returns nothing for smaller companies.** `aescape.com`
returned `{}`, while research found the ideal person (Lisa Hu, SVP Finance &
Administration) with no address.

**Fix:** re-added `emailFinder` as a fallback behind an IF, so it runs *only* for
contacts lacking an email. Result: `nick@aescape.com` (confidence 95),
`frank.britt@aescape.com` (97), `lisa.hu@aescape.com` (99) — all Verified.

The two Hunter operations are complementary: domainSearch finds people at well-indexed
companies, emailFinder converts a researched name into an address at smaller ones.

### 🔴 My own bug: overriding the research stage's judgement

`Assign Contact IDs` was force-marking whoever ranked first as `Primary Decision-Maker`.
That produced a misleading flag on a generic VP at LHH, and failed the opposite way at
Aescape — research *correctly* identified the SVP Operations as the accounting decision
maker (the posting names him as the Accounting Manager's manager), but a title regex
cannot see that.

**Fix:** Primary/Backup are now designated only where the research explicitly said so, or
the role is plainly finance. Ranking orders candidates; it no longer promotes anyone.
Eligibility accepts either path.

The principle: a regex cannot know a specific SVP owns the accounting hire. The research
stage read the posting and did know. Trust the reasoning over the pattern match.

### 🎯 All gates cleared — first real draft

`Eligible: true` · USA ✅ · score 82 ✅ · fresh ✅ · not suppressed ✅ · no prior
outreach ✅ · verified designated decision maker ✅
(`Contacts Found: 3 · Reachable: 2 · Valid: 2`)

Sample draft (score 82 run):

> **Subject:** Accounting support as finance scales
>
> Hi Nick Nelson,
>
> Aescape's current Accounting Manager posting says the role will leverage a third-party
> accounting firm across accounting operations, technical accounting, reporting, tax and
> audit support, while initially reporting to the SVP of Operations.
>
> Grandeur Advisory provides outsourced accounting support that can supplement an
> existing external model, including month-end close, financial reporting, AP/AR and
> NetSuite support…

Note *"can supplement an existing external model"* — it understood Aescape already has an
accounting firm and pitched alongside rather than pretending to displace, matching the
qualification stage's own conclusion.

### 🔴 Outreach write: worksheet upsert fails on this sheet

`Upsert Outreach` failed twice with
`400 InvalidArgument — The number of rows or columns in the input array doesn't match the
size or dimensions of the range`, under **both** auto-map and explicit column mapping. The
worksheet-level upsert cannot reconcile the Outreach sheet's used range.

**Fix:** switched to **`table: append`**, which respects the table's own column definition
and was already proven on this sheet by the seeder. Append is also the correct semantics —
creating a new draft is an insert, and the duplicate-draft guard upstream prevents two
pending drafts for one opportunity.

**Result: the draft row landed in `Outreach` with `Approval Status = Pending Approval`.**

### Sender: approval-triggered sending

Excel cannot push change events to n8n, so approval is detected by polling. Options were
put to the owner with the execution cost of each:

| Approach | Latency | Executions/month |
|---|---|---|
| Poll every 1 min | ~60 sec | ~43,000 |
| **Poll every 15 min, business hours** ← chosen | ~15 min | ~1,100 |
| Power Automate → webhook | instant | ~1 per approval |

`Check For Approvals` now runs `*/15 8-20 * * 1-5`. ⚠️ This uses the **n8n instance
timezone** — owner to confirm it is set to their working timezone.

### Behaviour worth watching

Opportunity type varies between runs as research surfaces different signals for the same
company (Finance/Accounting Outsourcing vs Finance Operations). Since opportunity dedup
keys on **company + type**, genuinely different signals create separate opportunities —
correct by design, but it means repeated runs on one company can accumulate rows.

### ✅ Instance timezone confirmed — no change needed

The `*/15 8-20 * * 1-5` cron is interpreted in the **n8n instance timezone**, which was an
open unknown. Rather than ask, a throwaway two-node diagnostic workflow reported it:

```
Workflow Timezone:   Asia/Calcutta
Local Now:           2026-08-26T23:26:13+05:30
Local Offset:        +330 minutes
Container Timezone:  UTC
```

So the sender polls **08:00–20:45 IST, Mon–Fri** — already the owner's real business hours.
The schedule stands as written. Diagnostic workflow archived after reading.

Worth noting for future date logic: the *container* clock is UTC while `$now` (Luxon) is
IST. Code nodes that use `new Date()` get UTC; anything using `$now` gets IST. The Sender's
`Build Send Queue` stamps `Send Date` from `new Date().toISOString().slice(0,10)`, so
between 18:30 and 00:00 IST the stamped date is the previous calendar day. Harmless for the
30-day gate, but the recorded date can read a day early on late-evening sends.

### 🔴 Double-email risk: re-engagement guards keyed on the wrong ID

Both outreach guards in `Check Outreach Eligibility` — the 30-day re-engagement gate and the
duplicate-draft guard — matched on **Opportunity ID**:

```js
if (idKey(r['Opportunity ID']) !== idKey(opportunityId)) continue;
```

This is the same defect from two angles. Opportunity dedup keys on *company + type*, and
research words the type differently between runs (Aescape produced both
`Finance / Accounting Outsourcing` and `Finance Operations`). A re-run therefore mints a
**fresh Opportunity ID for the same company**, and both guards look up an ID that has no
history — so a second draft to the same person passes every gate and can be approved and
sent, inside the 30-day window.

This sits directly under the approve→send path, which is exactly where the "don't become a
spam cannon" principle has to hold: the owner has to be able to trust that approving a row
sends one email to one person.

**Fix:** both guards now key on **Company ID**.

```js
// The two guards below are scoped to the COMPANY, not the opportunity.
// A re-run can mint a fresh Opportunity ID for the same company whenever
// research words the opportunity differently, so an opportunity-scoped
// guard lets a second email reach the same people.
if (idKey(r['Company ID']) !== idKey(companyId)) continue;
```

The pending-draft reason now names the blocking row (`Outreach ID N`) so a skip is
traceable rather than mysterious.

**Deliberate trade-off:** one email per company per 30 days, even when a company has two
genuinely distinct opportunities. Blocking is the safe direction — a missed second pitch
costs a cycle, a duplicate cold email costs the relationship. Revisit only if a real case
appears where two same-company opportunities clearly warrant separate conversations.

Verified by reading the node back and diffing against the intended source: identical, and
`parameters` has exactly `jsCode`/`language`/`mode` — no nested `parameters` object from
the `setNodeParameter` footgun.

### 📧 First real outreach email sent

Owner approved the Aescape draft in chat. Before sending, the live sheet was read back to
confirm the row and the recipient rather than trusting the earlier execution output:

```
Outreach ID 1 · Grand 004 · Opportunity 5 · Contact 12
Nick Nelson · SVP Operations · nick@aescape.com
Email Verification Status: Verified   (Hunter confidence 95)
Primary Decision-Maker: Yes           Do Not Contact: No
Approval Status: Pending Approval     Sent Date: (empty)
```

`Approval Status` was then set to `Approved` through the same Excel worksheet upsert the
sender uses, so the sheet carries a real approval record rather than a side-channel send.
The sender ran and `Send Outreach Email` returned `{ success: true }`. Outreach row now
reads `Sent Date 46260 · Outreach Status Sent · Draft Status Sent`.

**This is the first genuine outbound email the system has produced end to end** —
researched, scored, qualified against six gates, drafted, human-approved, and sent.

### 🔴 `Stamp Opportunity Last Outreach` silently wrote nothing

The send succeeded but the last node returned a row where *every field was an empty
string*. `Last Outreach Date` was empty on all five Opportunities rows, including the one
just emailed.

Root cause is not Excel. The Excel upsert node emits a `pairedItem` index pointing at the
**sheet row it touched**, not at the input item it came from. `Stamp Opportunity Last
Outreach` sat downstream of `Mark Outreach Sent` and resolved its match value with:

```js
{{ $('Build Send Queue').item.json['Opportunity ID'] }}
```

`.item` walks the paired-item chain backwards. Through `Mark Outreach Sent` that chain
said `item: 1`, but `Build Send Queue` had emitted a single item at index 0, so resolution
fell through to empty and the upsert matched nothing. `Mark Outreach Sent` used the
identical expression and worked — because *its* input came from the Outlook node, whose
pairing was still intact. The defect only appears one hop past an Excel node.

**Fix:** rewired so `Send Outreach Email` feeds `Mark Outreach Sent` **and**
`Stamp Opportunity Last Outreach` as parallel branches. Both now sit one hop from the
Outlook node, both resolve `.item` correctly, and neither depends on the other.

**Rule worth keeping: never use `$('Node').item` downstream of a Microsoft Excel node.**
Either branch from a node with intact pairing, or read the value from `$json`.

No blank row was appended — the Opportunities table still holds exactly 5 rows, none
blank. Opportunity 5 was backfilled to `2026-08-26` to match the Outreach `Sent Date`.

### ⏰ Owner rule: send only 15:00–02:00 IST, Mon–Fri

Set by the owner immediately after the first send. The window spans midnight on purpose —
it tracks the US working day, where the target markets are.

Three changes, because a cron alone is not enforcement:

**1. Timezone pinned.** The sender's `settings.timezone` is now `Asia/Kolkata` explicitly
rather than inherited. This mattered: the schedule trigger's manual-execution output
reported `Timezone: UTC (UTC+00:00)` while a Code node's `$now.zoneName` reported
`Asia/Calcutta`. Rather than reason about which one governs cron scheduling, the setting
is now stated on the workflow and the ambiguity is gone. (Verified on a disposable
workflow first that `setWorkflowSettings` preserves `availableInMCP` — it does.)

**2. Schedule covers the window in two legs**, since cron cannot express a range crossing
midnight:

```
*/15 15-23 * * 1-5     Mon-Fri  15:00 - 23:45
*/15 0-1  * * 2-6      Tue-Sat  00:00 - 01:45   (tail of the previous weekday evening)
```

**3. Hard gate inside `Build Send Queue`.** The cron controls when the workflow *runs*; it
cannot stop a manual execution. The queue builder now checks the clock itself and returns
`[]` outside the window — and a node with zero input items does not execute in n8n, so the
Outlook node cannot fire at all:

```js
const eveningLeg      = weekday >= 1 && weekday <= 5 && hour >= 15;
const afterMidnightLeg = weekday >= 2 && weekday <= 6 && hour < 2;
if (!eveningLeg && !afterMidnightLeg) return [];
```

**Also fixed while here:** `Send Date` came from `new Date().toISOString()`, which is the
*container* clock — UTC. Between 18:30 and 00:00 IST that reports the previous day. Now
harmless-sounding, but the new window is deliberately mostly after 18:30 IST, so nearly
every future send would have been stamped a day early. Now `$now.toFormat('yyyy-LL-dd')`
in pinned IST.

One consequence stands in the record: the Aescape email went out at 01:35 IST on
2026-08-27 but is stamped `2026-08-26`, because it was sent under the old UTC logic. Left
as-is so the Outreach and Opportunities rows agree with each other; every send from here
is stamped in IST.

### 🌐 Remote-only rule

Owner rule: pursue only remote roles, not hybrid and not on-site. The reasoning is
delivery, not preference — Grandeur works remotely, so a role requiring presence in a
Tampa office cannot be served no matter how strong the finance signal is. Filtering it out
at qualification stops the system spending research and a send on something unwinnable.

Nothing in the schema recorded work arrangement, so this took two changes:

**1. Research must report it.** `Opportunity Research` now has a `WORK ARRANGEMENT`
section requiring `evidence_summary` to begin with exactly one tag:

```
WORK ARRANGEMENT: Remote |
WORK ARRANGEMENT: Hybrid |
WORK ARRANGEMENT: On-site |
WORK ARRANGEMENT: Not stated |
WORK ARRANGEMENT: Not a job posting |
```

The prompt forbids inferring the arrangement from the company's general policy, from the
city in the posting, or from what is typical for the role. A posting naming a headquarters
is not thereby on-site. This kept the change inside the existing 22-field JSON contract —
no new Excel column, so nothing was blocked on the owner.

Applied as a **merge** update (`replace: false`) supplying only `responses`, so `modelId`,
`options`, and the `builtInTools` web-search config survived untouched. Verified by
diffing the read-back against the intended text: identical.

**2. Eligibility enforces it.** A seventh gate parses the tag:

| Tag | Outcome |
|---|---|
| `Remote` | pursue |
| `Not a job posting` | pursue — an ERP migration or CFO appointment has no work arrangement |
| `Hybrid` / `On-site` | blocked |
| `Not stated` | **blocked** |
| tag missing entirely | **blocked** |

Blocking `Not stated` is the never-invent rule applied to a new field: if the posting does
not say the role is remote, we do not email on the assumption that it could be. The
tradeoff is real — some genuinely remote roles with vague postings will be skipped — and
it is the right direction, because the failure mode on the other side is pitching offshore
delivery to someone who needs a person in the building.

The five existing opportunities carry no tag and are therefore now blocked until
re-researched. Correct: they were qualified before the rule existed.

### ⏱️ One email per 10 minutes

Owner rule: emails go out at 10-minute intervals, not in a batch. Two changes:

```
*/10 15-23 * * 1-5     poll every 10 min, Mon-Fri 15:00-23:50
*/10 0-1  * * 2-6      poll every 10 min, Tue-Sat 00:00-01:50
```

and `SEND_BATCH_SIZE = 1` in `Build Send Queue`, so each run sends at most one email and a
backlog drains one at a time. `Queue Depth` is now carried on each queued item so a run
records how many drafts were waiting rather than silently sending one of many.

This is reputation protection, not politeness. A batch of cold emails leaving a domain in
one second is the clearest spam signal a mail provider sees, and `grandeuradvisory.com` has
no sending history to absorb it.

### 🟢 LIVE

`Grandeur BD Agent - Outreach Sender` is **published and active** (version
`ca6bcea2-289f-444a-aebd-8108acc90b1b`). Approving a row in the Outreach sheet now sends
without anyone triggering anything.

Activation was safe to do immediately: the only Outreach row is Outreach ID 1, already
`Sent`, so no queued draft fired on publish.

The human approval gate is untouched and remains the core control — the system drafts and
queues, a person still decides. What changed is that the decision now executes itself.

### 🔧 Owner revision: unstated work arrangement now qualifies

The remote-only gate shipped blocking three cases — `Hybrid`, `On-site`, and anything
unstated. The owner revised it the same day: only an **explicit** hybrid or on-site
requirement disqualifies. A posting that says nothing about arrangement is an opportunity.

The judgement behind the revision is sound, and it overrides mine. I blocked `Not stated`
by extending the never-invent rule to a new field. But never-invent governs what we
*record as fact*, not how we *prioritise a lead* — and most job postings simply omit the
line. Blocking silence would have discarded the majority of the funnel to avoid a
mis-pitch that costs one ignored email. The gate is now a single condition:

```js
if (wa === 'hybrid' || wa === 'onsite') {
  reasons.push('Role is ' + workArrangement + ' and Grandeur delivers remotely');
}
```

The research tag stays exactly as it was — it still reports `Not stated` honestly rather
than guessing `Remote`. Only what we *do* with that answer changed. That separation is
worth keeping: research records the truth, policy decides what to do about it.

### ✍️ Draft rewrite: from capability list to actual proposal

The Aescape email was accurate and evidence-backed, and still generic where it counted. It
closed with five services — "AP/AR, reconciliations, financial reporting, month-end close,
and NetSuite support" — which reads as a brochure, and it never said what Grandeur is. A
stranger receiving it had no idea who was writing.

The prompt now specifies a five-part body:

1. the verified signal, one specific sentence
2. the concrete finance work that situation creates
3. **who Grandeur is** — one plain sentence, since the reader has never heard of the firm
4. the proposal: the specific work Grandeur would take on *here*, and how it would work
5. the close, carrying `https://grandeuradvisory.com/` and a low-friction ask

Three mechanisms do the real work:

**The swap test.** Stated as a hard check before returning:

> If this email could be sent to a different company by changing only the company name
> and the person's name, it has FAILED. Rewrite it.

**A cap on the pitch.** At most three pieces of proposed work, each traceable to something
in the Evidence. The cap is the fix for the brochure problem — five services is not more
persuasive than two, it is less, because it signals the sender did not read anything.

**A ban on empty category words.** "Solutions", "support", "services", "processes",
"operations" may not appear alone without saying support *with what, exactly*.

Grandeur's own description is fixed text in the prompt, sourced from PROJECT_BRIEF §2 —
the owner's own words — with `That description is the ONLY thing you may say about
Grandeur. Do not extend it.` The company website is blocked by this environment's egress
proxy, so it could not be read; using the owner's brief avoids inventing positioning that
the real site might contradict. Pricing, contract terms, team size, turnaround times and
years of experience are explicitly banned as unverified.

One trap closed: `Evidence Summary` now begins with the internal `WORK ARRANGEMENT: ... |`
routing tag, and without instruction the model would have quoted it into a customer-facing
email. The prompt names the tag and says to ignore it.

Word count moved 90–130 → 130–180. The old ceiling could not hold a signal, an
introduction, a specific proposal and a link.

### ✅ Verified: work-arrangement tag works on a live run

Ran the main workflow against **Afresh** (a US prospect from the discovery workflow), since
Aescape is now blocked by its own 30-day company guard. The tag came back clean:

```
Work Arrangement: Remote        Opportunity Score: 82
Evidence Summary: "WORK ARRANGEMENT: Remote | Afresh's current Greenhouse posting
explicitly lists the Controller role as 'Remote - United States.' ..."
```

Research quoted the posting rather than inferring, the gate parsed it, and the opportunity
qualified. Both halves of the rule work.

**Afresh then failed at a different gate: `No contactable decision maker with a verified
email` — `Contacts Found For Company: 0`.** Contact discovery plus Hunter found nobody. So
a company scoring 82, in a target market, on a verified remote finance signal, produced no
outreach. This is the contact-enrichment ceiling reasserting itself, and it is now the
binding constraint again: qualification is working better than sourcing.

Note also: `get_workflow_execution` reported this run as `status: running` with empty
runData for 12+ minutes after it had actually succeeded in 1m48s. `search_workflow_executions`
had the correct status the whole time. **Trust the search endpoint over the detail endpoint
for execution status.**

### ✍️ Draft copy verified against a real record

Because Afresh produced no draft, the rewritten prompt was rendered in a throwaway preview
workflow against Aescape's real opportunity and contact records — the same inputs that
produced the original generic email, so the two are directly comparable. (One field was a
stand-in: the Aescape record predates the tag, so `WORK ARRANGEMENT: Not stated |` was
prefixed to exercise the ignore-the-tag rule.)

Result: signal named specifically, the work it creates spelled out, Grandeur introduced in
one sentence, exactly three pieces of proposed work — partner billing and collections,
settlement and revenue-share reconciliation, NetSuite workflows — all traceable to the
evidence, the link present once, and the tag correctly ignored. It passes the swap test:
nothing in it transfers to another company.

### 🔴 Trailing punctuation would have broken every link

The first preview render closed with:

```
More about Grandeur is at https://grandeuradvisory.com/.
```

The full stop sits flush against the URL. Outreach is sent as **plain text**
(`bodyContentType: Text`), so the recipient's mail client auto-linkifies the URL itself,
and Outlook's plain-text linkifier has historically absorbed trailing punctuation into the
href. That would have produced a dead link in the only call to action in the email — on
every send, silently, with nothing in the logs to show for it.

Caught only because the copy was actually rendered rather than assumed. The prompt now
carries an explicit rule with a worked example, and the re-render confirms it:

```
You can see more at https://grandeuradvisory.com/ and if that kind of additional
capacity is relevant, would it be worth a short conversation?
```

### ⚠️ Open: the emails have no signature

`Send Outreach Email` sets `bodyContent` to the draft body and nothing else, and the draft
prompt explicitly says *"Do NOT include a signature... The sender adds those."* Nobody adds
them. Every email so far has gone out with no sign-off, no sender name, and no contact
details beyond the From address.

Not fixed here because it needs a decision that is not mine to make: who signs (a named
person or the firm), what title, and whether to include a phone number. Flagged to the
owner.

### ❓ Question-led email structure

Owner revision to the body: greet properly, then **ask** whether they are looking for what
the job post asks for, then say how Grandeur solves it. The body spec is now six ordered
paragraphs:

1. `Hi <Name>,` on its own
2. one short warm line — "Hope the week is going well at <Company>."
3. **the question**, in the evidence's own terms, ending in a question mark
4. one sentence on who Grandeur is
5. how Grandeur solves *exactly that*, with the standing three-item cap
6. the close, with the link and a low-friction ask

Paragraph 3 replaces the old statement-of-signal opener. Same evidence, different move:
the old version told them what we had noticed about them, the new one asks whether the need
we inferred is real. It also hands the reader a one-word reply, which is the cheapest
possible response to a cold email.

Paragraph 5 carries an explicit constraint — *"must answer the question in paragraph 3, not
change the subject"* — because a question followed by an unrelated pitch is worse than no
question at all.

The prompt covers the non-job-posting case too: where the signal is an ERP migration, a
funding round or a CFO appointment, the question asks about the finance work the evidence
shows they are taking on, rather than forcing a hiring frame that does not fit.

### 🔴 The URL rule caused a run-on sentence

Fixing the trailing-punctuation bug created a second one. Told never to put punctuation
after the URL, the model dropped the sentence terminator entirely:

```
You can see more at https://grandeuradvisory.com/ Would it be worth a short conversation?
```

Two sentences fused, no full stop. The rule was correct about what to avoid and silent
about what to do instead, so the model satisfied it in the laziest available way.

**Fix:** state the positive requirement rather than only the prohibition — the URL must sit
**inside** a sentence, never end one, so the full stop lands well clear of the link. The
prompt now carries one correct example and both wrong ones. Re-render confirms:

```
You can see more at https://grandeuradvisory.com/ if useful for context. Would it be
worth a short conversation about whether this could complement the work Aescape is
building out?
```

Worth remembering as a prompt-writing rule in its own right: **a prohibition without a
replacement gets satisfied by deletion.** Both bugs here were found by rendering the copy,
neither by reading the prompt.

Also re-confirmed the `setNodeParameter` array limitation the hard way — `/responses/values/0/content`
fails with *"cannot descend into non-object at '/responses/values'"*. `updateNodeParameters`
with `replace: false` is the only way to edit a prompt in place.

### 🚨 OUTAGE: Excel credential expired — the live sender has been failing silently

Found while testing the new intake, not by any alert. The Microsoft Excel OAuth credential
(`t05ZuN05jLPuMapG`) has stopped refreshing:

```
NodeApiError: The credential "Microsoft Excel account" needs to be reconnected.
Access could not be refreshed because the connected account has revoked access, the
refresh token expired, or the account password or permissions changed.
```

Timeline from the execution history:

| | |
|---|---|
| Last successful sender run | execution **119**, 2026-08-27 **12:20 UTC** (17:50 IST) |
| Every run since | **failed** — 21 consecutive ticks |
| Duration | ~3.5 hours before anyone noticed |

The sender is `active: true` and fires every 10 minutes, so it has been erroring on every
tick. During that window nothing could be read from Outreach, no approval could be
detected, and nothing could send. The workbook is the database for the whole system, so
this takes out the main pipeline too.

Only the owner can fix it — OAuth reconnection means clicking through Microsoft consent in
the n8n credential UI. It cannot be done over the API.

One piece of luck: the failure is at `Get Outreach Rows`, the *first* Excel node in the
sender, so no run got far enough to half-write a row or send a duplicate. The data is
consistent; the system was simply dead.

**The real lesson is not the expiry — refresh tokens expire, that is normal. It is that an
active workflow failed 21 times in a row and told nobody.** n8n supports an error workflow
per workflow (`settings.errorWorkflow`) that fires on any production failure. Nothing here
has one. That is the next thing to build once the credential is back, and it should have
existed before anything was set live.

### ⚙️ Automatic intake built (untested)

The main workflow is no longer manual-only. Added:

```
Scheduled Intake (0 9-21 * * 1-5, Asia/Kolkata)
  → Get Research Queue   (tblCompanies, all rows)
  → Pick Next Company    (Code)
  → Company Research AI  (existing chain, unchanged)
```

The manual trigger and `Test Company Input` are deliberately kept alongside, so on-demand
testing still works. No node downstream referenced `Test Company Input` by name — the only
coupling was six field names (`Company Name`, `website`, `country`, `industry`,
`company_type`, `revenue`) — so `Pick Next Company` emits exactly those and nothing else in
the chain needed touching.

**One company per run, and that is a correctness requirement rather than a simplification.**
Every lookup node downstream is marked `executeOnce`:

```
Get Existing Companies · Get Existing Opportunities · Get Existing Contacts
Get Existing Signals · Get Outreach History · Get Company Contacts
Get Suppression List · Get Clients · Hunter Domain Search
```

In a multi-company batch each of those would read its table once at the start and never see
rows appended mid-run, so the second company would be assigned the same Company ID and
Opportunity ID as the first. Running one per tick and scheduling more often avoids the
problem outright instead of trying to work around `executeOnce`.

Selection rules in `Pick Next Company`: skip statuses (`excluded`, `suppressed`,
`do not contact`, `client`, `closed`, `disqualified`), never-researched companies first,
then most overdue by `Next Research Date`. A hard `MIN_DAYS_BETWEEN_RESEARCH = 14` floor
overrides `Next Research Date` — without it a badly written date would re-research the same
company every tick and burn OpenAI credit re-deriving data already on file. Zero candidates
returns `[]`, which halts the run; that is the normal idle state, not a failure.

Rate: 13 runs per weekday = ~286 company researches/month. Each run costs three
web-search AI calls, so this is the main OpenAI cost lever — one number to change.

**Untested.** The verification run used the *manual* trigger (n8n prefers it when a
workflow has both), so it went down the `Test Company Input` path and died at
`Get Existing Companies` on the expired credential. `Pick Next Company` has never executed.
It stays unverified, and the schedule stays **off**, until the credential is reconnected.

### Current state: 37 nodes (main), 3 active workflows, sender LIVE but FAILING

Diagnostic workflows built during this session (outreach inspector, opportunities dump,
approval/backfill helpers) were archived after use — they write to live tables and should
not be runnable by accident.
