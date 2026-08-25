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
