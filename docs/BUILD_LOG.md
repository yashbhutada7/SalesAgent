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
