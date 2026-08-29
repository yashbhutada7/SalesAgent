# Design — Approve-in-Excel → Outlook Send

Agreed with owner 2026-08-24.

## Decisions locked

| Decision | Choice |
|---|---|
| Approval mechanism | **Approve in the Excel sheet** (set `Status = Approved`) |
| Email account | **Microsoft Outlook** |
| Build target | **Main** workflow `Grandeur BD Agent V1` (`jIghxNOFdVshn2d3`) |
| Email drafting | **Draft before approval, into Excel** (owner approves the real message) |
| Recipient email source | **Hunter** — `domainSearch` then `emailFinder`, confidence recorded |
| Approval detection | **Poll** — Excel cannot push change events to n8n |
| Send window | **15:00–02:00 IST, Mon–Fri** — enforced in the cron *and* in `Build Send Queue` |
| Send rate | **1 email per 10 minutes** — poll every 10 min, `SEND_BATCH_SIZE = 1` |
| Eligible roles | **Not hybrid, not on-site** — only an explicit office requirement blocks; unstated qualifies |
| Draft content | Greeting → warm line → **the question** → who Grandeur is → how we solve it → link + ask |
| The question | "Are you looking for &lt;what the posting asks the hire to own&gt;?" — in the evidence's own terms |
| Website in body | `https://grandeuradvisory.com/`, exactly once, verbatim |
| Signature | Appended by `Build Send Queue`, **not** by Outlook — Graph sendMail adds nothing |
| Signature format | Plain text, bare URLs, no logo or icon images |
| Firm name | **Grandeur Advisors LLP** — Advisors, never Advisory |
| Workflow timezone | **`Asia/Kolkata`, pinned explicitly** on the sender — never inherited |

## Flow

```
── Workflow 1: RESEARCH + DRAFT (extend Main) ─────────────────────
Trigger → Company Research AI → Normalize (39 cols)
        → Draft Outreach Email (NEW AI node)
              writes: Email Subject, Email Body, Contact Name/Title,
                      Status = "Pending Approval"
        → Append/Update Excel

── HUMAN (in Excel) ───────────────────────────────────────────────
Review drafted email in the row → set Status = "Approved"
(and fill Contact Email if option B)

── Workflow 2: OUTREACH SENDER (NEW, separate, scheduled) ─────────
Schedule Trigger → Excel: read rows WHERE Status = "Approved"
        → (guard: Contact Email present)
        → Microsoft Outlook: send (Subject/Body from row)
        → Excel: update row → Status = "Sent", Sent At = now
```

Separate sender keeps the working research baseline intact and puts a hard human gate
between drafting and sending.

## New Excel columns required in `tblCompanies`

`Status` · `Contact Name` · `Contact Title` · `Contact Email` · `Email Subject` ·
`Email Body` · `Approved At` · `Sent At`

`Status` vocabulary: `Pending Approval` → `Approved` → `Sent` (plus `Skipped` / `Failed`).

## Recipient-email source — open fork

- **A** AI fills `Contact Email` only when a public business email is *verifiably* found
  (never invented). Fits the never-fabricate rule; many rows stay blank.
- **B** Owner fills `Contact Email` before approving. Most reliable; keeps control.
- **C** Enrichment tool (Apollo/Hunter) later for real contact data. Bigger add.

Recommendation: **B now + A layered in; C when volume justifies.**

## Prerequisites owned by the human (cannot be done via MCP API)

1. Create `microsoftOutlookOAuth2Api` credential in n8n (OAuth sign-in).
2. Add the 8 columns above to `tblCompanies`.
3. Choose recipient-email option A / B / C.

## Guardrails carried from PROJECT_BRIEF

- Human approval before any send — non-negotiable.
- Never send to a fabricated address.
- Every lead/email carries a reason tied to a verified signal.
- Compliance (GDPR/CASL/CAN-SPAM): capture `data_source` for any contact; honor opt-out.
  (Future columns; noted so the schema can grow cleanly.)

## Build status

- [ ] Fix `=Finance Team Size` / `=ERP` typos in Normalize (Main)
- [ ] Add `Draft Outreach Email` AI node (Main)
- [ ] Extend Append to write outreach columns (Main)
- [ ] Build `Outreach Sender` workflow (Schedule → read Approved → Outlook → mark Sent)
- [ ] Owner: Outlook credential + 8 columns + recipient-email choice
