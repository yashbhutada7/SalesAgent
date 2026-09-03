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
| Signature format | **HTML**, linked text `Website \| LinkedIn \| Instagram`, Unicode symbols, no hosted images |
| Body conversion | Escaped, URLs anchored, newlines to `<br>` — HTML collapses newlines |
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

---

# Follow-up cadence — LOCKED 2026-09-02

Owner replaced the original 7-calendar-day gap:

> "instead of making 7 days after last email, make it 2 working days after last email. So if
> first email is sent on Monday then next email should be sent on Thursday. if anything sent
> on Wednesday then next email will go on monday"

**"2 working days" here means two CLEAR working days in between**, so the follow-up lands on
the **third working day** after the send. Both worked examples confirm it, and they are the
spec — Mon→Thu needs Tue and Wed skipped; Wed→Mon needs Thu and Fri skipped:

| Last email | Next email |
|---|---|
| Monday    | Thursday  |
| Tuesday   | Friday    |
| Wednesday | Monday    |
| Thursday  | Tuesday   |
| Friday    | Wednesday |

Saturday and Sunday are never counted and never receive. This is worth stating carefully
because "2 working days later" read naively gives Monday→Wednesday, which contradicts the
owner's own example. The examples win.

```js
// Two clear working days between emails, so the follow-up is due on the third
// working day. Owner's rule, 2026-09-02: Mon->Thu, Tue->Fri, Wed->Mon,
// Thu->Tue, Fri->Wed.
const WORKING_DAYS_AFTER_SEND = 3;

// UTC accessors throughout: Send Date is a date-only value, and using local
// getters would let a timezone offset shift it a day either way.
const addWorkingDays = (from, n) => {
  const d = new Date(from.getTime());
  let added = 0;
  while (added < n) {
    d.setUTCDate(d.getUTCDate() + 1);
    const wd = d.getUTCDay();               // 0 Sun .. 6 Sat
    if (wd !== 0 && wd !== 6) added += 1;
  }
  return d;
};
```

Unchanged by this: **maximum 3 follow-ups**, stop immediately on any reply, always in the
same thread, and the existing send window (15:00–02:00 IST, Mon–Fri, one per 10 minutes).
The due date only makes a follow-up *eligible*; the sender still decides when in the window
it actually goes.

## Two edges the owner should rule on

1. **After-midnight sends.** The window runs to 02:00 IST, and `Send Date` stamps the real
   IST date, so an email sent 00:30 Tuesday is stamped **Tuesday** even though it belongs to
   Monday evening's session. Under this rule it follows up Friday, not Thursday. Using the
   stamped date is the simplest and defensible reading — it genuinely was sent on Tuesday —
   and that is what will be built unless the owner says otherwise.
2. **Public holidays.** Working days means Mon–Fri only. There is no holiday calendar, so a
   follow-up can land on Christmas Day. Adding one is easy but needs the owner to say which
   country's holidays apply — Grandeur's, or the prospect's.

**Status: specified, NOT built.** The sequencer is still blocked on the owner adding
`Sequence Step`, `Sent Message ID` and `Conversation ID` to Outreach (Table6), and on reply
detection, which must exist first — a follow-up sent to someone who already replied is worse
than no follow-up at all.
