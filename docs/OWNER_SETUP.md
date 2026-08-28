# Owner Setup Tasks

Three things only the account owner can do. Claude cannot do these via the API:
the Excel node has **no add-column operation** (table resource offers only
`add_table / append / get_columns / get_rows / lookup / delete_table /
convert_to_range`; worksheet writes rows only), and credentials require an
interactive OAuth sign-in.

---

## 1. Add `Subject` column to the Outreach sheet

1. Open **`Grandeur_BD_Agent_V1`** → **Outreach** sheet
2. The table currently ends at column **O** (`Notes`)
3. Click cell **P1** and type exactly: `Subject`
4. Press Enter — Excel normally auto-extends the table to include it

**Verify it joined the table:** click any cell inside the table → the Table Design tab
should show the range now covering column P. If `Subject` sits *outside* the table,
select the table → **Table Design → Resize Table** → extend the range to include P.

Suggested position: leave it at the end (P). Column order does not matter — the
workflow maps by header name, not position.

## 2. Add `Last Outreach Date` column to the Opportunities sheet

1. Same workbook → **Opportunities** sheet
2. The table currently ends at column **V** (`Evidence Summary`)
3. Click cell **W1** and type exactly: `Last Outreach Date`
4. Press Enter, and confirm the table extended (as above)

Format the column as **Date** (or leave General — the workflow writes `YYYY-MM-DD`).

> Until these two columns exist, the workflow still runs — Excel auto-map simply ignores
> keys with no matching header. `Subject` and `Last Outreach Date` are written but land
> nowhere. Nothing breaks; the data is just dropped. They start working the moment the
> headers exist.

## 3. Add the Microsoft Outlook credential in n8n

1. In n8n, open the left sidebar → **Credentials**
2. Click **Add credential** (top right)
3. Search for and select **Microsoft Outlook OAuth2 API**
4. Click **Connect my account** / **Sign in with Microsoft**
5. Sign in with the Grandeur Microsoft account that should *send* the outreach
   (the same account as the Excel credential is fine)
6. Approve the requested permissions — sending mail requires `Mail.Send`
7. Name it something recognisable, e.g. **`Microsoft Outlook account`**
8. **Save**

**Verify:** the credential should show a green "Connected" state. Then tell Claude —
the sender node binds to it by ID.

### If the OAuth flow fails

- **Redirect URI mismatch** → copy the OAuth Redirect URL shown at the top of the n8n
  credential screen and add it to the Azure app registration's redirect URIs.
- **Admin consent required** → a Microsoft 365 tenant admin must approve `Mail.Send`
  for the app. Common on business tenants.
- n8n Cloud usually provides a pre-registered app, so steps 3–6 are often all that is
  needed.


### ⚠️ "Needs permission to access resources in your organization that only an admin can grant"

This is an Entra (Azure AD) tenant restriction: your organization blocks users from
consenting to third-party apps. An admin must approve n8n once, tenant-wide.

**Option 1 — Admin signs in and consents (easiest)**

A Global Administrator (or Cloud Application Administrator / Privileged Role
Administrator) performs the n8n connect flow themselves:

1. n8n → Credentials → Microsoft Outlook OAuth2 API → **Connect my account**
2. Sign in **as the admin**
3. Tick **"Consent on behalf of your organization"** on the consent screen
4. **Accept**

That checkbox is the entire fix. Afterwards any user in the tenant can connect.

**Option 2 — Entra admin center**

1. https://entra.microsoft.com → sign in as Global Admin
2. **Identity → Applications → Enterprise applications**
3. Search **n8n** → open it
4. **Security → Permissions → Grant admin consent for \<org\>**

If n8n is not listed, it has never been consented and the service principal does not
exist yet — use Option 1 or 3.

**Option 3 — Direct admin-consent URL**

```
https://login.microsoftonline.com/<tenant-id>/adminconsent?client_id=<app-id>
```

The `client_id` is present in the failed sign-in URL / error message. The admin opens
this link and approves once.

**Recommended:** Entra → Enterprise applications → **Admin consent requests** → enable
the request workflow, so future blocks file an approvable request instead of a dead end.

---

## 4. Sending from a different email address

