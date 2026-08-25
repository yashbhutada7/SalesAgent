# Test Plan

**Test recipient for all sender tests: `info@grandeuradvisory.com`** (the owner's own
inbox — never a real prospect during testing).
**Sender address: `accounting@grandeuradvisory.com`** (delegated Send As).

---

## Test 1 — Research chain on a real company

The `example.com` fixture is treated as a placeholder by the prompts, so Contact
Discovery and everything downstream can never fire with it. A real company is required.

1. Open **Grandeur BD Agent V1** → `Test Company Input`
2. Replace all six values with a real prospect (no leading space in `website`)
3. **Execute workflow**

| Node | Expected |
|---|---|
| `Normalize Research Output` | Real researched values; `ERP` / `Finance Hiring Activity` / `Growth Information` populated where verifiable |
| `Assign Company ID` | `Grand 002` (Grand 001 already exists), `Company Key` = real domain |
| `Map Opportunity Output` | Real `Opportunity Type` + `Evidence Summary`, `Opportunity Score` > 0 |
| `Assign Opportunity ID` | `002`, `Company ID` = `Grand 002` |
| `Contact Research AI` | Real names/titles; **`email` often `""` — that is correct** |
| `Assign Contact IDs` | Contact rows, or empty if nothing verifiable |

🚩 **Red flag:** an email that looks pattern-guessed (`firstname.lastname@domain`) means
a guardrail leaked. Report it.

## Test 2 — Eligibility gate

Same run → open `Check Outreach Eligibility` → read **`Ineligible Reason`**.

It names exactly which gate blocked. Most likely *"No contactable decision maker with a
verified email"* — the known weak link (LLM web search rarely finds published CFO emails).

If `Eligible = true`: check `Outreach Draft AI` produced a subject that genuinely
describes its body, and that a `Pending Approval` row landed in Outreach.

## Test 3 — Sender, end to end (self-contained, run this for a quick win)

### Seed Contacts

| Column | Value |
|---|---|
| Contact ID | `001` |
| Company ID | `Grand 001` |
| Name | `Yash Bhutada` |
| Job Title | `CFO` |
| **Email** | **`info@grandeuradvisory.com`** |
| Email Verification Status | `Verified` |
| Contact Confidence | `High` |
| Primary Decision-Maker | `Yes` |
| Backup Decision-Maker | `No` |
| Do Not Contact | `No` |

### Seed Outreach

| Column | Value |
|---|---|
| Outreach ID | `001` |
| Company ID | `Grand 001` |
| Opportunity ID | `001` |
| Contact ID | `001` |
| Channel | `Email` |
| **Approval Status** | **`Approved`** |
| Draft Status | `Drafted` |
| **Subject** | `Test send from BD agent` |
| **Draft/Message** | two short lines |
| **Sent Date** | **empty** |
| Outreach Status | `Draft` |

### Run

Open **Grandeur BD Agent - Outreach Sender** → **Execute workflow**. Do **not** activate.

### Verify

- Email arrives at **info@grandeuradvisory.com** from **accounting@grandeuradvisory.com**
- Message appears in accounting@'s **Sent Items** (confirms real Send As, not spoofing)
- Outreach row: `Sent Date` filled, `Outreach Status` = `Sent`, `Draft Status` = `Sent`
- Opportunity `001`: **`Last Outreach Date`** filled

### Re-run guard (the important one)

Execute a **second** time → **nothing sends**, no duplicate email. This is the
`Sent Date` guard, and it is what prevents double-emailing real prospects.

### Approval guard

Set a row's `Approval Status` to `Pending Approval` and run → it must be ignored.

---

## Known defect blocking full end-to-end on real prospects

`Check Outreach Eligibility` reads contacts from **this run's** `Assign Contact IDs`
output rather than from the Contacts table. If contact discovery finds nobody on a run,
that node emits zero items and the entire outreach branch is skipped — even when good
contacts already exist in the sheet for that company.

**Fix:** read contacts for the company from `tblContacts` instead of the current run's
discoveries. Pending owner approval.
