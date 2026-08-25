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

---

## Current status

| Task | Status |
|---|---|
| `Company Key` column on Companies | ✅ done |
| `Subject` column on Outreach | ⬜ pending |
| `Last Outreach Date` on Opportunities | ⬜ pending |
| Microsoft Outlook credential | ⬜ pending |