Verified against `n8n-nodes-base.microsoftOutlook` v2 (`message:send`). The node supports
three auth types — `microsoftOutlookOAuth2Api`, `microsoftOAuth2Api`,
`microsoftEntraServicePrincipalApi` — and exposes `additionalFields.from`
("The owner of the mailbox from which the message is sent. Must correspond to the actual
mailbox used") plus `replyTo`.

### Route 1 — Delegated + Send As (recommended)

`from` is enforced by Microsoft: real permission on that mailbox is required.

1. https://admin.exchange.microsoft.com → **Recipients → Mailboxes**
2. Select the mailbox to send *from* (e.g. a shared `bd@grandeuradvisory.com`)
3. **Delegation → Send as → Add** → add the account n8n authenticates as
4. Set `from` to that address in the send node

**Simplest variant:** create the n8n credential while signed in **as the account you want
to send from**. One credential = one mailbox, no delegation required.

### Route 2 — App-only (Entra Service Principal)

With `microsoftEntraServicePrincipalApi`, the node exposes a **`mailbox`** resource
locator that can target a different mailbox **per input item**. Requires an app
registration with **`Mail.Send` application permission**.

⚠️ By default this permits sending as **any mailbox in the tenant**. Scope it with an
`ApplicationAccessPolicy` in Exchange Online PowerShell restricting the app to specific
mailboxes. Overkill until outreach genuinely sends from many addresses.

---

## Current status

| Task | Status |
|---|---|
| `Company Key` column on Companies | ✅ done |
| `Subject` column on Outreach | ✅ done |
| `Last Outreach Date` on Opportunities | ✅ done |
| Microsoft Outlook credential | ✅ done (`NmkBgylCa1gGZEob`) |
| Send As on accounting@grandeuradvisory.com | ✅ done |
| Sender timezone + send window | ✅ pinned `Asia/Kolkata`, 15:00–02:00 IST Mon–Fri |
| **Activate the Outreach Sender workflow** | ⬜ owner decision — starts real sending |

---

## 5. Hunter API credential (contact enrichment)

**Why:** every run so far has been blocked by the same single reason —
*"No contactable decision maker with a verified email"*. Contact discovery finds the
right people and titles; it cannot reliably find published email addresses. Hunter closes
that gap and is the only thing standing between a scored opportunity and a sendable draft.

**Why Hunter specifically:** it has a native n8n node (Apollo does not), and its
operations map exactly onto the gap — `emailFinder` turns a name plus domain into an
address, and returns a confidence score, so an address is *evidence* rather than a guess.

### Steps

1. Sign up at **https://hunter.io** (free tier ≈ 25 searches/month — enough to validate)
2. Go to **Dashboard → API** and copy your **API key**
3. In n8n: **Credentials → Add credential → Hunter API**
4. Paste the key, name it **`Hunter account`**, **Save**
5. Open **Grandeur BD Agent V1** → node **`Hunter Find Email`** → select that credential

Tell Claude once it exists and the credential can be bound programmatically instead.

### How it behaves (agreed with owner)

| Outcome | Result |
|---|---|
| Hunter finds an address, confidence **≥ 90** | written with `Email Verification Status = Verified` |
| Hunter finds an address, confidence **< 90** | **still written**, flagged `Unverified` — reaches you as a draft to approve |
| Hunter finds nothing | `Email` left blank, contact stays un-emailable |
| Research already found a verified email | Hunter result **ignored**, the verified one wins |

The confidence threshold (`VERIFIED_SCORE = 90`) is a single constant at the top of
`Apply Enrichment`.

Every enriched contact gets a `Notes` entry recording the source and confidence, e.g.
*"Email found via Hunter (confidence 94)"* — so provenance is never lost.

### Credit note

One Hunter credit per contact per run. Contact discovery returns up to 3 people per
company, so budget roughly 1-3 credits per company. A separate `emailVerifier` step can
be added later for true deliverability checking at the cost of a second credit per
address.

## Current status

| Task | Status |
|---|---|
| `Company Key` column on Companies | ✅ done |
| `Subject` column on Outreach | ✅ done |
| `Last Outreach Date` on Opportunities | ✅ done |
| Microsoft Outlook credential | ✅ done (`NmkBgylCa1gGZEob`) |
| Send As on accounting@grandeuradvisory.com | ✅ done |
| Hunter API credential | ✅ done (`RVNuMRGVdJhoNhT2`) |
| A target-market prospect to test with | ✅ done — Aescape scored 82, draft is in Outreach |
| Sender timezone | ✅ pinned to `Asia/Kolkata` on the workflow itself |
| Send window 15:00–02:00 IST, Mon–Fri | ✅ enforced in the cron **and** in `Build Send Queue` |
| Approve the Aescape draft | ✅ approved and **sent** to Nick Nelson 2026-08-26 |
| Remote-only rule | ✅ research reports work arrangement, eligibility gate blocks non-remote |
| One email per 10 minutes | ✅ poll every 10 min, one send per run |
| **Activate the Outreach Sender workflow** | ✅ **LIVE — approvals now auto-send** |

---

## 6. Phase 2 setup — replies, follow-ups and instant approval

Four tasks. They are independent, so they can be done in any order, but nothing in
Phase 2 works until (a) is done.

### (a) Add three columns to the `Outreach` table  ← blocks everything below

Open the **Outreach** sheet. Click any cell **inside** `Table6`, then add these three
column headers in the first empty columns **of the table** (not to the right of it — a
header typed outside the table boundary is invisible to the Excel API, which is what
made rows vanish once already):

| Column | Holds | Why |
|---|---|---|
| `Sequence Step` | `0`, `1`, `2`, `3` | 0 is the first email; 1–3 are the follow-ups. Caps the sequence at 3. |
| `Sent Message ID` | Graph message id | Needed to reply **on the same thread** rather than starting a new one. |
| `Conversation ID` | Graph conversation id | Ties a reply back to the outreach that caused it. |

Leave them blank. The workflows populate them.

### (b) Create a `Responses` sheet

New worksheet named exactly **`Responses`**. Put these headers in row 1, select them,
and press **Ctrl+T** (My table has headers ✓) so it becomes a real table:

```
Response ID | Outreach ID | Company ID | Contact ID | Received Date |
From Email | From Name | Subject | Body | Intent | Conversation ID | Notes
```

`Intent` is filled by classification — *Interested*, *Not Interested*, *Referred*,
*Out of Office*, *Unsubscribe*, *Other*. Auto-replies must be classified before they can
be allowed to stop a sequence, otherwise a holiday responder silently kills a live lead.

### (c) ~~Grant `Mail.Read`~~ — NOT NEEDED, already works

Tested on 2026-08-28 rather than assumed. The existing Outlook credential already reads the
mailbox: a probe returned 3 messages, each carrying both `conversationId` and message `id`,
which is exactly what reply matching needs.

n8n's `microsoftOutlookOAuth2Api` credential requests `Mail.ReadWrite`, and read is a subset
of that, so no additional Entra consent is required. **Worth generalising: test the
capability before requesting an admin permission — the scope may already be granted.**

### (d) Build the Power Automate flow (instant approval)

Excel cannot push changes to n8n, so a watcher has to sit in Microsoft's side. Steps:

1. **make.powerautomate.com** → Create → **Automated cloud flow**
2. Trigger: **When a row is modified** (Excel Online Business)
3. Location / Document Library / File: the `Grandeur_BD_Agent_V1` workbook · Table: `Table6`
4. Add a **Condition**: `Approval Status` **is equal to** `Approved`
5. On the *If yes* branch: **HTTP** action → **POST** → the n8n webhook URL (supplied once
   the webhook node is built) → Body: `{ "outreachId": <Outreach ID from the trigger> }`
6. Save.

Approving a row then fires the send within seconds instead of waiting for the next poll.
The 10-minute spacing rule and the 15:00–02:00 IST window still apply — approval releases
the email into the queue, it does not bypass the guards.

### (e) Apollo.io API key (contact enrichment)

Sign up at apollo.io, then **Settings → Integrations → API** → create a key. Paste it into
n8n as a **Header Auth** credential (`X-Api-Key`). This is the second enrichment stage
after Hunter, and it returns `linkedin_url` on people records — which is what removes the
manual LinkedIn hunting.

