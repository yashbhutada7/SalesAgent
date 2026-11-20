# Grandeur BD Agent — Complete Setup & Handover File

**Snapshot date:** 20 November 2026 (IST)
**Owner:** Yash Bhutada, Grandeur Advisors LLP
**Purpose of this file:** One self-contained file that lets any new device, new Claude session or new n8n account understand, restore and continue the Grandeur AI Business Development Agent exactly where it was left.

---

## 0. Instructions for the AI assistant receiving this file

You are picking up a live project. Read this whole file before acting.

1. **Do not send any email, publish any workflow or delete any data without the owner's explicit OK.** Human approval before outbound communication is a standing rule.
2. First check what already exists. Connect to n8n (Section 2) and list the workflows and credentials. If the five workflows in Section 5 already exist with the same IDs, **nothing needs importing**: continue from Section 9 (status) and Section 10 (next steps).
3. Only if this is a **new / empty n8n account**, follow Section 11 (restore procedure), using the workflow exports in the Appendix.
4. Secrets are **not** in this file. The owner re-enters them in the n8n UI (Section 3). Never ask the owner to paste keys into chat.
5. Never invent data. The agent's core rule is that every company, signal, contact and email must be real and verifiable.

---

## 1. What this system is

An AI agent, built in **n8n**, that works as a virtual Business Development Manager for **Grandeur Advisors LLP** (outsourced accounting, bookkeeping, month-end close, financial reporting, AP/AR, fractional CFO, NetSuite/ERP and multi-entity accounting support).

It does five jobs:

1. **Prospect Discovery**: finds real companies with a recent finance signal (finance hiring, ERP migration, acquisition, expansion, funding).
2. **Research & qualification**: researches each company, scores the opportunity, finds the finance decision-maker, gets a verified email (Findymail), and writes a personalised email **draft**.
3. **Sending**: sends only drafts the owner has marked **Approved**, one at a time, inside a set time window.
4. **Follow-ups**: up to 3 polite follow-ups in the same email thread, stopping as soon as the prospect replies.
5. **Reply detection**: reads the inbox, logs replies with an intent label (Interested / Not Interested / Opt Out / Out of Office / Bounce / Needs Review), and stops all automated mail to that company.

**Target markets (hard-coded allow-list):** USA, UK, Ireland, Canada, Australia, New Zealand, Germany, Netherlands, Belgium, Switzerland, France, Sweden, Denmark, Norway, Spain, Italy, Singapore, Hong Kong, Japan, South Korea, UAE, Saudi Arabia, Qatar. Companies outside these are dropped automatically.

**Ideal customer:** 50–500 employees, with a recent, verifiable finance signal. Accounting firms, BPOs/outsourcers, consultancies and recruitment agencies are excluded (they are competitors or brokers, not buyers).

---

## 2. Accounts & services used

| Service | What it is used for | Account / location |
|---|---|---|
| **n8n Cloud** | Runs all workflows | `https://bhutadayash7.app.n8n.cloud` (personal project "Yash Bhutada") |
| **Microsoft 365 – Excel** | The database (one workbook) | OneDrive of **accounting@grandeuradvisory.com**, folder **Grandeur BD Agent** |
| **Microsoft 365 – Outlook** | Sending and reading email | Sends **from info@grandeuradvisory.com** (delegated Send-As); replies land in info@ |
| **OpenAI API** | All AI steps (model `chat-latest`, with built-in web search) | platform.openai.com: needs a valid key **and credit balance** |
| **Findymail API** | Verified email lookup (LinkedIn URL first, then name + domain) | findymail.com: pay per successful lookup |
| ~~Hunter.io~~ | **Retired** (Sept 2026). Credential still exists but is unused. | Can be cancelled |
| **GitHub** | Project documentation | Repo `yashbhutada7/SalesAgent` (folder `docs/`) |

Email authentication on `grandeuradvisory.com` was checked in Sept 2026: SPF and DKIM pass via Microsoft 365; DMARC policy is `p=none` (monitor). Optional future hardening: `p=quarantine`, then `p=reject`.

---

## 3. Credentials (n8n) — names only, no secrets

| n8n credential name | Type | Current ID | Used by | How to (re)create |
|---|---|---|---|---|
| **OpenAI account** | OpenAI API | `Iny8RznkWYiFgD9G` | Discovery AI, Company Research AI, Opportunity Research, Contact Research AI, Outreach Draft AI | n8n → Credentials → Create → OpenAI → paste API key → Save |
| **Microsoft Excel account** | Microsoft Excel OAuth2 | `t05ZuN05jLPuMapG` | Every Excel read/write | Create → Microsoft Excel → **Sign in as accounting@grandeuradvisory.com** |
| **Microsoft Outlook account** | Microsoft Outlook OAuth2 | `NmkBgylCa1gGZEob` | Sender, Follow-Ups, Reply Detection | Create → Microsoft Outlook → sign in with an account that has **Send As** rights on info@ |
| Hunter account | Hunter API | `RVNuMRGVdJhoNhT2` | Nothing (retired) | Not needed |
| Header Auth account | HTTP Header Auth | `pjAb9Kxt6by4EeiC` | Nothing currently | Not needed |

**Findymail key:** is **not** stored as an n8n credential. It is written inside the code node **"Findymail Enrich"** in the main workflow (also in the "Findymail Backfill" helper workflow), as `Authorization: Bearer <key>`. In the Appendix export it is replaced with `<<FINDYMAIL_API_KEY>>`. After importing, open that node and paste the real key. (Improvement for later: move it into a Header Auth credential.)

**If credential IDs change** (new n8n account), every node must be re-pointed to the new credential: open each workflow and re-select the credential on each red node, or ask the assistant to do it.

---

## 4. The Excel workbook (the database)

| Item | Value |
|---|---|
| File | `Grandeur_BD_Agent_V1.xlsx` |
| Location | accounting@ OneDrive → **Grandeur BD Agent** folder |
| Drive item ID | `01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6` |
| Backup taken 20-Nov-2026 | `Grandeur_BD_Agent_V1_backup_2026-11-20.xlsx` (same folder; contains all data before the reset) |

⚠️ A **different** file with the same name exists in info@'s OneDrive under *01. Internal/Sales & Marketing/Leads*. The agent does **not** use that one.

### Tabs and Excel tables

| Tab | Excel table | Purpose | Key column |
|---|---|---|---|
| Companies | `tblCompanies` | One row per company | `Company Key` (normalised domain) → `Company ID` |
| Opportunities | `tblOpportunities` | One row per company + opportunity type, with score | `Opportunity ID` |
| Contacts | `tblContacts` | Decision-makers + verified emails | `Contact ID` |
| Signals | `tblSignals` | Dated evidence (hiring, ERP, etc.) | `Signal ID` |
| Outreach | `Table6` | Drafts, approvals, sends, follow-ups | `Outreach ID` |
| Responses | `tblResponses` | Logged replies + intent | `Response ID` |
| Suppression | `tblSuppression` | Do-not-contact (company or contact) | `Suppression ID` |
| Clients | `tblClients` | Existing clients (blocked from outreach) | — |
| Competitors | `tblCompetitors` | Reference list (not currently read by any workflow; competitors are excluded through the Discovery prompt) | — |
| Sources | `tblSources` | Source URLs / evidence | — |
| Learning | `tblLearning` | Outcome log for future tuning | — |
| Settings, Dashboard | — | Reference / summary | — |

### Companies columns (40)
Company Key, Company ID, Company Name, Legal Name, Website, Country, State/Region, City, Parent Company ID, Company Type, Industry, Ownership Type, Revenue, Revenue Type, Revenue Band, Employee Count, Employee Count Type, Employee Band, Finance Team Size, Finance Hiring Activity, Growth Information, ERP, Accounting Software, Technology Stack, Number of Entities, Countries Operated, Existing Outsourcing, Current Provider, Company Status, First Discovered, Last Researched, Last Signal Date, Next Research Date, Primary Source ID, Verification Status, Notes, ICP Fit, Priority, Reason, Missing Information.
(Since Sept 2026 research only fills 24 of these, to save cost. The rest stay blank by design.)

### Outreach columns used by the workflows
Outreach ID, Company ID, Opportunity ID, Contact ID, Channel, **Approval Status**, Draft Status, Subject, Draft/Message, Recommended Send Date, Recommended Send Window, Sent Date, Follow-Up Date, Follow-Up Plan, Outreach Status, Sequence Step, Sent Message ID, Conversation ID, Notes.

### Contacts columns used by the workflows
Contact ID, Company ID, Name, Job Title, Department, Seniority, Email, Email Verification Status, Phone, Phone Verification Status, LinkedIn URL, Primary Decision-Maker, Backup Decision-Maker, Contact Confidence, Source ID, Last Verified, **Do Not Contact** (Yes/blank), Notes.

---

## 5. Workflows

| # | Workflow | n8n ID | Schedule (IST) | What it does |
|---|---|---|---|---|
| 1 | **Grandeur BD Agent - Prospect Discovery** | `iEZAsjljfX0jXF83` | `0 3,9,17 * * *`: 03:00, 09:00, 17:00 daily | Rotates through 9 market groups and 2 signal types; up to 5 new companies per run; appends stubs to Companies (deduped on domain) |
| 2 | **Grandeur BD Agent V1** (main pipeline) | `jIghxNOFdVshn2d3` | `30 9-21 * * *`: hourly at :30, 09:30–21:30 (13 runs/day) | Picks **one** company per run → research → opportunity score → signal → contacts → Findymail → eligibility check → AI email draft (Pending Approval) |
| 3 | **Grandeur BD Agent - Outreach Sender** | `sEaRV2WFAshZ9uFu` | Every 10 min, 15:00–01:59, Mon–Fri evenings | Sends **one** Approved draft per run from info@, with HTML signature; stamps Sent Date and Conversation ID |
| 4 | **Grandeur BD - Follow-Up Sequencer** | `ie6wPd70DBL6IPD8` | Every 10 min, 17:00–21:59, Mon–Fri | One follow-up per run, threaded into the original conversation; 2 working days apart; max 3 |
| 5 | **Grandeur BD - Reply Detection** | `lAufPqbyL5XBBbEv` | Every 30 min, 24/7 | Reads the last 4 days of inbox; matches replies by conversation or sender; logs them to Responses; marks the company Replied |

Helper / diagnostic workflows (inactive, keep for reuse): `Findymail Backfill (name+domain)` `ofPqdJXsnhWxU6RB`, `Grandeur BD - Outreach Audit` `cW44D07WQvM1NMd5` (read-only), `Outreach Funnel Diagnostic` `zFXOLcSHA3Qjyfsm`.

### Main pipeline: node order (35 nodes)
`Scheduled Intake` → `Get Research Queue` (Companies) → `Pick Next Company` → `Normalize Domain` → **`Company Research AI`** (web search) → `Normalize Research Output` → `Get Existing Companies` → `Assign Company ID` → `Upsert Company` → **`Opportunity Research`** (web search) → `Map Opportunity Output` → `Get Existing Opportunities` → `Assign Opportunity ID` → `Upsert Opportunity` → **`Contact Research AI`** (web search) → `Get Existing Signals` → `Assign Signal ID` → `Upsert Signal` → `Get Existing Contacts` → `Assign Contact IDs` → `Has Email?` → (no email) **`Findymail Enrich`** → `Merge Contacts` → `Upsert Contact` → `Get Company Contacts` → `Get Outreach History` → `Get Suppression List` → `Get Clients` → `Check Outreach Eligibility` → `Eligible?` → **`Outreach Draft AI`** (no web search) → `Build Outreach Row` → `Append Outreach Draft`.
Plus a manual trigger and the `Test Company Input` fixture (BluePeak test company) kept for testing.

**AI calls per researched company:** up to 4 (Company Research, Opportunity Research, Contact Research, Outreach Draft), three of them with web search, plus Discovery 3×/day. All use model `chat-latest`; web-search context is "medium" in the main pipeline and **"high"** in Discovery.

---

## 6. Business rules built into the agent

**Data integrity**
- Never invent companies, websites, URLs, people, emails or facts; blank is better than guessed.
- Company ID = deterministic, minted only by research; dedup on **normalised domain** (`Company Key`).
- Opportunity ID = one per **company + opportunity type**; re-runs update rather than duplicate.
- Discovery appends stubs with a blank Company ID; research fills them in (single-writer rule).

**Research cadence**
- One company per hourly run. New (never-researched) companies first.
- Any company is re-researched at most every **14 days** (`MIN_DAYS_BETWEEN_RESEARCH = 14`).
- Skipped statuses: Excluded, Suppressed, Do Not Contact, Client, Closed, Disqualified.
- Research spends **zero** searches on revenue, employees, ERP, tech stack, outsourcing, etc. (cost cut, Sept 2026).

**Outreach eligibility (all must pass)**
- Opportunity score ≥ **50** (`MIN_SCORE`).
- Country verified and in the target allow-list.
- Role is not explicitly on-site/hybrid (Grandeur delivers remotely).
- Company not in Suppression and not an existing Client.
- A finance decision-maker exists (CFO, finance, controller, accounting, treasury, FP&A, bookkeeping) with a **verified** email, not marked Do Not Contact.
- Opportunity refreshed within the last **72 hours** (`FRESH_HOURS`).
- Company not emailed in the last **30 days** (`REENGAGE_DAYS`), and no draft already awaiting approval for it.
- Every blocked company gets a written `Ineligible Reason`.

**Approval & sending**
- Every AI email is saved as **"Pending Approval"**. **Nothing is sent until the owner changes Approval Status to "Approved"** in the Outreach tab.
- Send window: **15:00–02:00 IST, Monday–Friday evenings** (the 00:00–01:59 tail runs Tue–Sat).
- **One email per 10 minutes**, never in bursts (protects domain reputation).
- Sent from **info@grandeuradvisory.com**, HTML body with the owner's signature (logo, CEO & Founder, Website | LinkedIn | Instagram).

**Follow-ups**
- 2 working days after the last email; maximum 3 follow-ups; sent 17:00–21:59 IST weekdays.
- Always threaded into the **original** conversation (looked up live by Conversation ID).
- Stop immediately if the company replied, is suppressed, or the contact is Do Not Contact.

**Replies**
- Rule-based intent (no AI cost). A reply stops all automated mail for the **whole company**.

---

## 7. Known technical gotchas (learned the hard way)

- **Excel via Graph API is fragile:** 504/503 and "EditModeCannotAcquireLock" 429 errors happen. Every Excel node has retries (3–4×, 2–3 s).
- **The Outreach tab blocks row deletion** ("would move cells in a table"); something else on that sheet sits next to the table. Clear contents instead, or delete rows by hand in Excel (select rows → Delete → Table Rows).
- **n8n Code node limits on this instance:** 60 s per task, 300 s per workflow run; Discovery has a 180 s timeout.
- **Findymail limits:** LinkedIn endpoint 50/min; name+domain endpoint 300/min. Misses cost nothing.
- **n8n MCP editing:** never use `setNodeParameter` (it silently fails on arrays); use `updateNodeParameters` with the full value.
- Always use `$now` (Asia/Kolkata timezone), never `new Date()` for dates; the container clock is UTC.
- Excel turns "001" into 1, so ID comparisons normalise digits.
- Outlook draft IDs change after sending; follow-ups resolve the live message by **Conversation ID** instead.

---

## 8. Change log of 20 November 2026

1. **Health check:** Prospect Discovery and the main pipeline had failed on **every run since at least 13 Nov** with `401 – API key invalidated`. Sender, Follow-Ups and Reply Detection were healthy (one transient Excel 504 on 19 Nov).
2. **Backup created:** `Grandeur_BD_Agent_V1_backup_2026-11-20.xlsx`.
3. **Lead data cleared** (owner's request, headers kept): Companies (134 rows), Opportunities (133), Contacts (236), Signals (105), Outreach (69), Responses (3), Sources (1). Suppression, Clients, Competitors, Settings and Learning were left untouched (they were already empty).
   - Outreach still has **69 blank table rows** (contents cleared, rows could not be removed by the API). Optional tidy-up by hand.
4. **All 5 schedules found switched OFF** at 12:04 UTC (17:34 IST) via an AI/MCP connection to n8n that was **not** this session. They remain OFF.
5. **OpenAI key replaced** by the owner: n8n now accepts the new key. **OpenAI credit balance is zero**: runs fail with `429 – credit_balance_exhausted` until topped up.
6. **Tests passed with empty tabs:** Outreach Sender, Reply Detection and Follow-Up Sequencer all ran green and sent nothing (Excel + Outlook connections confirmed working).
7. Temporary helper workflows used for the backup/clear were archived.

---

## 9. Current status (end of 20 Nov 2026)

| Item | Status |
|---|---|
| OpenAI key | ✅ Valid |
| OpenAI credit | ❌ Zero (owner will top up after the rules review) |
| Findymail credit | ⚠️ Not checked since Sept, so check before go-live |
| Excel + Outlook connections | ✅ Working |
| Lead tabs | Empty (backup saved) |
| Do-not-email lists (Suppression / Clients / Competitors) | ⚠️ Empty |
| All 5 schedules | ⏸️ OFF |
| End-to-end test on a real company | ⏳ Pending (needs credit) |

---

## 10. Next steps (agreed plan)

**Step 1: Rules review to cut token cost** (planned for 21 Nov, before any top-up). Levers to discuss:
- Discovery web search "high" → "medium"; fewer runs or fewer results per run.
- Main pipeline: 13 runs/day; consider fewer hours or skipping companies that fail early checks.
- **Stop the 14-day re-research loop** for companies already judged Low/Unknown or with no findable contact (currently every company is re-researched forever).
- Run the cheap checks (country, suppression, client) **before** the expensive AI research; today most of them run only at the end, after all AI calls are spent.
- Note: the 72-hour freshness rule means a company only gets a draft in the same run it was researched.
- Merge or slim prompts (Company Research, Opportunity Research, Contact Research); use a cheaper model for formatting-only steps (e.g. the email draft).
- Only run Contact Research / Findymail when the opportunity score is ≥ 50.

**Step 2:** Top up OpenAI (consider auto-recharge) and Findymail.

**Step 3:** Add existing clients to **Clients** and any "not interested" / opt-out contacts to **Suppression** (the old Outreach/Responses data is in the backup file).

**Step 4:** Manual end-to-end test: Discovery → one company through the full pipeline → check the draft in Outreach.

**Step 5:** With the owner's OK, switch the five schedules back on (publish each workflow in n8n).

**Step 6:** Find out what switched the schedules off on 20 Nov (another Claude session or automation with n8n access) so it doesn't happen again.

---

## 11. Restore procedure (new device / new n8n account)

**A. Same n8n account (most likely):** nothing to restore. Open n8n, confirm the five workflows exist, then continue from Section 10.

**B. New/empty n8n account:**
1. Create credentials (Section 3): OpenAI, Microsoft Excel (accounting@), Microsoft Outlook (Send-As on info@).
2. For each workflow in the Appendix: n8n → **Create Workflow → ⋯ menu → Import from File/URL** (or paste the JSON onto the canvas). Import order: Discovery, Main, Sender, Follow-Up, Reply Detection.
3. On every node showing a red credential warning, select the new credential.
4. In **Findymail Enrich** (main workflow), replace `<<FINDYMAIL_API_KEY>>` with the real key.
5. If the Excel workbook has moved or been re-created, re-select the workbook / sheet / table in every Excel node (the IDs in the exports point to the current file).
6. Run each workflow once manually to test; publish only with the owner's OK.

**C. New Claude session / assistant:** give it this file, connect it to the n8n instance (n8n MCP) and Microsoft 365, and ask it to start at Section 0.

---

## Appendix: Full workflow exports (n8n JSON)

Exported 20 Nov 2026 from the live instance. Secrets are removed (`<<FINDYMAIL_API_KEY>>`). Each block is a complete, importable n8n workflow (`name`, `nodes`, `connections`, `settings`).

### A1. Grandeur BD Agent - Prospect Discovery (`iEZAsjljfX0jXF83`)

```json
{
 "name": "Grandeur BD Agent - Prospect Discovery",
 "nodes": [
  {
   "id": "dff86d6f-c8ff-46dc-bdb7-141c4030df94",
   "name": "Run Discovery",
   "type": "n8n-nodes-base.manualTrigger",
   "typeVersion": 1,
   "position": [
    0,
    0
   ],
   "parameters": {}
  },
  {
   "id": "f5b7ee75-bf08-46c4-9284-9e801ccac361",
   "name": "Prospect Discovery AI",
   "type": "@n8n/n8n-nodes-langchain.openAi",
   "typeVersion": 2.3,
   "position": [
    480,
    0
   ],
   "parameters": {
    "builtInTools": {
     "webSearch": {
      "searchContextSize": "high"
     }
    },
    "modelId": {
     "__rl": true,
     "cachedResultName": "CHAT-LATEST",
     "mode": "list",
     "value": "chat-latest"
    },
    "options": {
     "textFormat": {
      "textOptions": {
       "type": "text"
      }
     }
    },
    "responses": {
     "values": [
      {
       "content": "=You are a B2B prospect researcher for Grandeur Advisory LLP, an outsourced finance and accounting firm.\n\nUse Web Search to find REAL companies that are plausible BUYERS of outsourced accounting services.\n\nGRANDEUR SELLS: outsourced accounting, bookkeeping, month-end close, financial reporting, management reporting, AP/AR, fractional CFO, interim finance support, NetSuite/ERP accounting support, multi-entity accounting.\n\nSEARCH BRIEF:\n\nEngine: {{ $json.engine }}\nTarget countries: {{ $json.countries }}\nCompany size: {{ $json.employee_range }}\nSignal recency: within the last {{ $json.lookback_days }} days\nNumber of companies to return: {{ $json.max_results }}\n\nWHAT MAKES A GOOD CANDIDATE:\n\n- Headquartered in one of the target countries listed above\n- Roughly the stated employee size: large enough to have real finance complexity, small enough to outsource\n- Shows a RECENT, VERIFIABLE finance signal, such as:\n  - hiring a Controller, Finance Manager, Accounting Manager, CFO or Finance Director\n  - an announced ERP or accounting-system migration or implementation\n  - an acquisition creating multi-entity accounting complexity\n  - international expansion creating new reporting obligations\n  - rapid growth or funding followed by finance-team building\n\nHARD EXCLUSIONS. Do NOT return:\n\n- accounting firms, CPA firms, bookkeeping firms, audit firms\n- outsourcing providers, BPO or offshore staffing companies\n- management consultancies or advisory firms\n- recruitment agencies, staffing firms or talent companies\n- companies whose finance job postings are recruitment listings placed on behalf of clients rather than their own hiring\n- any company headquartered outside the listed target countries\n\nThose sell or broker the same services Grandeur does, or are out of market. They are not buyers.\n\nABSOLUTE RULES:\n\n- Return only companies you have actually found in search results. Never invent a company.\n- Never invent a website. The website must be the company's real domain.\n- Never invent a source URL. Every signal must have a real URL you actually saw.\n- If the signal is a job posting, the URL must be that posting or the company's careers page.\n- If you cannot find the required number of qualifying companies, return fewer. Returning 2 solid candidates is far better than 5 with 3 invented.\n- If you can verify nothing, return an empty array.\n\nRETURN ONLY THIS JSON OBJECT:\n\n{\n  \"candidates\": [\n    {\n      \"company_name\": \"\",\n      \"website\": \"\",\n      \"country\": \"\",\n      \"industry\": \"\",\n      \"approx_employees\": \"\",\n      \"signal_type\": \"\",\n      \"signal_description\": \"\",\n      \"signal_url\": \"\",\n      \"signal_date\": \"\",\n      \"why_grandeur_fits\": \"\",\n      \"confidence\": \"\"\n    }\n  ]\n}\n\nFIELD RULES:\n\ncompany_name: the real trading name.\nwebsite: real company domain, including https://.\ncountry: must be one of the target countries.\nindustry: what the company actually does.\napprox_employees: only if found; otherwise \"\".\nsignal_type: e.g. \"Controller hiring\", \"ERP migration\", \"Acquisition\", \"International expansion\".\nsignal_description: one or two factual sentences describing what you found.\nsignal_url: the real URL where you saw it.\nsignal_date: YYYY-MM-DD if known, otherwise \"\".\nwhy_grandeur_fits: one sentence connecting the signal to a specific Grandeur service. Do not overstate.\nconfidence: exactly one of \"High\", \"Medium\", \"Low\".\n\nReturn ONLY the JSON. No markdown, no code fences, no commentary."
      }
     ]
    }
   },
   "credentials": {
    "openAiApi": {
     "id": "Iny8RznkWYiFgD9G",
     "name": "OpenAI account"
    }
   }
  },
  {
   "id": "094f6280-0965-4e80-bee7-0bcb8afbaae4",
   "name": "Parse Candidates",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    720,
    0
   ],
   "parameters": {
    "jsCode": "const norm = (v) => (v == null ? '' : String(v)).trim();\n\nlet text = '';\ntry {\n  text = $input.first().json.output[0].content[0].text;\n} catch (e) {\n  text = '';\n}\n\nlet parsed;\ntry {\n  parsed = JSON.parse(text);\n} catch (e) {\n  parsed = {};\n}\n\nconst list = Array.isArray(parsed) ? parsed : (parsed.candidates || []);\nconst out = [];\n\nfor (const c of list) {\n  const name = norm(c.company_name);\n  const site = norm(c.website);\n  if (!name || !site) continue;\n\n  out.push({ json: {\n    'Company Name': name,\n    'Website': site,\n    'Country': norm(c.country),\n    'Industry': norm(c.industry),\n    'Approx Employees': norm(c.approx_employees),\n    'Signal Type': norm(c.signal_type),\n    'Signal Description': norm(c.signal_description),\n    'Signal URL': norm(c.signal_url),\n    'Signal Date': norm(c.signal_date),\n    'Why Grandeur Fits': norm(c.why_grandeur_fits),\n    'Confidence': norm(c.confidence)\n  }});\n}\n\nreturn out;",
    "language": "javaScript",
    "mode": "runOnceForAllItems"
   }
  },
  {
   "id": "9c7bef3a-6b12-4312-be08-60d887dff2ab",
   "name": "Discovery Schedule",
   "type": "n8n-nodes-base.scheduleTrigger",
   "typeVersion": 1.3,
   "position": [
    0,
    240
   ],
   "parameters": {
    "rule": {
     "interval": [
      {
       "field": "cronExpression",
       "expression": "0 3,9,17 * * *"
      }
     ]
    }
   }
  },
  {
   "id": "de677e78-55f3-4cdc-a49e-30919aab5f9e",
   "name": "Get Existing Companies",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    960,
    0
   ],
   "parameters": {
    "resource": "table",
    "operation": "getRows",
    "returnAll": true,
    "rawData": false,
    "filters": {},
    "workbook": {
     "__rl": true,
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6",
     "cachedResultName": "Grandeur_BD_Agent_V1"
    },
    "worksheet": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-0001-0000-0100-000000000000}",
     "cachedResultName": "Companies"
    },
    "table": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF00000000}",
     "cachedResultName": "tblCompanies"
    }
   },
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "549c2e60-f80d-44f5-b40a-d131c7ec3648",
   "name": "Filter New Companies",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    1200,
    0
   ],
   "parameters": {
    "mode": "runOnceForAllItems",
    "language": "javaScript",
    "jsCode": "// Appends newly discovered companies into tblCompanies as STUBS. This is the\n// link that makes the pipeline self-feeding: the research scheduler picks up any\n// row whose Last Researched is blank, so a row appended here is researched on\n// the next intake tick.\n//\n// Company ID is deliberately left BLANK. Research is the single authority that\n// mints IDs, and Upsert Company matches on Company Key (the domain), so research\n// fills this row in rather than creating a second one.\n//\n// That single-writer rule is what makes this node safe. The earlier design had\n// discovery deriving the next ID by reading the table and incrementing, and on\n// 2026-08-27 a read came back with every field blank: maxId computed to 0 and\n// five companies were written as Grand 001-005 on top of live rows. Two attempts\n// to guard that read by counting blank rows both failed, because an emptied\n// Excel table and a failed read produce the same shape - Excel always keeps one\n// blank row, and this node returns one blank row per input item. Not depending\n// on the read at all is the fix. The worst a bad read can now do is let a\n// duplicate through, which dedupe catches on the following run.\n\nconst COUNTRY_ALIASES = {\n  'usa': 'USA', 'us': 'USA', 'u.s.': 'USA', 'u.s.a.': 'USA',\n  'united states': 'USA', 'united states of america': 'USA', 'america': 'USA',\n  'uk': 'UK', 'gb': 'UK', 'united kingdom': 'UK', 'great britain': 'UK',\n  'england': 'UK', 'scotland': 'UK', 'wales': 'UK', 'northern ireland': 'UK',\n  'australia': 'Australia',\n  'germany': 'Germany', 'deutschland': 'Germany',\n  'canada': 'Canada',\n  'singapore': 'Singapore',\n  'uae': 'UAE', 'u.a.e.': 'UAE', 'united arab emirates': 'UAE',\n  'dubai': 'UAE', 'abu dhabi': 'UAE',\n  'netherlands': 'Netherlands', 'the netherlands': 'Netherlands', 'holland': 'Netherlands',\n  'ireland': 'Ireland', 'republic of ireland': 'Ireland',\n  'new zealand': 'New Zealand', 'nz': 'New Zealand',\n  'france': 'France',\n  'switzerland': 'Switzerland',\n  'belgium': 'Belgium',\n  'sweden': 'Sweden',\n  'denmark': 'Denmark',\n  'norway': 'Norway',\n  'spain': 'Spain',\n  'italy': 'Italy',\n  'hong kong': 'Hong Kong', 'hongkong': 'Hong Kong', 'hk': 'Hong Kong',\n  'japan': 'Japan',\n  'south korea': 'South Korea', 'korea': 'South Korea',\n  'republic of korea': 'South Korea',\n  'saudi arabia': 'Saudi Arabia', 'ksa': 'Saudi Arabia',\n  'qatar': 'Qatar'\n};\n\nconst norm = (v) => (v == null ? '' : String(v)).trim();\nconst lower = (v) => norm(v).toLowerCase();\n\nconst normalizeDomain = (w) => {\n  let s = lower(w);\n  s = s.replace(/^https?:\\/\\//, '');\n  s = s.replace(/^www\\./, '');\n  s = s.split('/')[0].split('?')[0].split('#')[0];\n  return s.trim();\n};\n\n// Dedupe on DOMAIN, not name. 'LHH' and 'LHH Recruitment Solutions' are the same\n// company; the domain is the only stable key, and it is what Assign Company ID\n// and Upsert Company both match on.\nconst known = {};\nfor (const r of $input.all().map(i => i.json)) {\n  if (!r) continue;\n  const k = normalizeDomain(r['Company Key'] || r['Website']);\n  if (k) known[k] = true;\n}\n\n// $now is Luxon in the workflow timezone, pinned to Asia/Kolkata. The container\n// clock is UTC and would stamp the previous day after 18:30 IST.\nconst today = $now.toFormat('yyyy-LL-dd');\n\nconst out = [];\nconst seenThisRun = {};\n\nfor (const c of $('Parse Candidates').all().map(i => i.json)) {\n  const key = normalizeDomain(c['Website']);\n  if (!key) continue;\n  if (known[key] || seenThisRun[key]) continue;\n\n  // Defence in depth: the prompt names the target countries, but a model can\n  // drift. An out-of-market company must never reach the Companies table.\n  const country = COUNTRY_ALIASES[lower(c['Country'])] || '';\n  if (!country) continue;\n\n  seenThisRun[key] = true;\n\n  const noteParts = [];\n  if (norm(c['Signal Type'])) noteParts.push('Signal: ' + norm(c['Signal Type']));\n  if (norm(c['Signal Description'])) noteParts.push(norm(c['Signal Description']));\n  if (norm(c['Signal URL'])) noteParts.push('Source: ' + norm(c['Signal URL']));\n  if (norm(c['Signal Date'])) noteParts.push('Signal date: ' + norm(c['Signal Date']));\n  if (norm(c['Why Grandeur Fits'])) noteParts.push('Fit: ' + norm(c['Why Grandeur Fits']));\n  if (norm(c['Confidence'])) noteParts.push('Discovery confidence: ' + norm(c['Confidence']));\n\n  out.push({ json: {\n    'Company Key': key,\n    // Blank on purpose - research mints the ID and upserts on Company Key.\n    'Company ID': '',\n    'Company Name': norm(c['Company Name']),\n    'Legal Name': '',\n    'Website': norm(c['Website']),\n    'Country': country,\n    'State/Region': '',\n    'City': '',\n    'Parent Company ID': '',\n    'Company Type': '',\n    'Industry': norm(c['Industry']),\n    'Ownership Type': '',\n    'Revenue': '',\n    'Revenue Type': '',\n    'Revenue Band': '',\n    'Employee Count': norm(c['Approx Employees']),\n    'Employee Count Type': norm(c['Approx Employees']) ? 'Discovery estimate' : '',\n    'Employee Band': '',\n    'Finance Team Size': '',\n    'Finance Hiring Activity': '',\n    'Growth Information': '',\n    'ERP': '',\n    'Accounting Software': '',\n    'Technology Stack': '',\n    'Number of Entities': '',\n    'Countries Operated': '',\n    'Existing Outsourcing': '',\n    'Current Provider': '',\n    'Company Status': 'New',\n    'First Discovered': today,\n    // Deliberately blank. A blank Last Researched is exactly what Pick Next\n    // Company treats as never-researched, which puts this row at the front of\n    // the research queue on the next tick. Filling it here would strand the row.\n    'Last Researched': '',\n    'Last Signal Date': norm(c['Signal Date']),\n    'Next Research Date': '',\n    'Primary Source ID': '',\n    'Verification Status': 'Unverified',\n    'Notes': noteParts.join(' | '),\n    'ICP Fit': '',\n    'Priority': '',\n    'Reason': '',\n    'Missing Information': 'Awaiting full company research'\n  } });\n}\n\n// No new companies is the normal case once a market is covered. Zero items stops\n// the run before the append node.\nreturn out;"
   }
  },
  {
   "id": "f2430738-53ca-4b0b-a880-f17a32e4df13",
   "name": "Append New Companies",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1440,
    0
   ],
   "parameters": {
    "resource": "table",
    "operation": "append",
    "dataMode": "autoMap",
    "workbook": {
     "__rl": true,
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6",
     "cachedResultName": "Grandeur_BD_Agent_V1"
    },
    "worksheet": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-0001-0000-0100-000000000000}",
     "cachedResultName": "Companies"
    },
    "table": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF00000000}",
     "cachedResultName": "tblCompanies"
    },
    "options": {}
   },
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "a279ec31-2780-4eb0-82a1-660887b402f7",
   "name": "Discovery Criteria",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    240,
    120
   ],
   "parameters": {
    "mode": "runOnceForAllItems",
    "language": "javaScript",
    "jsCode": "// Rotates a FOCUSED market per run instead of searching all 23 target countries\n// at once.\n//\n// Measured, not assumed: a 4-country brief completed in 74 seconds and returned\n// 5 real candidates. Widening the same prompt to all 23 countries produced\n// either an empty array in 2.5 seconds with 9 output tokens - the model did not\n// search at all - or a run still going past 7 minutes, against an instance\n// execution ceiling of 180 seconds. A broad brief gives the model no place to\n// start, so it either gives up or wanders until it is killed.\n//\n// Narrow briefs are also better BD. 'Companies in the USA hiring a Controller'\n// is a search. 'Companies in 23 countries with a finance signal' is a wish.\n\nconst GROUPS = [\n  { name: 'United States', countries: 'USA' },\n  { name: 'UK and Ireland', countries: 'United Kingdom, Ireland' },\n  { name: 'United States', countries: 'USA' },\n  { name: 'Canada, Australia and New Zealand', countries: 'Canada, Australia, New Zealand' },\n  { name: 'Western Europe', countries: 'Germany, Netherlands, Belgium, Switzerland, France' },\n  { name: 'United States', countries: 'USA' },\n  { name: 'Asia Pacific', countries: 'Singapore, Hong Kong, Japan, South Korea' },\n  { name: 'Gulf', countries: 'UAE, Saudi Arabia, Qatar' },\n  { name: 'Nordics and Southern Europe', countries: 'Sweden, Denmark, Norway, Spain, Italy' }\n];\n\n// Also rotate the signal being hunted, so three runs on the same day do not all\n// chase identical results.\nconst ENGINES = ['Hiring Signal', 'ERP Signal', 'Hiring Signal'];\n\n// $now is Luxon in the workflow timezone, pinned to Asia/Kolkata.\nconst SLOT_BY_HOUR = { 3: 0, 9: 1, 17: 2 };\nconst hour = $now.hour;\nconst slot = SLOT_BY_HOUR[hour] === undefined ? 0 : SLOT_BY_HOUR[hour];\n\n// Whole days since epoch, so the rotation advances once per calendar day and is\n// reproducible - the same slot on the same day always picks the same market.\nconst dayIndex = Math.floor($now.toSeconds() / 86400);\nconst groupIndex = ((dayIndex * 3) + slot) % GROUPS.length;\n\nconst group = GROUPS[groupIndex];\n\nreturn [{ json: {\n  'engine': ENGINES[slot],\n  'countries': group.countries,\n  'market_focus': group.name,\n  'employee_range': '50 to 500 employees',\n  'max_results': 5,\n  'lookback_days': 90,\n  'slot': slot,\n  'run_hour_ist': hour\n} }];"
   }
  }
 ],
 "connections": {
  "Prospect Discovery AI": {
   "main": [
    [
     {
      "node": "Parse Candidates",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Parse Candidates": {
   "main": [
    [
     {
      "node": "Get Existing Companies",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Get Existing Companies": {
   "main": [
    [
     {
      "node": "Filter New Companies",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Filter New Companies": {
   "main": [
    [
     {
      "node": "Append New Companies",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Run Discovery": {
   "main": [
    [
     {
      "node": "Discovery Criteria",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Discovery Schedule": {
   "main": [
    [
     {
      "node": "Discovery Criteria",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Discovery Criteria": {
   "main": [
    [
     {
      "node": "Prospect Discovery AI",
      "type": "main",
      "index": 0
     }
    ]
   ]
  }
 },
 "settings": {
  "executionOrder": "v1",
  "timezone": "Asia/Kolkata",
  "executionTimeout": 180
 },
 "meta": {
  "originalId": "iEZAsjljfX0jXF83",
  "exportedAt": "2026-11-20"
 }
}
```

### A2. Grandeur BD Agent V1 (`jIghxNOFdVshn2d3`)

```json
{
 "name": "Grandeur BD Agent V1",
 "nodes": [
  {
   "parameters": {},
   "type": "n8n-nodes-base.manualTrigger",
   "typeVersion": 1,
   "position": [
    0,
    0
   ],
   "id": "459a8fbc-64f2-49b6-9b13-3e1c2812f0f2",
   "name": "When clicking ‘Execute workflow’",
   "disabled": false
  },
  {
   "parameters": {
    "assignments": {
     "assignments": [
      {
       "id": "d50f95d7-d0a6-40bb-becf-77db60d96341",
       "name": "Company Name",
       "type": "string",
       "value": "Afresh"
      },
      {
       "id": "bcac3cfd-5b65-42fc-877f-985989c3f7a4",
       "name": "website",
       "type": "string",
       "value": "https://www.afresh.com"
      },
      {
       "id": "1b1cf94e-e0f1-49c1-88ad-0c17eed40b51",
       "name": "country",
       "type": "string",
       "value": "USA"
      },
      {
       "id": "75651307-2072-4508-ab62-cf2d5376832e",
       "name": "industry",
       "type": "string",
       "value": ""
      },
      {
       "id": "d020723b-afec-4cb9-a4f7-e8b10fbbe6f5",
       "name": "company_type",
       "type": "string",
       "value": ""
      },
      {
       "id": "a8e18c49-09cd-4ce1-b1dd-c1e72861084b",
       "name": "revenue",
       "type": "number",
       "value": 0
      }
     ]
    },
    "mode": "manual",
    "options": {}
   },
   "type": "n8n-nodes-base.set",
   "typeVersion": 3.5,
   "position": [
    224,
    0
   ],
   "id": "19430fb8-8e1b-4d32-8fcb-6ea8787ca65e",
   "name": "Test Company Input"
  },
  {
   "parameters": {
    "modelId": {
     "__rl": true,
     "value": "chat-latest",
     "mode": "list",
     "cachedResultName": "CHAT-LATEST"
    },
    "responses": {
     "values": [
      {
       "content": "=You are a B2B business development research analyst for Grandeur Advisory LLP.\n\nYour task is to research, verify, structure, and qualify the supplied company for Grandeur Advisory's B2B prospect database.\n\nYou have access to Web Search.\n\nUse the supplied company information as the starting point and use Web Search to research publicly available information about the SAME company.\n\nIMPORTANT:\n\n- Do not invent, assume, estimate, or infer information.\n- Do not confuse the company with another company having a similar name.\n- Use only information that is explicitly supported by the supplied information or reliable web research.\n- If information cannot be verified, return an empty string \"\".\n- Do not use industry assumptions to fill missing information.\n- Do not use search-result snippets as sufficient evidence when the underlying source cannot verify the information.\n- Prefer authoritative and recent sources.\n- Prefer the company's official website, official company pages, official careers pages, government filings, regulatory filings, and reputable business publications.\n- When multiple sources conflict, prefer the most authoritative and recent source.\n- Do not treat third-party estimates as confirmed company facts unless clearly identified as estimates.\n- Do not treat a technology as being used by the company merely because it is common in that industry.\n- Do not treat outsourcing as existing merely because the company uses external vendors.\n- Do not treat hiring as a finance hiring signal unless the role is clearly related to finance, accounting, controllership, CFO, FP&A, AP, AR, or another relevant finance function.\n- Do not infer company growth merely from company size.\n- Do not infer the existence of a parent company unless explicitly verified.\n- Do not create IDs for companies, parent companies, or sources.\n\nSUPPLIED COMPANY INFORMATION:\n\nCompany Name: {{ $json[\"Company Name\"] }}\nWebsite: {{ $json[\"website\"] }}\nCountry: {{ $json[\"country\"] }}\nIndustry: {{ $json[\"industry\"] }}\nCompany Type: {{ $json[\"company_type\"] }}\n\nRESEARCH OBJECTIVE:\n\nUse Web Search to determine which of the following company information can be reliably verified.\n\nResearch, where available:\n\n- Legal company name\n- Headquarters state/region\n- Headquarters city\n- Parent company\n- Finance hiring activity\n- Countries in which the company operates\n- Company operating status\n- Relevant recent business signals\n\nDO NOT research, web-search, or populate the following — leave each blank and spend ZERO search effort on them, including when judging ICP Fit or Priority: ownership, revenue, revenue type/band, employee count/type/band, finance team size, growth information, ERP, accounting software, technology stack, number of entities, existing outsourcing, current provider. Judge ICP Fit and Priority only from finance hiring activity, company operating status, recent business signals, and the supplied discovery notes.\n\nDo not spend research effort trying to fill a field when reliable information is not available.\n\nRETURN ONLY A VALID JSON OBJECT WITH EXACTLY THESE 24 FIELDS:\n\n{\n  \"company_id\": \"\",\n  \"company_name\": \"\",\n  \"legal_name\": \"\",\n  \"website\": \"\",\n  \"country\": \"\",\n  \"state_region\": \"\",\n  \"city\": \"\",\n  \"parent_company_id\": \"\",\n  \"company_type\": \"\",\n  \"industry\": \"\",\n  \"finance_hiring_activity\": \"\",\n  \"countries_operated\": \"\",\n  \"company_status\": \"\",\n  \"first_discovered\": \"\",\n  \"last_researched\": \"\",\n  \"last_signal_date\": \"\",\n  \"next_research_date\": \"\",\n  \"primary_source_id\": \"\",\n  \"verification_status\": \"\",\n  \"notes\": \"\",\n  \"icp_fit\": \"\",\n  \"priority\": \"\",\n  \"reason\": \"\",\n  \"missing_information\": \"\"\n}\n\nFIELD RULES:\n\ncompany_id:\nLeave blank unless a Company ID is explicitly supplied.\n\ncompany_name:\nUse the supplied Company Name. If reliable research confirms the same company's name, retain the supplied company name unless there is a clearly verified legal/official name that belongs in legal_name.\n\nlegal_name:\nPopulate only when the legal or registered company name is explicitly verified.\n\nwebsite:\nUse the supplied Website.\n\ncountry:\nUse the supplied Country unless reliable research clearly verifies that the supplied country is incorrect for the same company.\n\nstate_region:\nPopulate only when the company's headquarters state, province, region, or equivalent is explicitly verified.\n\ncity:\nPopulate only when the company's headquarters city is explicitly verified.\n\nparent_company_id:\nLeave blank unless a Company ID for the parent company was explicitly supplied.\nDo not create a parent company ID.\n\ncompany_type:\nUse the supplied Company Type unless reliable research clearly verifies a different type for the same company.\n\nindustry:\nUse the supplied Industry unless reliable research clearly verifies a more accurate description of the company's primary industry.\n\nfinance_hiring_activity:\nPopulate only when a current or recent finance/accounting hiring signal is explicitly verified.\nRelevant examples include CFO, Controller, Finance Director, Accounting Manager, FP&A, AP, AR, or other clearly finance-related positions.\nDo not classify generic hiring as finance hiring.\n\ncountries_operated:\nInclude only countries where the company's own operations, offices, subsidiaries, or business presence are explicitly verified.\nDo not count customer or supplier countries.\n\ncompany_status:\nPopulate only when the company's operating status is explicitly verified, such as Active, Acquired, Inactive, or Dissolved.\n\nfirst_discovered:\nLeave blank unless a discovery date is explicitly supplied.\n\nlast_researched:\nLeave blank unless a research date is explicitly supplied by the workflow.\n\nlast_signal_date:\nPopulate only when a specific date associated with a verified recent business signal is available.\n\nnext_research_date:\nLeave blank unless explicitly supplied by the workflow.\n\nprimary_source_id:\nLeave blank unless a source ID is explicitly supplied by the workflow.\n\nverification_status:\nUse exactly one of:\n\"Verified\"\n\"Partially Verified\"\n\"Unverified\"\n\nUse \"Verified\" only when the company identity and core company information can be reliably confirmed.\n\nUse \"Partially Verified\" when the company identity is reasonably confirmed but important information remains unverified.\n\nUse \"Unverified\" when the company identity itself cannot be reliably confirmed.\n\nnotes:\nProvide concise factual research notes.\nInclude important verified observations that do not fit naturally into another field.\nDo not include unsupported opinions.\n\nICP FIT:\n\nICP Fit must be exactly one of:\n\n\"High\"\n\"Medium\"\n\"Low\"\n\"Unknown\"\n\nDo not invent ICP criteria.\n\nUse the previously established Grandeur Advisory positioning and verified company information when evaluating ICP fit.\n\nPositive indicators may include verified characteristics such as:\n\n- Strong fit with Grandeur Advisory's target markets\n- Meaningful accounting or finance complexity\n- Finance/accounting transformation\n- Finance or accounting hiring\n- Other explicit signals indicating a potential need for outsourced accounting, bookkeeping, financial reporting, AP/AR, or fractional finance leadership\n\nDo not classify a company as High merely because it is large, public, private, or in a preferred industry.\n\nOnly assign High or Medium when there is enough verified evidence to support the classification.\n\nIf the available information is insufficient to objectively determine ICP Fit, use \"Unknown\".\n\nPRIORITY:\n\nPriority must be exactly one of:\n\n\"High\"\n\"Medium\"\n\"Low\"\n\"Unknown\"\n\nPriority should reflect the strength and commercial relevance of the verified opportunity, not simply company size.\n\nStrong verified buying signals should increase priority.\n\nExamples of meaningful signals include:\n\n- Finance/accounting hiring\n- CFO or Controller hiring\n- Acquisition activity\n- A newly established finance leadership function\n- Other explicit evidence suggesting an active or emerging finance need\n\nDo not assign High Priority solely because revenue is large.\n\nIf there is insufficient evidence to determine priority, use \"Unknown\".\n\nREASON:\n\nExplain the ICP Fit and Priority using only verified information.\n\nThe reason must distinguish between:\n\n1. Verified company facts\n2. Verified positive or negative sales signals\n3. Information that is still missing\n\nDo not make unsupported statements such as \"they probably need outsourcing\" or \"they likely have finance problems.\"\n\nMISSING_INFORMATION:\n\nList the important information that remains unavailable and would be needed for proper ICP qualification.\n\nUse concise comma-separated items.\n\nDo not list fields that have already been reliably verified.\n\nSOURCE AND EVIDENCE RULES:\n\nUse Web Search during research.\n\nFor important researched facts, record the source name and/or source URL in the \"notes\" field where useful.\n\nDo not fabricate source URLs.\n\nDo not claim that a source verified something unless the source actually supports the claim.\n\nIf no reliable source can verify a field, leave that field blank.\n\nOUTPUT RULES:\n\nReturn ONLY the JSON object.\n\nDo not return Markdown.\n\nDo not return code fences.\n\nDo not return explanations outside the JSON.\n\nReturn exactly the 24 fields listed above.\n\nDo not add any additional fields.\n\nDo not remove any fields.\n\nUse \"\" for unavailable ordinary company data.\n\nUse \"Unknown\" only for ICP Fit or Priority when there is insufficient evidence to determine them."
      }
     ]
    },
    "builtInTools": {
     "webSearch": {
      "searchContextSize": "medium"
     }
    },
    "options": {
     "textFormat": {
      "textOptions": {
       "type": "text"
      }
     }
    }
   },
   "type": "@n8n/n8n-nodes-langchain.openAi",
   "typeVersion": 2.3,
   "position": [
    1400,
    100
   ],
   "id": "ecd9ccaa-09d1-4a7f-9ce0-619e09af1b13",
   "name": "Company Research AI",
   "credentials": {
    "openAiApi": {
     "id": "Iny8RznkWYiFgD9G",
     "name": "OpenAI account"
    }
   }
  },
  {
   "parameters": {
    "assignments": {
     "assignments": [
      {
       "id": "fc759636-ba9c-4c93-9572-3d7e9c9618d4",
       "name": "Company ID",
       "type": "string",
       "value": "={{\n  (() => {\n    const data = JSON.parse($json.output[0].content[0].text);\n    const name = (data.company_name || '').toString().toLowerCase().replace(/[^a-z0-9]/g, '');\n    const country = (data.country || '').toString().toLowerCase().replace(/[^a-z]/g, '');\n    return 'COM-' + name + (country ? '-' + country : '');\n  })()\n}}"
      },
      {
       "id": "c4ee01bb-1697-44fb-81d2-1351e2da12b4",
       "name": "Company Name",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).company_name }}"
      },
      {
       "id": "13166e28-12d6-4176-96bc-f3c6f225326b",
       "name": "Legal Name",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).legal_name }}"
      },
      {
       "id": "5c9f04d9-324d-44d5-9b8c-5c6510105389",
       "name": "Website",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).website }}"
      },
      {
       "id": "93acdf04-0896-4d64-87a7-4e5ae4493259",
       "name": "Country",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).country }}"
      },
      {
       "id": "6b8ace92-b198-474e-8f13-fb13b7d39ce6",
       "name": "State/Region",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).state_region }}"
      },
      {
       "id": "b90c83c3-0a26-4707-b81a-b6645311c03e",
       "name": "City",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).city }}"
      },
      {
       "id": "a42757cb-8565-45a2-bda0-53115fa0178d",
       "name": "Parent Company ID",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).parent_company_id }}"
      },
      {
       "id": "d533c640-0ad8-4c38-b971-2d1d0fbb28f4",
       "name": "Company Type",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).company_type }}"
      },
      {
       "id": "4e04d650-5bf6-4009-855a-af211bd9e452",
       "name": "Industry",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).industry }}"
      },
      {
       "id": "7fd26e8d-f36f-49bf-983c-2e94ac453c13",
       "name": "Finance Hiring Activity",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).finance_hiring_activity }}"
      },
      {
       "id": "100f249c-3f39-44fc-98fe-cf41b15720d7",
       "name": "Countries Operated",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).countries_operated }}"
      },
      {
       "id": "40b62214-6912-4904-9523-9c827df09786",
       "name": "Company Status",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).company_status }}"
      },
      {
       "id": "b1de171d-14bc-4243-b9a7-821cb47e3e40",
       "name": "First Discovered",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).first_discovered }}"
      },
      {
       "id": "a23eb92c-0e84-451b-b785-bd99d08bdc09",
       "name": "Last Researched",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).last_researched }}"
      },
      {
       "id": "fc7f0708-7ad6-4580-9135-939f49106636",
       "name": "Last Signal Date",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).last_signal_date }}"
      },
      {
       "id": "acfc58a8-2e5c-4429-b0eb-a7859504dd3e",
       "name": "Next Research Date",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).next_research_date }}"
      },
      {
       "id": "2ecdb095-fe8d-411f-8830-534e2a4c76ab",
       "name": "Primary Source ID",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).primary_source_id }}"
      },
      {
       "id": "9176b3e0-1e5a-4285-9d35-d1f92fc287ef",
       "name": "Verification Status",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).verification_status }}"
      },
      {
       "id": "66edc7d0-3be8-424f-a80d-79ee5db1f9f9",
       "name": "Notes",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).notes }}"
      },
      {
       "id": "2ec987a2-a8a2-4589-8176-f6d1124e9b42",
       "name": "ICP Fit",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).icp_fit }}"
      },
      {
       "id": "f7e836a3-eec7-46e2-9827-efe4d29c218f",
       "name": "Priority",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).priority }}"
      },
      {
       "id": "12ce6f1f-1288-4a3d-ab39-20825468ae20",
       "name": "Reason",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).reason }}"
      },
      {
       "id": "3651d652-6718-4989-96b1-cd42b5bc90b1",
       "name": "Missing Information",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text).missing_information }}"
      }
     ]
    },
    "options": {}
   },
   "type": "n8n-nodes-base.set",
   "typeVersion": 3.5,
   "position": [
    768,
    0
   ],
   "id": "a72c21b8-b4b7-4068-9c83-f47699448053",
   "name": "Normalize Research Output"
  },
  {
   "parameters": {
    "resource": "worksheet",
    "operation": "upsert",
    "workbook": {
     "__rl": true,
     "cachedResultName": "Grandeur_BD_Agent_V1",
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6"
    },
    "worksheet": {
     "__rl": true,
     "cachedResultName": "Companies",
     "mode": "list",
     "value": "{00000000-0001-0000-0100-000000000000}"
    },
    "dataMode": "autoMap",
    "columnToMatchOn": "Company Key",
    "options": {}
   },
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1472,
    -96
   ],
   "id": "8c719bdd-a3b4-4706-a554-8d1e5bdde741",
   "name": "Upsert Company",
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "parameters": {
    "assignments": {
     "assignments": [
      {
       "id": "d741bb71-4616-47e2-ae2a-07c317caa772",
       "name": "Opportunity ID",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text.message).opportunity_id }}"
      },
      {
       "id": "2b020ad3-3f41-4d74-a97b-ed8bbb867635",
       "name": "Company ID",
       "type": "string",
       "value": "={{ $('Assign Company ID').first().json['Company ID'] }}"
      },
      {
       "id": "1f21632e-df3b-49a1-a186-a8227305da21",
       "name": "Opportunity Type",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text.message).opportunity_type }}"
      },
      {
       "id": "51f1623b-3b1d-4fe1-8b78-6494e9ed3103",
       "name": "Opportunity Description",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text.message).opportunity_description }}"
      },
      {
       "id": "2c62596f-8810-4a5d-9ae2-87662e3e8c03",
       "name": "Primary Signal",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text.message).primary_signal }}"
      },
      {
       "id": "f6c74a6c-eeb5-4239-a9f2-ef5688c4bcff",
       "name": "Signal Strength",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text.message).signal_strength }}"
      },
      {
       "id": "2dde3bff-4e9e-47ce-b8ce-11f4c96b3653",
       "name": "First Detected",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text.message).first_detected }}"
      },
      {
       "id": "948e9337-f052-4606-b3c3-2563e81950f6",
       "name": "Last Verified",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text.message).last_verified }}"
      },
      {
       "id": "f242ce94-a207-4851-98dd-194692acd8f2",
       "name": "Expected Deadline",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text.message).expected_deadline }}"
      },
      {
       "id": "4c9e0af2-9875-4d60-9855-a6fe843abefa",
       "name": "Urgency",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text.message).urgency }}"
      },
      {
       "id": "4f445758-7e98-474e-ace0-c78ea466813b",
       "name": "Grandeur Service",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text.message).grandeur_service }}"
      },
      {
       "id": "1fbb82c5-76ad-4a35-a51e-d7c6168fdbee",
       "name": "Opportunity Score",
       "type": "number",
       "value": "={{ JSON.parse($json.output[0].content[0].text.message).opportunity_score }}"
      },
      {
       "id": "90ff8195-5bef-4410-8b7b-049a8f204ebb",
       "name": "Opportunity Status",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text.message).opportunity_status }}"
      },
      {
       "id": "635cb31d-fc32-44b1-9c09-644ae6a42bad",
       "name": "Next Best Action",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text.message).next_best_action }}"
      },
      {
       "id": "e146fbfa-4d60-4179-8102-c3bf9975d9ac",
       "name": "Recommended Contact Date",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text.message).recommended_contact_date }}"
      },
      {
       "id": "1d9de687-424e-42cd-b99c-18f8e7230b5d",
       "name": "Recommended Contact Window",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text.message).recommended_contact_window }}"
      },
      {
       "id": "f2d8c8cd-750c-447d-8a69-8df69d3bf73f",
       "name": "Evidence Summary",
       "type": "string",
       "value": "={{ JSON.parse($json.output[0].content[0].text.message).evidence_summary }}"
      }
     ]
    },
    "options": {}
   },
   "type": "n8n-nodes-base.set",
   "typeVersion": 3.5,
   "position": [
    320,
    224
   ],
   "id": "89c94e86-dd8f-449a-92b7-1ced9b1fd86a",
   "name": "Map Opportunity Output"
  },
  {
   "parameters": {
    "modelId": {
     "__rl": true,
     "value": "chat-latest",
     "mode": "list",
     "cachedResultName": "CHAT-LATEST"
    },
    "responses": {
     "values": [
      {
       "content": "=You are a B2B business development opportunity analyst for Grandeur Advisory LLP.\n\nYour job is to identify and structure genuine sales opportunities for Grandeur Advisory based on the supplied company record and publicly verifiable information.\n\nUse Web Search to look for current or recent business signals related to the SAME company.\n\nIMPORTANT RULES:\n\n- Do not invent, assume, estimate, or infer opportunities.\n- Do not confuse the company with similarly named companies.\n- Only identify an opportunity when there is explicit supporting evidence.\n- A company being large, profitable, public, private, or in a preferred industry is NOT by itself an opportunity.\n- Do not create an opportunity simply because Grandeur Advisory could theoretically provide a service.\n- Prefer recent and authoritative sources.\n- Prefer the company's official website, careers pages, official announcements, filings, reputable business publications, and other reliable sources.\n- If the supplied website is clearly a placeholder, invalid, unrelated, or does not establish the company's identity, do not treat it as evidence of the company.\n- If no genuine opportunity can be verified, return an Opportunity Score of 0.\n- Do not fabricate contact dates, deadlines, values, providers, decision makers, or source IDs.\n- Do not fabricate URLs or source IDs.\n- Return ONLY the JSON object described below.\n- Do not return Markdown or explanations outside the JSON.\n\nSUPPLIED COMPANY RECORD:\n\nCompany ID: {{ $json['Company ID'] || '' }}\nCompany Name: {{ $json['Company Name'] || '' }}\nLegal Name: {{ $json['Legal Name'] || '' }}\nWebsite: {{ $json['Website'] || '' }}\nCountry: {{ $json['Country'] || '' }}\nState/Region: {{ $json['State/Region'] || '' }}\nCity: {{ $json['City'] || '' }}\nParent Company ID: {{ $json['Parent Company ID'] || '' }}\nCompany Type: {{ $json['Company Type'] || '' }}\nIndustry: {{ $json['Industry'] || '' }}\nOwnership Type: {{ $json['Ownership Type'] || '' }}\nRevenue: {{ $json['Revenue'] || '' }}\nRevenue Type: {{ $json['Revenue Type'] || '' }}\nRevenue Band: {{ $json['Revenue Band'] || '' }}\nEmployee Count: {{ $json['Employee Count'] || '' }}\nEmployee Count Type: {{ $json['Employee Count Type'] || '' }}\nEmployee Band: {{ $json['Employee Band'] || '' }}\nFinance Team Size: {{ $json['Finance Team Size'] || '' }}\nFinance Hiring Activity: {{ $json['Finance Hiring Activity'] || '' }}\nGrowth Information: {{ $json['Growth Information'] || '' }}\nERP: {{ $json['ERP'] || '' }}\nAccounting Software: {{ $json['Accounting Software'] || '' }}\nTechnology Stack: {{ $json['Technology Stack'] || '' }}\nNumber of Entities: {{ $json['Number of Entities'] || '' }}\nCountries Operated: {{ $json['Countries Operated'] || '' }}\nExisting Outsourcing: {{ $json['Existing Outsourcing'] || '' }}\nCurrent Provider: {{ $json['Current Provider'] || '' }}\nCompany Status: {{ $json['Company Status'] || '' }}\nFirst Discovered: {{ $json['First Discovered'] || '' }}\nLast Researched: {{ $json['Last Researched'] || '' }}\nLast Signal Date: {{ $json['Last Signal Date'] || '' }}\nNext Research Date: {{ $json['Next Research Date'] || '' }}\nPrimary Source ID: {{ $json['Primary Source ID'] || '' }}\nVerification Status: {{ $json['Verification Status'] || '' }}\nNotes: {{ $json['Notes'] || '' }}\nICP Fit: {{ $json['ICP Fit'] || '' }}\nPriority: {{ $json['Priority'] || '' }}\nReason: {{ $json['Reason'] || '' }}\nMissing Information: {{ $json['Missing Information'] || '' }}\n\nOPPORTUNITY TYPES TO LOOK FOR:\n\nOnly identify an opportunity when supported by evidence.\n\nPotential opportunity categories include:\n\n- Accounting / Bookkeeping\n- Month-End Close\n- Financial Reporting\n- Management Reporting\n- Fractional CFO / Finance Leadership\n- AP / AR\n- Finance Operations\n- NetSuite / ERP Support\n- ERP Implementation or Transformation\n- Accounting System Transformation\n- Finance Team Expansion\n- Finance / Accounting Outsourcing\n- International Finance Operations\n- Multi-Entity Accounting\n- Other clearly verified finance-related opportunity\n\nIMPORTANT SIGNALS:\n\nLook for explicit evidence such as:\n\n- Finance or accounting hiring\n- CFO, Controller, Finance Director, Accounting Manager, FP&A, AP or AR hiring\n- New CFO or Controller appointment\n- ERP implementation or migration\n- NetSuite implementation or expansion\n- Accounting software change\n- Finance transformation\n- Rapid geographic expansion\n- International expansion\n- Acquisition activity creating additional accounting complexity\n- New subsidiaries or entities\n- Finance/accounting outsourcing\n- Explicit search for an external accounting or finance provider\n- Significant finance team restructuring\n- Other recent and verifiable finance-related business signals\n\nDo NOT treat generic company hiring as a finance opportunity.\n\nDo NOT treat a job posting as an outsourcing opportunity unless the evidence specifically supports an external-service need.\n\nOPPORTUNITY SCORE:\n\nUse an integer from 0 to 100.\n\nScore based ONLY on verified evidence.\n\n0:\nNo verified opportunity or no reliable evidence.\n\n1-29:\nVery weak or indirect signal.\n\n30-49:\nSome relevant signal, but weak commercial evidence.\n\n50-69:\nMeaningful verified signal indicating a plausible Grandeur opportunity.\n\n70-84:\nStrong verified signal with a clear connection to a Grandeur service.\n\n85-100:\nVery strong, recent, specific buying signal with a clear and commercially relevant Grandeur opportunity.\n\nDo not increase the score merely because revenue or company size is high.\n\nOPPORTUNITY STATUS:\n\nUse exactly one of:\n\n\"New\"\n\"Active\"\n\"Monitoring\"\n\"Closed\"\n\"Unknown\"\n\nUse \"New\" when a newly identified opportunity is supported by evidence.\n\nUse \"Monitoring\" when there is a relevant signal but insufficient evidence of an active buying opportunity.\n\nUse \"Unknown\" when the status cannot be determined.\n\nSIGNAL STRENGTH:\n\nUse exactly one of:\n\n\"Strong\"\n\"Medium\"\n\"Weak\"\n\"None\"\n\nUse \"None\" when no genuine opportunity is identified.\n\nURGENCY:\n\nUse exactly one of:\n\n\"Immediate\"\n\"Near Term\"\n\"Normal\"\n\"Low\"\n\"Unknown\"\n\nOnly assign urgency when supported by evidence such as a deadline, active hiring process, announced implementation, transaction, expansion, or other time-sensitive event.\n\nGRANDEUR SERVICE:\n\nIdentify the most relevant Grandeur Advisory service ONLY when supported by the evidence.\n\nPotential services include:\n\n- Accounting & Bookkeeping\n- Financial Reporting\n- Management Reporting\n- Fractional CFO\n- AP / AR\n- NetSuite Support\n- ERP Consulting\n- Finance Operations\n- Outsourced Accounting\n- Multi-Entity Accounting\n\nDo not select a service merely because it could theoretically be useful.\n\nESTIMATED VALUE:\n\nOnly estimate opportunity value when there is sufficient evidence and a reasonable basis.\n\nIf there is insufficient evidence:\n\n- estimated_monthly_value = \"\"\n- estimated_annual_value = \"\"\n- estimate_type = \"\"\n- estimate_basis = \"\"\n\nNever invent a monetary value.\n\nIf an estimate is made, clearly explain the basis in estimate_basis and use \"Estimated\" as estimate_type.\n\nNEXT BEST ACTION:\n\nRecommend the most appropriate next action based on the verified opportunity.\n\nExamples:\n\n- Research CFO/Controller\n- Monitor finance hiring\n- Review ERP implementation signal\n- Identify finance decision maker\n- Prepare personalized outreach\n- Monitor for outsourcing signal\n\nDo not recommend contacting someone when no relevant decision maker has been identified.\n\nWORK ARRANGEMENT (REQUIRED):\n\nGrandeur Advisory delivers finance and accounting work remotely. A role that must be\nperformed on-site, or on a hybrid schedule requiring days in an office, cannot be served\nby Grandeur, so the work arrangement of the underlying signal decides whether the\nopportunity is pursuable at all.\n\nWhen the signal is a job posting, determine the work arrangement from the posting itself.\nDo not infer it from the company's general policy, from the city named in the posting, or\nfrom what is typical for the role. A posting that merely names a headquarters location is\nnot thereby on-site.\n\nBegin evidence_summary with exactly one of these tags, followed by a space and a pipe:\n\nWORK ARRANGEMENT: Remote |\nWORK ARRANGEMENT: Hybrid |\nWORK ARRANGEMENT: On-site |\nWORK ARRANGEMENT: Not stated |\nWORK ARRANGEMENT: Not a job posting |\n\nUse \"Remote\" only when the posting explicitly says the role is remote, fully remote,\nwork from home, or distributed with no office requirement.\n\nUse \"Hybrid\" when the posting requires some days in an office.\n\nUse \"On-site\" when the posting requires full-time presence at a location.\n\nUse \"Not stated\" when the signal is a job posting but the posting does not state a work\narrangement.\n\nUse \"Not a job posting\" when the verified signal is something other than a job posting -\nan ERP migration, a funding round, an acquisition, a leadership appointment, an\noutsourcing search, or similar.\n\nNever guess. \"Not stated\" is the correct answer whenever a posting does not say.\n\nEVIDENCE:\n\nEvidence Summary must briefly explain:\n\n1. What the verified signal is.\n2. Why it represents a potential Grandeur opportunity.\n3. The source/date where relevant.\n\nDo not make unsupported claims.\n\nRETURN EXACTLY THIS JSON OBJECT:\n\n{\n  \"opportunity_id\": \"\",\n  \"company_id\": \"\",\n  \"opportunity_type\": \"\",\n  \"opportunity_description\": \"\",\n  \"primary_signal\": \"\",\n  \"signal_strength\": \"\",\n  \"first_detected\": \"\",\n  \"last_verified\": \"\",\n  \"expected_deadline\": \"\",\n  \"urgency\": \"\",\n  \"grandeur_service\": \"\",\n  \"estimated_monthly_value\": \"\",\n  \"estimated_annual_value\": \"\",\n  \"estimate_type\": \"\",\n  \"estimate_basis\": \"\",\n  \"opportunity_score\": 0,\n  \"opportunity_status\": \"\",\n  \"next_best_action\": \"\",\n  \"recommended_contact_date\": \"\",\n  \"recommended_contact_window\": \"\",\n  \"primary_contact_id\": \"\",\n  \"evidence_summary\": \"\"\n}\n\nFINAL RULES:\n\n- Return exactly the 22 fields above.\n- Do not add fields.\n- Do not remove fields.\n- Use \"\" for unavailable ordinary fields.\n- Use 0 only for Opportunity Score when no opportunity can be verified.\n- If no opportunity is verified, use:\n  \"opportunity_type\": \"\"\n  \"opportunity_description\": \"\"\n  \"primary_signal\": \"\"\n  \"signal_strength\": \"None\"\n  \"urgency\": \"Unknown\"\n  \"grandeur_service\": \"\"\n  \"opportunity_score\": 0\n  \"opportunity_status\": \"Monitoring\"\n  \"next_best_action\": \"Monitor for a verified finance or accounting buying signal\"\n- Do not create an opportunity simply because the company appears attractive.\n- Evidence must support the opportunity.\n- Return ONLY valid JSON."
      }
     ]
    },
    "builtInTools": {
     "webSearch": {
      "searchContextSize": "medium"
     }
    },
    "options": {
     "textFormat": {
      "textOptions": {
       "type": "json_schema"
      }
     }
    }
   },
   "type": "@n8n/n8n-nodes-langchain.openAi",
   "typeVersion": 2.3,
   "position": [
    -48,
    224
   ],
   "id": "8c456609-2b1b-410f-86f1-1ff086a3e23e",
   "name": "Opportunity Research",
   "credentials": {
    "openAiApi": {
     "id": "Iny8RznkWYiFgD9G",
     "name": "OpenAI account"
    }
   }
  },
  {
   "parameters": {
    "resource": "worksheet",
    "operation": "upsert",
    "workbook": {
     "__rl": true,
     "cachedResultName": "Grandeur_BD_Agent_V1",
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6"
    },
    "worksheet": {
     "__rl": true,
     "cachedResultName": "Opportunities",
     "mode": "list",
     "value": "{00000000-0001-0000-0200-000000000000}"
    },
    "dataMode": "autoMap",
    "columnToMatchOn": "Opportunity ID",
    "options": {}
   },
   "id": "0a152f38-0720-45ae-a627-99230abe406e",
   "name": "Upsert Opportunity",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1008,
    400
   ],
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "parameters": {
    "resource": "table",
    "operation": "getRows",
    "workbook": {
     "__rl": true,
     "cachedResultName": "Grandeur_BD_Agent_V1",
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6"
    },
    "worksheet": {
     "__rl": true,
     "cachedResultName": "Companies",
     "mode": "list",
     "value": "{00000000-0001-0000-0100-000000000000}"
    },
    "table": {
     "__rl": true,
     "cachedResultName": "tblCompanies",
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF00000000}"
    },
    "returnAll": true,
    "filters": {}
   },
   "id": "e12a4c06-8fc7-410e-a4a6-d74824a2bd37",
   "name": "Get Existing Companies",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1008,
    0
   ],
   "alwaysOutputData": true,
   "executeOnce": true,
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "parameters": {
    "mode": "runOnceForAllItems",
    "language": "javaScript",
    "jsCode": "// Research is the SINGLE authority for Company IDs.\n//\n// Discovery appends a stub carrying only Company Key (the domain), Company Name,\n// Website and Country, with the ID left blank on purpose. This node mints the ID\n// the first time that company is researched, and Upsert Company matches on\n// Company Key so the stub is filled in rather than duplicated.\n//\n// The previous design had discovery assigning IDs too. Both sides derived the\n// next ID by reading the table and incrementing, so a single bad read at either\n// end corrupted the ID space - which is exactly what happened on 2026-08-27,\n// when a read returned blank rows and five companies were written as Grand\n// 001-005 on top of live rows. One writer removes the whole class of bug.\n\nconst norm = (v) => (v == null ? '' : String(v)).trim();\n\nconst normalizeDomain = (w) => {\n  let s = norm(w).toLowerCase();\n  s = s.replace(/^https?:\\/\\//, '');\n  s = s.replace(/^www\\./, '');\n  s = s.split('/')[0].split('?')[0].split('#')[0];\n  return s.trim();\n};\n\n// Every row that identifies a company, INCLUDING discovery stubs with no ID yet.\n// The old filter was rows.filter(r => r && r['Company ID']), which made stubs\n// invisible here and caused research to create a second row for them.\nconst rows = $input.all()\n  .map(i => i.json)\n  .filter(r => r && (norm(r['Company ID']) || norm(r['Company Key']) || norm(r['Company Name'])));\n\nconst company = $('Normalize Research Output').first().json;\n\n// $now is Luxon in the workflow timezone, pinned to Asia/Kolkata. new Date()\n// would use the container clock, which is UTC, and stamp the previous day after\n// 18:30 IST - and this value drives the research queue's 14-day floor.\nconst today = $now.toFormat('yyyy-LL-dd');\nconst companyKey = normalizeDomain(company['Website']);\n\nlet matched = null;\nif (companyKey) {\n  for (const r of rows) {\n    const k = normalizeDomain(r['Company Key'] || r['Website']);\n    if (k && k === companyKey) { matched = r; break; }\n  }\n}\n\n// The next free number, derived only from rows that actually carry an ID.\nconst mintNextId = () => {\n  let max = 0;\n  for (const r of rows) {\n    const m = norm(r['Company ID']).match(/(\\d+)\\s*$/);\n    if (m) {\n      const n = parseInt(m[1], 10);\n      if (!isNaN(n) && n > max) max = n;\n    }\n  }\n  const next = max + 1;\n  const width = Math.max(3, String(next).length);\n  return 'Grand ' + String(next).padStart(width, '0');\n};\n\nlet companyId, firstDiscovered, isNew;\n\nif (matched && norm(matched['Company ID'])) {\n  // Already researched before - keep its identity.\n  companyId = norm(matched['Company ID']);\n  firstDiscovered = matched['First Discovered'] || today;\n  isNew = false;\n} else if (matched) {\n  // A discovery stub: the row exists and holds the original discovery date, but\n  // has never been researched, so it has no ID yet. Mint one now.\n  companyId = mintNextId();\n  firstDiscovered = matched['First Discovered'] || today;\n  isNew = false;\n} else {\n  companyId = mintNextId();\n  firstDiscovered = today;\n  isNew = true;\n}\n\nconst out = {};\nfor (const [k, v] of Object.entries(company)) {\n  out[k.replace(/^=+/, '')] = v;\n}\n\n// A supplied revenue of 0 means unknown, not \"under $1M\". Never record a\n// revenue band no source verified.\nif (!Number(out['Revenue'])) {\n  out['Revenue'] = '';\n  out['Revenue Band'] = '';\n  out['Revenue Type'] = '';\n}\n\nout['Company ID'] = companyId;\nout['Company Key'] = companyKey;\nout['First Discovered'] = firstDiscovered;\nout['Last Researched'] = today;\nout['Is New Company'] = isNew;\n\nreturn [{ json: out }];"
   },
   "id": "8b27bfc0-7a01-46ac-9e5b-7723c5347e39",
   "name": "Assign Company ID",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    1232,
    0
   ]
  },
  {
   "parameters": {
    "resource": "table",
    "operation": "getRows",
    "workbook": {
     "__rl": true,
     "cachedResultName": "Grandeur_BD_Agent_V1",
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6"
    },
    "worksheet": {
     "__rl": true,
     "cachedResultName": "Opportunities",
     "mode": "list",
     "value": "{00000000-0001-0000-0200-000000000000}"
    },
    "table": {
     "__rl": true,
     "cachedResultName": "tblOpportunities",
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF01000000}"
    },
    "returnAll": true,
    "filters": {}
   },
   "id": "02a1ac92-28af-432b-a913-8e48ee9d89e0",
   "name": "Get Existing Opportunities",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    560,
    400
   ],
   "alwaysOutputData": true,
   "executeOnce": true,
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "parameters": {
    "jsCode": "const rows = $input.all()\n  .map(i => i.json)\n  .filter(r => r && r['Opportunity ID']);\n\nconst opp = $('Map Opportunity Output').first().json;\n\nconst norm = (v) => (v == null ? '' : String(v)).trim().toLowerCase().replace(/\\s+/g, ' ');\nconst today = new Date().toISOString().slice(0, 10);\n\nconst companyId = String(opp['Company ID'] || '').trim();\n\n// Keyed on the COMPANY alone, deliberately.\n// The key used to include Opportunity Type, but the research model renames the\n// same underlying signal between runs - AssetWatch's ERP hire came back as\n// 'Finance Operations' once and 'ERP Implementation or Transformation' the next\n// time - so every re-research minted a second row for one company (8 and 19,\n// 9 and 20, 11 and 21). Outreach is already company-scoped, so a company has no\n// use for two rows: it keeps one, refreshed in place with the latest evidence.\nconst matchKey = norm(companyId);\n\nlet matched = null;\nfor (const r of rows) {\n  if (norm(r['Company ID']) === matchKey) { matched = r; break; }\n}\n\nlet opportunityId, firstDetected, isNew;\n\nif (matched) {\n  // Pass the sheet's own value through with its type intact so the upsert\n  // updates this row instead of appending beside it.\n  opportunityId = matched['Opportunity ID'];\n  firstDetected = matched['First Detected'] || opp['First Detected'] || today;\n  isNew = false;\n} else {\n  let max = 0;\n  for (const r of rows) {\n    const m = String(r['Opportunity ID']).match(/(\\d+)\\s*$/);\n    if (m) {\n      const n = parseInt(m[1], 10);\n      if (!isNaN(n) && n > max) max = n;\n    }\n  }\n  opportunityId = max + 1;\n  firstDetected = opp['First Detected'] || today;\n  isNew = true;\n}\n\nconst out = {};\nfor (const [k, v] of Object.entries(opp)) {\n  out[k.replace(/^=+/, '')] = v;\n}\n\nout['Opportunity ID'] = opportunityId;\nout['Company ID'] = companyId;\nout['First Detected'] = firstDetected;\nout['Last Verified'] = today;\nout['Is New Opportunity'] = isNew;\n\nreturn [{ json: out }];"
   },
   "id": "ab4688b1-33e8-46c1-b179-10a45c9fde3e",
   "name": "Assign Opportunity ID",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    784,
    400
   ]
  },
  {
   "parameters": {
    "modelId": {
     "__rl": true,
     "value": "chat-latest",
     "mode": "list",
     "cachedResultName": "CHAT-LATEST"
    },
    "responses": {
     "values": [
      {
       "content": "=You are a B2B contact research analyst for Grandeur Advisory LLP.\n\nYour task is to actively find the finance decision makers who CURRENTLY work at the ONE specific company defined below, using Web Search and publicly available business information.\n\n========================================\nTHE COMPANY IS FIXED - THIS IS THE HARD ANCHOR\n========================================\n\nCompany Name: {{ $('Assign Company ID').first().json['Company Name'] || '' }}\nWebsite: {{ $('Assign Company ID').first().json['Website'] || '' }}\nCountry: {{ $('Assign Company ID').first().json['Country'] || '' }}\nIndustry: {{ $('Assign Company ID').first().json['Industry'] || '' }}\n\nThe WEBSITE DOMAIN above (for example, the registered domain such as \"acme.com\" taken from the Website) is the single source of truth for this company's identity. A person qualifies ONLY if a reliable public source shows them CURRENTLY employed at THIS company, matched by BOTH the company name AND the same website domain. Many companies share similar names; the domain is what disambiguates them.\n\n========================================\nHOW TO FIND THEM - DO THIS ACTIVELY\n========================================\n\n1. Start at the company's OWN website: the About, Team, Leadership, or Management pages on its domain. A company's own leadership page is the most reliable source and often names the CFO, Head of Finance, or Controller directly.\n2. Search LinkedIn for people whose CURRENT company is this exact company and whose title is a finance role.\n3. Use reputable business sources that explicitly state the person's current employer as this company.\n\nDo the genuine work to find this company's real finance leaders. An empty result is correct ONLY when, after actually searching the sources above, you cannot verify anyone at THIS company. It is not a shortcut to skip the search.\n\n========================================\nCONTEXT - NOT A SEARCH TARGET\n========================================\n\nOpportunity Type: {{ $json['Opportunity Type'] || '' }}\nPrimary Signal: {{ $json['Primary Signal'] || '' }}\n\nThe Opportunity Type and Primary Signal explain WHY Grandeur is interested in this company. They are background context ONLY - not a list of companies to search, and not a job posting to chase. A job posting, article, or role description that belongs to a DIFFERENT company or DIFFERENT domain is irrelevant here even if it matches the signal perfectly. NEVER follow a matching signal, title, or job posting to another company.\n\n========================================\nABSOLUTE RULES\n========================================\n\n- NEVER invent, guess, construct, pattern-match, or infer an email address.\n- Do NOT build an email from a pattern such as firstname.lastname@domain even if that pattern appears elsewhere at the company.\n- Only return an email that is explicitly published in a reliable public source. If none, return \"\". A blank email is CORRECT and expected.\n- NEVER invent a person. Only return people explicitly verified as CURRENTLY holding a finance role at THIS company (name AND domain match).\n- NEVER return a person whose verified current employer is a different company - including a similarly named company, a parent, a subsidiary, or the company that posted a matching job. Drop them.\n- Do NOT return generic inboxes such as info@, sales@, support@, contact@ as a decision maker.\n- Do NOT fabricate LinkedIn URLs, phone numbers or source IDs.\n- Between a real finance leader at THIS company and an empty array, return the real leader. Between a wrong-company or invented person and an empty array, return the empty array.\n\nIf the Website is clearly a placeholder, invalid, or does not establish the company's identity, return an empty contacts array.\n\n========================================\nWHO TO LOOK FOR (most relevant first)\n========================================\n\n- CFO / Chief Financial Officer\n- Finance Director\n- Controller / Financial Controller\n- VP Finance\n- Head of Finance / Head of Accounting\n- Finance Manager\n- Accounting Manager\n- Founder / CEO (only for small companies with no dedicated finance leader)\n\nReturn at most 3 people. Rank the most relevant decision maker first.\n\n========================================\nPER-PERSON CHECK - APPLY BEFORE INCLUDING ANYONE\n========================================\n\nFor each candidate, before you include them:\n1. Confirm a reliable source shows their CURRENT employer is this exact company (name AND website domain match).\n2. In \"notes\", name the source AND state the employer exactly as the source gives it. If that employer is not this company, do NOT include the person.\n\n========================================\nRETURN ONLY THIS JSON OBJECT\n========================================\n\n{\n  \"contacts\": [\n    {\n      \"name\": \"\",\n      \"job_title\": \"\",\n      \"department\": \"\",\n      \"seniority\": \"\",\n      \"linkedin_url\": \"\",\n      \"email\": \"\",\n      \"email_verification_status\": \"\",\n      \"phone\": \"\",\n      \"phone_verification_status\": \"\",\n      \"source_id\": \"\",\n      \"contact_confidence\": \"\",\n      \"primary_decision_maker\": \"\",\n      \"backup_decision_maker\": \"\",\n      \"do_not_contact\": \"\",\n      \"notes\": \"\"\n    }\n  ]\n}\n\nFIELD RULES:\n\nname: Full name, only if explicitly verified at THIS company.\njob_title: The person's actual current title at this company.\ndepartment: Usually \"Finance\" or \"Accounting\". Leave blank if unclear.\nseniority: Exactly one of: \"C-Level\", \"VP\", \"Director\", \"Manager\", \"Other\".\nlinkedin_url: Only a real, verified profile URL that shows this company as the current employer. Otherwise \"\".\nemail: Only an explicitly published business email. Otherwise \"\".\nemail_verification_status: Exactly one of: \"Verified\" (email explicitly published in a reliable source) or \"Unverified\" (no email found, or source not reliable). If email is \"\", this must be \"Unverified\".\nphone: Only an explicitly published business phone. Otherwise \"\".\nphone_verification_status: \"Verified\" or \"Unverified\", same rule as email.\nsource_id: Leave blank. The workflow assigns source IDs.\ncontact_confidence: Exactly one of: \"High\", \"Medium\", \"Low\", \"Unknown\". Use \"High\" only when the person's identity AND current role at THIS company (name and domain) are clearly verified.\nprimary_decision_maker: \"Yes\" for the single most relevant finance decision maker. \"No\" for the others.\nbackup_decision_maker: \"Yes\" for the next most relevant. \"No\" otherwise.\ndo_not_contact: \"No\" unless there is explicit public evidence the person should not be contacted. Never guess.\nnotes: Brief factual notes, naming the source AND the exact employer that source gives for the person. Do not fabricate sources.\n\n========================================\nFINAL CHECK BEFORE RETURNING\n========================================\n\nRe-read every person. Keep those you can tie to {{ $('Assign Company ID').first().json['Company Name'] || '' }} at its website domain right now, with a named source. Remove anyone you cannot tie to THIS company. Do not remove a genuine, sourced finance leader at this company.\n\nOUTPUT RULES:\n\n- Return ONLY the JSON object. No Markdown, no code fences, no explanation outside the JSON.\n- Use \"\" for anything not explicitly verified.",
       "role": "user",
       "type": "text"
      }
     ]
    },
    "builtInTools": {
     "webSearch": {
      "searchContextSize": "medium"
     }
    },
    "options": {
     "textFormat": {
      "textOptions": {
       "type": "text"
      }
     }
    }
   },
   "id": "eb0ede69-8021-4189-b463-fdbec3c8335e",
   "name": "Contact Research AI",
   "type": "@n8n/n8n-nodes-langchain.openAi",
   "typeVersion": 2.3,
   "position": [
    928,
    240
   ],
   "credentials": {
    "openAiApi": {
     "id": "Iny8RznkWYiFgD9G",
     "name": "OpenAI account"
    }
   }
  },
  {
   "parameters": {
    "resource": "table",
    "operation": "getRows",
    "workbook": {
     "__rl": true,
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6",
     "mode": "list",
     "cachedResultName": "Grandeur_BD_Agent_V1"
    },
    "worksheet": {
     "__rl": true,
     "value": "{00000000-0001-0000-0300-000000000000}",
     "mode": "list",
     "cachedResultName": "Contacts"
    },
    "table": {
     "__rl": true,
     "value": "{00000000-000C-0000-FFFF-FFFF02000000}",
     "mode": "list",
     "cachedResultName": "tblContacts"
    },
    "returnAll": true,
    "filters": {}
   },
   "id": "7c4f4909-6faa-4659-a31d-a536b9f8bd20",
   "name": "Get Existing Contacts",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1460,
    400
   ],
   "alwaysOutputData": true,
   "executeOnce": true,
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "parameters": {
    "jsCode": "const norm = (v) => (v == null ? '' : String(v)).trim();\nconst lower = (v) => norm(v).toLowerCase();\n\nconst FINANCE_TITLE = /chief financial|cfo\\b|finance|financial|controller|accounting|accountant|treasur|fp&a|bookkeep/;\n\nconst idKey = (v) => {\n  const s = norm(v);\n  if (s === '') return '';\n  if (/^\\d+$/.test(s)) return String(parseInt(s, 10));\n  return s.toLowerCase();\n};\n\n// First and last token only - the research model returns name VARIANTS between\n// runs ('Erica Hanson' vs 'Erica Eaton Hanson'), and a full-name key does not\n// survive an inserted middle name.\nconst nameKey = (v) => {\n  const parts = lower(v).replace(/[^a-z\\s'-]/g, ' ').split(/\\s+/).filter(Boolean);\n  if (!parts.length) return '';\n  return parts.length === 1 ? parts[0] : parts[0] + ' ' + parts[parts.length - 1];\n};\n\nconst existingRows = $input.all()\n  .map(i => i.json)\n  .filter(r => r && norm(r['Contact ID']));\n\nconst src = $('Assign Opportunity ID').first().json;\nconst companyId = norm(src['Company ID']);\nconst today = new Date().toISOString().slice(0, 10);\n\n// Contacts come only from the research model now. It targets the finance\n// decision-makers by name and LinkedIn URL; Findymail Enrich resolves their\n// verified email downstream. The Hunter domain-search bulk source was removed.\nlet aiPeople = [];\ntry {\n  const text = $('Contact Research AI').first().json.output[0].content[0].text;\n  const parsed = JSON.parse(text);\n  const list = Array.isArray(parsed) ? parsed : (parsed.contacts || []);\n  aiPeople = list.map(c => ({\n    name: norm(c.name),\n    title: norm(c.job_title),\n    department: norm(c.department),\n    seniority: norm(c.seniority),\n    linkedin: norm(c.linkedin_url),\n    phone: norm(c.phone),\n    email: norm(c.email),\n    confidence: norm(c.contact_confidence),\n    primary: norm(c.primary_decision_maker),\n    backup: norm(c.backup_decision_maker),\n    dnc: norm(c.do_not_contact),\n    notes: norm(c.notes)\n  })).filter(p => p.name || p.email);\n} catch (e) {\n  aiPeople = [];\n}\n\nconst merged = [];\nconst seen = {};\nconst keyOf = (p) => lower(p.email) || lower(p.name);\n\nfor (const a of aiPeople) {\n  const k = keyOf(a);\n  if (!k || seen[k]) continue;\n  seen[k] = true;\n  merged.push({\n    name: a.name, title: a.title, department: a.department, seniority: a.seniority,\n    linkedin: a.linkedin, phone: a.phone, email: a.email,\n    verification: 'Unverified',\n    confidence: a.confidence, primary: a.primary, backup: a.backup, dnc: a.dnc,\n    notes: a.notes\n  });\n}\n\nif (!merged.length) return [];\n\n// Finance relevance by role, OR an explicit designation from the research stage.\nconst financeRole = (p) =>\n  lower(p.department).indexOf('finance') !== -1 ||\n  FINANCE_TITLE.test(lower(p.title));\n\nconst designated = (p) => lower(p.primary) === 'yes' || lower(p.backup) === 'yes';\nconst qualifies = (p) => financeRole(p) || designated(p);\n\nconst rank = (p) => {\n  let r = 0;\n  if (lower(p.primary) === 'yes') r += 6;\n  if (lower(p.backup) === 'yes') r += 3;\n  if (lower(p.department).indexOf('finance') !== -1) r += 4;\n  if (FINANCE_TITLE.test(lower(p.title))) r += 4;\n  if (lower(p.seniority) === 'executive' || lower(p.seniority) === 'c-level') r += 2;\n  else if (lower(p.seniority) === 'senior' || lower(p.seniority) === 'vp') r += 1;\n  if (p.email) r += 2;\n  if (p.verification === 'Verified') r += 1;\n  return r;\n};\nmerged.sort((a, b) => rank(b) - rank(a));\n\n// Only designate Primary/Backup among contacts that actually qualify.\nconst eligible = merged.filter(qualifies);\nconst primaryKey = eligible.length ? keyOf(eligible[0]) : null;\nconst backupKey = eligible.length > 1 ? keyOf(eligible[1]) : null;\n\n// Four match keys, because the same person never arrives the same way twice.\nconst byEmail = {};\nconst byLinked = {};\nconst byName = {};\nconst byShortName = {};\nfor (const r of existingRows) {\n  const co = idKey(r['Company ID']);\n  if (lower(r['Email'])) byEmail[co + '||' + lower(r['Email'])] = r;\n  if (lower(r['LinkedIn URL'])) byLinked[co + '||' + lower(r['LinkedIn URL'])] = r;\n  if (lower(r['Name'])) byName[co + '||' + lower(r['Name'])] = r;\n  if (nameKey(r['Name'])) byShortName[co + '||' + nameKey(r['Name'])] = r;\n}\n\nlet max = 0;\nfor (const r of existingRows) {\n  const m = norm(r['Contact ID']).match(/(\\d+)\\s*$/);\n  if (m) {\n    const n = parseInt(m[1], 10);\n    if (!isNaN(n) && n > max) max = n;\n  }\n}\n\n// A blank on this run must never erase what an earlier run verified.\nconst keep = (fresh, old) => norm(fresh) || norm(old);\n\nconst out = [];\n\nfor (const p of merged) {\n  const k = keyOf(p);\n  const co = idKey(companyId);\n\n  let matchedRow = null;\n  if (lower(p.email)) matchedRow = byEmail[co + '||' + lower(p.email)] || null;\n  if (!matchedRow && lower(p.linkedin)) matchedRow = byLinked[co + '||' + lower(p.linkedin)] || null;\n  if (!matchedRow && lower(p.name)) matchedRow = byName[co + '||' + lower(p.name)] || null;\n  if (!matchedRow && nameKey(p.name)) matchedRow = byShortName[co + '||' + nameKey(p.name)] || null;\n\n  let contactId, isNew;\n  if (matchedRow) {\n    contactId = matchedRow['Contact ID'];\n    isNew = false;\n  } else {\n    max = max + 1;\n    contactId = max;\n    isNew = true;\n  }\n\n  const old = matchedRow || {};\n  const email = keep(p.email, old['Email']);\n  const verification = norm(p.email)\n    ? p.verification\n    : (norm(old['Email']) ? norm(old['Email Verification Status']) || 'Unverified' : p.verification);\n\n  out.push({ json: {\n    'Contact ID': contactId,\n    'Company ID': companyId,\n    'Name': keep(p.name, old['Name']),\n    'Job Title': keep(p.title, old['Job Title']),\n    'Department': keep(p.department, old['Department']),\n    'Seniority': keep(p.seniority, old['Seniority']),\n    'LinkedIn URL': keep(p.linkedin, old['LinkedIn URL']),\n    'Email': email,\n    'Email Verification Status': verification,\n    'Phone': keep(p.phone, old['Phone']),\n    'Phone Verification Status': 'Unverified',\n    'Source ID': '',\n    'Last Verified': today,\n    'Contact Confidence': p.confidence || (verification === 'Verified' ? 'High' : 'Medium'),\n    'Primary Decision-Maker': (primaryKey && k === primaryKey) ? 'Yes' : 'No',\n    'Backup Decision-Maker': (backupKey && k === backupKey) ? 'Yes' : 'No',\n    'Do Not Contact': p.dnc || norm(old['Do Not Contact']) || 'No',\n    'Notes': keep(p.notes, old['Notes']),\n    'Is New Contact': isNew\n  }});\n}\n\nreturn out;",
    "language": "javaScript",
    "mode": "runOnceForAllItems"
   },
   "id": "603753ec-95c4-42c7-803e-72a552c9a044",
   "name": "Assign Contact IDs",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    1680,
    400
   ]
  },
  {
   "parameters": {
    "resource": "worksheet",
    "operation": "upsert",
    "workbook": {
     "__rl": true,
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6",
     "mode": "list",
     "cachedResultName": "Grandeur_BD_Agent_V1"
    },
    "worksheet": {
     "__rl": true,
     "value": "{00000000-0001-0000-0300-000000000000}",
     "mode": "list",
     "cachedResultName": "Contacts"
    },
    "dataMode": "autoMap",
    "columnToMatchOn": "Contact ID",
    "options": {}
   },
   "id": "7aaf124c-3fda-4cda-a6dd-6b9773322dd5",
   "name": "Upsert Contact",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    2760,
    400
   ],
   "alwaysOutputData": true,
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "parameters": {
    "resource": "table",
    "operation": "getRows",
    "workbook": {
     "__rl": true,
     "cachedResultName": "Grandeur_BD_Agent_V1",
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6"
    },
    "worksheet": {
     "__rl": true,
     "cachedResultName": "Outreach",
     "mode": "list",
     "value": "{00000000-0001-0000-0500-000000000000}"
    },
    "table": {
     "__rl": true,
     "cachedResultName": "Table6",
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF04000000}"
    },
    "returnAll": true,
    "filters": {}
   },
   "id": "0a22b8a4-53a4-449e-86a0-64bddd6bb68d",
   "name": "Get Outreach History",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1248,
    640
   ],
   "alwaysOutputData": true,
   "executeOnce": true,
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "parameters": {
    "jsCode": "const MIN_SCORE = 50;\nconst FRESH_HOURS = 72;\nconst REENGAGE_DAYS = 30;\n\nconst COUNTRY_ALIASES = {\n  'usa': 'USA', 'us': 'USA', 'u.s.': 'USA', 'u.s.a.': 'USA',\n  'united states': 'USA', 'united states of america': 'USA', 'america': 'USA',\n  'uk': 'UK', 'gb': 'UK', 'united kingdom': 'UK', 'great britain': 'UK',\n  'england': 'UK', 'scotland': 'UK', 'wales': 'UK', 'northern ireland': 'UK',\n  'australia': 'Australia',\n  'germany': 'Germany', 'deutschland': 'Germany',\n  'canada': 'Canada',\n  'singapore': 'Singapore',\n  'uae': 'UAE', 'u.a.e.': 'UAE', 'united arab emirates': 'UAE',\n  'dubai': 'UAE', 'abu dhabi': 'UAE',\n  'netherlands': 'Netherlands', 'the netherlands': 'Netherlands', 'holland': 'Netherlands',\n  'ireland': 'Ireland', 'republic of ireland': 'Ireland',\n  'new zealand': 'New Zealand', 'nz': 'New Zealand',\n  'france': 'France',\n  'switzerland': 'Switzerland',\n  'belgium': 'Belgium',\n  'sweden': 'Sweden',\n  'denmark': 'Denmark',\n  'norway': 'Norway',\n  'spain': 'Spain',\n  'italy': 'Italy',\n  'hong kong': 'Hong Kong', 'hongkong': 'Hong Kong', 'hk': 'Hong Kong',\n  'japan': 'Japan',\n  'south korea': 'South Korea', 'korea': 'South Korea',\n  'republic of korea': 'South Korea',\n  'saudi arabia': 'Saudi Arabia', 'ksa': 'Saudi Arabia',\n  'qatar': 'Qatar'\n};\n\nconst FINANCE_TITLE = /chief financial|cfo\\b|finance|financial|controller|accounting|accountant|treasur|fp&a|bookkeep/;\n\nconst norm = (v) => (v == null ? '' : String(v)).trim();\nconst lower = (v) => norm(v).toLowerCase();\n\nconst idKey = (v) => {\n  const s = norm(v);\n  if (s === '') return '';\n  if (/^\\d+$/.test(s)) return String(parseInt(s, 10));\n  return s.toLowerCase();\n};\n\nconst toDate = (v) => {\n  const s = norm(v);\n  if (s === '') return null;\n  if (/^\\d+(\\.\\d+)?$/.test(s)) {\n    const serial = Number(s);\n    if (serial > 20000 && serial < 90000) {\n      return new Date(Math.round((serial - 25569) * 86400000));\n    }\n  }\n  const d = new Date(s);\n  return isNaN(d.getTime()) ? null : d;\n};\n\nconst opp = $('Assign Opportunity ID').first().json;\nconst company = $('Assign Company ID').first().json;\n\nconst companyId = norm(opp['Company ID']);\nconst opportunityId = norm(opp['Opportunity ID']);\n\nconst outreachRows = $('Get Outreach History').all()\n  .map(i => i.json).filter(r => r && norm(r['Outreach ID']));\n\n// Contacts come from two places, and BOTH are needed.\n// This branch used to hang off Assign Opportunity ID, running in parallel with\n// contact discovery, so the sheet read happened before Upsert Contact had written\n// anything. Every company then failed the contact gate on the one run that found\n// its contact, and Pick Next Company would not offer it again for 14 days - so no\n// company ever reached a draft. The branch now runs after Upsert Contact, and the\n// two sources are unioned in case the sheet read still lags the write.\nconst sheetContacts = $('Get Company Contacts').all()\n  .map(i => i.json).filter(r => r && norm(r['Contact ID']));\n\nconst runContacts = $('Upsert Contact').all()\n  .map(i => i.json).filter(r => r && norm(r['Contact ID']));\n\nconst contactsById = {};\nfor (const c of sheetContacts) contactsById[idKey(c['Contact ID'])] = c;\nfor (const c of runContacts) contactsById[idKey(c['Contact ID'])] = c;\nconst allContacts = Object.keys(contactsById).map(k => contactsById[k]);\n\nconst suppression = $('Get Suppression List').all()\n  .map(i => i.json).filter(r => r && norm(r['Suppression ID']));\n\nconst clients = $('Get Clients').all()\n  .map(i => i.json).filter(r => r && norm(r['Record ID']));\n\nconst reasons = [];\n\nconst rawCountry = norm(company['Country']);\nconst matchedCountry = COUNTRY_ALIASES[lower(rawCountry)] || '';\nif (!rawCountry) {\n  reasons.push('Country not verified, cannot confirm the company is in a target market');\n} else if (!matchedCountry) {\n  reasons.push(rawCountry + ' is outside Grandeur target markets');\n}\n\n// Owner rule: Grandeur delivers finance work remotely, so a role that must be done\n// on-site or on a hybrid schedule cannot be served and is blocked outright.\n// Anything else stays in play, including a posting that states no arrangement at\n// all - owner's call, 2026-08-26: silence is far more often remote-tolerant than\n// not, and blocking it discarded too many workable leads. Only an EXPLICIT hybrid\n// or on-site requirement disqualifies.\nconst ARRANGEMENT_RE = /^\\s*WORK ARRANGEMENT:\\s*(Remote|Hybrid|On-?site|Not stated|Not a job posting)\\s*\\|/i;\nconst arrangementMatch = ARRANGEMENT_RE.exec(norm(opp['Evidence Summary']));\nconst workArrangement = arrangementMatch ? arrangementMatch[1] : '';\nconst wa = lower(workArrangement).replace(/-/g, '');\n\nif (wa === 'hybrid' || wa === 'onsite') {\n  reasons.push('Role is ' + workArrangement + ' and Grandeur delivers remotely');\n}\n\nconst suppressedCompany = suppression.find(s =>\n  norm(s['Company ID']) && idKey(s['Company ID']) === idKey(companyId)\n);\nif (suppressedCompany) {\n  reasons.push('Company is suppressed: ' + (norm(suppressedCompany['Reason']) || norm(suppressedCompany['Type']) || 'listed in Suppression'));\n}\n\nconst activeClient = clients.find(c =>\n  norm(c['Company ID']) &&\n  idKey(c['Company ID']) === idKey(companyId) &&\n  ['former', 'inactive', 'churned', 'past'].indexOf(lower(c['Client Status'])) === -1\n);\nif (activeClient) {\n  reasons.push('Company is an existing client' + (norm(activeClient['Client Status']) ? ' (' + norm(activeClient['Client Status']) + ')' : ''));\n}\n\nconst suppressedContactIds = {};\nfor (const s of suppression) {\n  if (norm(s['Contact ID'])) suppressedContactIds[idKey(s['Contact ID'])] = true;\n}\n\nconst companyContacts = allContacts.filter(c => idKey(c['Company ID']) === idKey(companyId));\n\nconst reachable = (c) =>\n  norm(c['Email']).indexOf('@') !== -1 &&\n  lower(c['Do Not Contact']) !== 'yes' &&\n  !suppressedContactIds[idKey(c['Contact ID'])];\n\n// Either the role is plainly finance, or the research stage explicitly designated\n// this person as the decision maker for the accounting need, with justification\n// recorded in Notes. A generic executive with neither is not a valid recipient.\nconst financeRole = (c) =>\n  lower(c['Department']).indexOf('finance') !== -1 ||\n  FINANCE_TITLE.test(lower(c['Job Title']));\n\nconst designated = (c) =>\n  lower(c['Primary Decision-Maker']) === 'yes' ||\n  lower(c['Backup Decision-Maker']) === 'yes';\n\nconst reachableContacts = companyContacts.filter(reachable);\nconst validContacts = reachableContacts.filter(c => financeRole(c) || designated(c));\n\nlet contact = validContacts.find(c => lower(c['Primary Decision-Maker']) === 'yes');\nif (!contact) contact = validContacts.find(c => lower(c['Backup Decision-Maker']) === 'yes');\nif (!contact) contact = validContacts.find(financeRole);\nif (!contact) contact = validContacts[0];\n\nif (!contact) {\n  if (reachableContacts.length) {\n    reasons.push('No finance decision maker identified (' + reachableContacts.length + ' non-finance contacts on file)');\n  } else {\n    reasons.push('No contactable decision maker with a verified email');\n  }\n}\n\nconst score = Number(opp['Opportunity Score'] || 0);\nif (!score || score < MIN_SCORE) {\n  reasons.push('Opportunity score ' + score + ' is below the ' + MIN_SCORE + ' outreach threshold');\n}\n\nconst verifiedAt = toDate(opp['Last Verified']);\nlet hoursOld = null;\nif (verifiedAt) hoursOld = (Date.now() - verifiedAt.getTime()) / 3600000;\nif (hoursOld === null || hoursOld > FRESH_HOURS) {\n  reasons.push('Opportunity not refreshed within the last ' + FRESH_HOURS + ' hours');\n}\n\n// The two guards below are scoped to the COMPANY, not the opportunity.\n// A re-run can mint a fresh Opportunity ID for the same company whenever\n// research words the opportunity differently (Aescape produced both\n// 'Finance / Accounting Outsourcing' and 'Finance Operations'), so an\n// opportunity-scoped guard lets a second email reach the same people.\nlet lastSent = null;\nfor (const r of outreachRows) {\n  if (idKey(r['Company ID']) !== idKey(companyId)) continue;\n  const d = toDate(r['Sent Date']);\n  if (!d) continue;\n  if (lastSent === null || d.getTime() > lastSent) lastSent = d.getTime();\n}\nlet daysSinceLastOutreach = null;\nif (lastSent !== null) {\n  daysSinceLastOutreach = Math.floor((Date.now() - lastSent) / 86400000);\n  if (daysSinceLastOutreach < REENGAGE_DAYS) {\n    reasons.push('This company was last emailed ' + daysSinceLastOutreach + ' days ago (' + REENGAGE_DAYS + '-day minimum)');\n  }\n}\n\nconst pendingDraft = outreachRows.find(r =>\n  idKey(r['Company ID']) === idKey(companyId) &&\n  !norm(r['Sent Date']) &&\n  lower(r['Approval Status']).indexOf('pending') !== -1\n);\nif (pendingDraft) {\n  reasons.push('A draft is already awaiting approval for this company (Outreach ID ' + norm(pendingDraft['Outreach ID']) + ')');\n}\n\nconst eligible = reasons.length === 0;\n\nreturn [{ json: {\n  'Eligible': eligible,\n  'Ineligible Reason': reasons.join(' | '),\n  'Company ID': companyId,\n  'Opportunity ID': opportunityId,\n  'Contact ID': contact ? norm(contact['Contact ID']) : '',\n  'Contact Name': contact ? norm(contact['Name']) : '',\n  'Contact Email': contact ? norm(contact['Email']) : '',\n  'Contact Job Title': contact ? norm(contact['Job Title']) : '',\n  'Company Name': norm(company['Company Name']),\n  'Company Website': norm(company['Website']),\n  'Company Country': rawCountry,\n  'Target Market': matchedCountry || 'OUT OF SCOPE',\n  'Work Arrangement': workArrangement || 'Not reported',\n  'Company Industry': norm(company['Industry']),\n  'Opportunity Type': norm(opp['Opportunity Type']),\n  'Primary Signal': norm(opp['Primary Signal']),\n  'Evidence Summary': norm(opp['Evidence Summary']),\n  'Grandeur Service': norm(opp['Grandeur Service']),\n  'Opportunity Score': score,\n  'Recommended Send Date': norm(opp['Recommended Contact Date']),\n  'Recommended Send Window': norm(opp['Recommended Contact Window']),\n  'Contacts Found For Company': companyContacts.length,\n  'Reachable Contacts': reachableContacts.length,\n  'Valid Contacts': validContacts.length,\n  'Suppression Entries Checked': suppression.length,\n  'Client Records Checked': clients.length,\n  'Days Since Last Outreach': daysSinceLastOutreach,\n  'Hours Since Verified': hoursOld === null ? null : Math.floor(hoursOld)\n}}];",
    "language": "javaScript",
    "mode": "runOnceForAllItems"
   },
   "id": "740ee7c4-4984-4c80-b7b6-62663d09a762",
   "name": "Check Outreach Eligibility",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    1900,
    860
   ]
  },
  {
   "parameters": {
    "conditions": {
     "combinator": "and",
     "conditions": [
      {
       "id": "elig-1",
       "leftValue": "={{ $json.Eligible }}",
       "operator": {
        "operation": "true",
        "singleValue": true,
        "type": "boolean"
       },
       "rightValue": ""
      }
     ],
     "options": {
      "caseSensitive": true,
      "leftValue": "",
      "typeValidation": "loose",
      "version": 2
     }
    },
    "options": {}
   },
   "id": "e437689d-13da-4dca-8497-6d0ce06c83fc",
   "name": "Eligible?",
   "type": "n8n-nodes-base.if",
   "typeVersion": 2.3,
   "position": [
    2120,
    860
   ]
  },
  {
   "parameters": {
    "modelId": {
     "__rl": true,
     "cachedResultName": "CHAT-LATEST",
     "mode": "list",
     "value": "chat-latest"
    },
    "responses": {
     "values": [
      {
       "content": "=You are a senior business development manager at Grandeur Advisors LLP, writing a first-touch outreach email to a finance decision maker who has never heard of Grandeur.\n\nWHO GRANDEUR IS:\n\nGrandeur Advisors LLP is an outsourced finance and accounting firm. It works as an extension of a company's existing finance team, handling bookkeeping, month-end close, financial reporting, AP/AR and day-to-day finance operations, with hands-on support for NetSuite, QuickBooks and Xero. It also provides fractional CFO and interim finance cover, and white-label accounting capacity for recruitment and CPA firms.\n\nWebsite: https://grandeuradvisory.com/\n\nThe firm's name is spelled \"Grandeur Advisors LLP\" - Advisors, never Advisory. The website domain is grandeuradvisory.com, which is not the company name. That description is the ONLY thing you may say about Grandeur. Do not extend it.\n\nWRITE THE EMAIL BASED ONLY ON THIS VERIFIED INFORMATION:\n\nRecipient Name: {{ $json['Contact Name'] }}\nRecipient Title: {{ $json['Contact Job Title'] }}\nCompany: {{ $json['Company Name'] }}\nIndustry: {{ $json['Company Industry'] }}\nOpportunity Type: {{ $json['Opportunity Type'] }}\nVerified Signal: {{ $json['Primary Signal'] }}\nEvidence: {{ $json['Evidence Summary'] }}\nRelevant Grandeur Service: {{ $json['Grandeur Service'] }}\n\nThe Evidence field begins with an internal routing tag such as \"WORK ARRANGEMENT: Remote |\". Ignore that tag completely. Never mention work arrangement, remote working, or hiring logistics in the email.\n\nABSOLUTE RULES:\n\n- Use ONLY the verified information above, plus the description of Grandeur above.\n- Do not invent facts about the company, the person, their systems, their team, or their plans.\n- Do not claim knowledge you were not given. Do not say \"I noticed you use X\" unless X appears above.\n- Do not invent case studies, client names, statistics, percentages, results, or years of experience.\n- Do not name other clients of Grandeur Advisors.\n- Do not state pricing, rates, contract terms, notice periods, team size, turnaround times, or guarantees. None of that is verified.\n- Do not promise specific savings, timelines, or outcomes.\n- If the evidence is thin, write a shorter and more modest email rather than padding it with invention.\n\nTHE EMAIL MUST BE SPECIFIC, NOT GENERIC:\n\nThis is the most important instruction. Apply this test before returning:\n\n  If this email could be sent to a different company by changing only the company\n  name and the person's name, it has FAILED. Rewrite it.\n\nTo pass that test:\n\n- Name the actual work implied by the evidence, in the evidence's own terms. If the signal describes billing, collections and settlement reconciliation, propose exactly that - not \"finance support\".\n- Propose AT MOST THREE specific pieces of work, and every one must be traceable to something in the Evidence. Do not list Grandeur's full service range. Five services reads as a brochure and destroys the specificity.\n- Never use a category word alone - \"solutions\", \"support\", \"services\", \"processes\", \"operations\" - without saying support with what, exactly.\n- Say what Grandeur would actually do for THIS company in THIS situation, not what Grandeur is capable of in general.\n\nHOW TO WRITE THE BODY:\n\n150 to 200 words, in six short paragraphs, in this EXACT order:\n\n1. The greeting line on its own: \"Hi {{ $json['Contact Name'] }},\"\n\n2. A short, warm opening line. ONE sentence, nothing more - for example \"Hope you are doing well.\" or \"Hope the week is going well at {{ $json['Company Name'] }}.\" Do not make it about yourself, do not stack two pleasantries, and do not mention the weather, the time of year, or anything you were not told.\n\n3. THE QUESTION. Ask directly whether they are looking for the thing the verified evidence says they are looking for, in the evidence's own terms. This is the heart of the email and it MUST end in a question mark. The shape to aim for, as illustration only - never copy this content:\n     \"Are you looking for someone to own month-end close and financial reporting in NetSuite as the team grows?\"\n     \"Are you looking to add AP/AR and reconciliation capacity while the Controller search runs?\"\n   If the signal is a job posting, mirror what that posting actually asks the hire to own. If the signal is not a job posting - an ERP migration, a funding round, a new CFO appointment - ask about the finance work the evidence shows they are taking on. Never invent a need the evidence does not state, and never ask about more than the evidence supports.\n\n4. Who Grandeur is. ONE plain sentence, adapted from the description above. This person has never heard of the firm, so say what it does.\n\n5. How Grandeur solves exactly the thing you just asked about. Name the specific work Grandeur would take on - at most three pieces, each traceable to the Evidence - and say how it would work: as an extension of their existing team, or alongside the hire rather than instead of it where the evidence supports that. This paragraph must answer the question in paragraph 3, not change the subject.\n\n6. The close. Include the website link, then a low-friction ask - a short call, or simply whether it is worth a conversation.\n\n- Plain, direct, human. Write like a competent professional emailing a peer, not like marketing copy.\n- No bullet points. No headers. No emojis. No exclamation marks.\n- Do NOT include a signature, sign-off block, or contact details. The sender appends those automatically.\n- The website URL must appear exactly once, written exactly as https://grandeuradvisory.com/ - never shortened, relabelled, hyperlinked, or altered.\n- CRITICAL, how to place the URL: the email is sent as plain text and the recipient's mail client turns the URL into a link itself, so punctuation touching the URL gets absorbed into the link and breaks it. Therefore the URL must sit INSIDE a sentence, never at the end of one. Follow it with a space and then more words, so the sentence's full stop ends up well clear of the link. Correct: \"You can see more at https://grandeuradvisory.com/ if that is useful background.\" Wrong, because punctuation touches the link: \"See more at https://grandeuradvisory.com/.\" Wrong, because the sentence never ends: \"See more at https://grandeuradvisory.com/ Would it be worth a call?\"\n- Banned phrases: \"I hope this email finds you well\", \"reaching out\", \"circle back\", \"touch base\", \"synergy\", \"game-changer\", \"revolutionary\", \"just following up\", \"quick question\", \"in today's fast-paced\", \"leverage\", \"best-in-class\", \"one-stop shop\", \"end-to-end\", \"seamless\".\n\nHOW TO WRITE THE SUBJECT LINE:\n\nThe subject MUST be derived from what the body actually says. Write the body first, then write a subject that honestly describes it.\n\n- 4 to 8 words.\n- Reference the specific signal or the specific work the body proposes.\n- Lower case or sentence case. NEVER all caps.\n- No clickbait, no fake urgency, no \"Re:\" or \"Fwd:\" tricks, no false familiarity.\n- No spam trigger words: free, guarantee, act now, limited time, urgent, offer, discount, cheap, risk-free.\n- No emojis. No exclamation marks. No question mark unless the body genuinely asks that question.\n- It must make sense to someone who has never heard of Grandeur Advisors.\n\nGood subject examples (style only, do not copy):\n\"NetSuite month-end support\"\n\"Finance capacity while you hire\"\n\"Controller search and interim cover\"\n\"Multi-entity close support\"\n\nRETURN ONLY THIS JSON OBJECT:\n\n{\n  \"subject\": \"\",\n  \"body\": \"\"\n}\n\nNo markdown. No code fences. No commentary outside the JSON. The body must be plain text with line breaks between paragraphs."
      }
     ]
    },
    "builtInTools": {},
    "options": {
     "textFormat": {
      "textOptions": {
       "type": "text"
      }
     }
    }
   },
   "id": "de158569-91ec-425b-aad8-b55c8b43ec08",
   "name": "Outreach Draft AI",
   "type": "@n8n/n8n-nodes-langchain.openAi",
   "typeVersion": 2.3,
   "position": [
    2340,
    860
   ],
   "credentials": {
    "openAiApi": {
     "id": "Iny8RznkWYiFgD9G",
     "name": "OpenAI account"
    }
   }
  },
  {
   "parameters": {
    "jsCode": "const rows = $('Get Outreach History').all()\n  .map(i => i.json)\n  .filter(r => r && r['Outreach ID']);\n\nconst gate = $('Check Outreach Eligibility').first().json;\n\nlet text = '';\ntry {\n  text = $('Outreach Draft AI').first().json.output[0].content[0].text;\n} catch (e) {\n  text = '';\n}\n\nlet draft;\ntry {\n  draft = JSON.parse(text);\n} catch (e) {\n  draft = {};\n}\n\nconst subject = String(draft.subject || '').trim();\nconst body = String(draft.body || '').trim();\n\nif (!subject || !body) {\n  return [];\n}\n\nlet max = 0;\nfor (const r of rows) {\n  const m = String(r['Outreach ID']).match(/(\\d+)\\s*$/);\n  if (m) {\n    const n = parseInt(m[1], 10);\n    if (!isNaN(n) && n > max) max = n;\n  }\n}\nconst next = max + 1;\nconst width = Math.max(3, String(next).length);\nconst outreachId = String(next).padStart(width, '0');\n\nconst today = new Date().toISOString().slice(0, 10);\n\nreturn [{ json: {\n  'Outreach ID': outreachId,\n  'Company ID': gate['Company ID'] || '',\n  'Opportunity ID': gate['Opportunity ID'] || '',\n  'Contact ID': gate['Contact ID'] || '',\n  'Channel': 'Email',\n  'Approval Status': 'Pending Approval',\n  'Draft Status': 'Drafted',\n  'Subject': subject,\n  'Draft/Message': body,\n  'Recommended Send Date': gate['Recommended Send Date'] || today,\n  'Recommended Send Window': gate['Recommended Send Window'] || '',\n  'Sent Date': '',\n  'Follow-Up Date': '',\n  'Follow-Up Plan': '',\n  'Outreach Status': 'Draft',\n  'Notes': 'Drafted ' + today + ' | To: ' + (gate['Contact Name'] || '') + ' <' + (gate['Contact Email'] || '') + '> | Signal: ' + (gate['Primary Signal'] || '')\n}}];"
   },
   "id": "0f0919d9-e344-4885-8267-ae12e733391c",
   "name": "Build Outreach Row",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    2560,
    860
   ]
  },
  {
   "parameters": {
    "dataMode": "autoMap",
    "operation": "append",
    "options": {},
    "resource": "table",
    "table": {
     "__rl": true,
     "cachedResultName": "Table6",
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF04000000}"
    },
    "workbook": {
     "__rl": true,
     "cachedResultName": "Grandeur_BD_Agent_V1",
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6"
    },
    "worksheet": {
     "__rl": true,
     "cachedResultName": "Outreach",
     "mode": "list",
     "value": "{00000000-0001-0000-0500-000000000000}"
    }
   },
   "id": "de1c3d40-d4c4-4d38-8428-c2c4a99c8766",
   "name": "Append Outreach Draft",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    2780,
    860
   ],
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "7d8aebbd-1ff4-4cb4-8438-8766bd35c35f",
   "name": "Get Company Contacts",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1240,
    860
   ],
   "parameters": {
    "filters": {},
    "operation": "getRows",
    "rawData": false,
    "resource": "table",
    "returnAll": true,
    "table": {
     "__rl": true,
     "cachedResultName": "tblContacts",
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF02000000}"
    },
    "workbook": {
     "__rl": true,
     "cachedResultName": "Grandeur_BD_Agent_V1",
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6"
    },
    "worksheet": {
     "__rl": true,
     "cachedResultName": "Contacts",
     "mode": "list",
     "value": "{00000000-0001-0000-0300-000000000000}"
    }
   },
   "alwaysOutputData": true,
   "executeOnce": true,
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "9fc78035-bd7b-4918-91e9-adc0e7a136ce",
   "name": "Get Suppression List",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1460,
    860
   ],
   "parameters": {
    "filters": {},
    "operation": "getRows",
    "rawData": false,
    "resource": "table",
    "returnAll": true,
    "table": {
     "__rl": true,
     "cachedResultName": "tblSuppression",
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF06000000}"
    },
    "workbook": {
     "__rl": true,
     "cachedResultName": "Grandeur_BD_Agent_V1",
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6"
    },
    "worksheet": {
     "__rl": true,
     "cachedResultName": "Suppression",
     "mode": "list",
     "value": "{00000000-0001-0000-0700-000000000000}"
    }
   },
   "alwaysOutputData": true,
   "executeOnce": true,
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "bf4f9e5f-10d5-4cc0-9522-7d38c08b72bc",
   "name": "Get Clients",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1680,
    860
   ],
   "parameters": {
    "filters": {},
    "operation": "getRows",
    "rawData": false,
    "resource": "table",
    "returnAll": true,
    "table": {
     "__rl": true,
     "cachedResultName": "tblClients",
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF07000000}"
    },
    "workbook": {
     "__rl": true,
     "cachedResultName": "Grandeur_BD_Agent_V1",
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6"
    },
    "worksheet": {
     "__rl": true,
     "cachedResultName": "Clients",
     "mode": "list",
     "value": "{00000000-0001-0000-0800-000000000000}"
    }
   },
   "alwaysOutputData": true,
   "executeOnce": true,
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "c66cb9de-f478-4c8a-966c-3166df688d2d",
   "name": "Get Existing Signals",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1240,
    1120
   ],
   "parameters": {
    "filters": {},
    "operation": "getRows",
    "rawData": false,
    "resource": "table",
    "returnAll": true,
    "table": {
     "__rl": true,
     "cachedResultName": "tblSignals",
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF03000000}"
    },
    "workbook": {
     "__rl": true,
     "cachedResultName": "Grandeur_BD_Agent_V1",
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6"
    },
    "worksheet": {
     "__rl": true,
     "cachedResultName": "Signals",
     "mode": "list",
     "value": "{00000000-0001-0000-0400-000000000000}"
    }
   },
   "alwaysOutputData": true,
   "executeOnce": true,
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "9a6d8bc6-c6b5-4b85-8c9a-48dafe5f8d44",
   "name": "Assign Signal ID",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    1460,
    1120
   ],
   "parameters": {
    "jsCode": "const norm = (v) => (v == null ? '' : String(v)).trim();\nconst lower = (v) => norm(v).toLowerCase();\n\nconst idKey = (v) => {\n  const s = norm(v);\n  if (s === '') return '';\n  if (/^\\d+$/.test(s)) return String(parseInt(s, 10));\n  return s.toLowerCase();\n};\n\nconst rows = $input.all()\n  .map(i => i.json)\n  .filter(r => r && norm(r['Signal ID']));\n\nconst opp = $('Assign Opportunity ID').first().json;\n\nconst companyId = norm(opp['Company ID']);\nconst opportunityId = norm(opp['Opportunity ID']);\nconst description = norm(opp['Primary Signal']);\nconst strength = norm(opp['Signal Strength']);\n\n// No verified signal means there is nothing to record as evidence.\nif (!description || lower(strength) === 'none') {\n  return [];\n}\n\nconst today = new Date().toISOString().slice(0, 10);\nconst matchKey = idKey(companyId) + '||' + idKey(opportunityId);\n\nlet matched = null;\nfor (const r of rows) {\n  if (idKey(r['Company ID']) + '||' + idKey(r['Opportunity ID']) === matchKey) {\n    matched = r;\n    break;\n  }\n}\n\nlet signalId, firstDetected;\n\nif (matched) {\n  signalId = norm(matched['Signal ID']);\n  firstDetected = norm(matched['First Detected']) || today;\n} else {\n  let max = 0;\n  for (const r of rows) {\n    const m = norm(r['Signal ID']).match(/(\\d+)\\s*$/);\n    if (m) {\n      const n = parseInt(m[1], 10);\n      if (!isNaN(n) && n > max) max = n;\n    }\n  }\n  const next = max + 1;\n  const width = Math.max(3, String(next).length);\n  signalId = String(next).padStart(width, '0');\n  firstDetected = norm(opp['First Detected']) || today;\n}\n\nreturn [{ json: {\n  'Signal ID': signalId,\n  'Company ID': companyId,\n  'Opportunity ID': opportunityId,\n  'Signal Type': norm(opp['Opportunity Type']),\n  'Signal Description': description,\n  'Signal Strength': strength,\n  'First Detected': firstDetected,\n  'Last Verified': today,\n  'Expected Deadline': norm(opp['Expected Deadline']),\n  'Evidence': norm(opp['Evidence Summary']),\n  'Source ID': '',\n  'Verification Status': 'Verified',\n  'Confidence': strength,\n  'Status': 'Active'\n}}];",
    "language": "javaScript",
    "mode": "runOnceForAllItems"
   }
  },
  {
   "id": "7c45460d-81e0-4ef9-94be-4d4408fe903a",
   "name": "Upsert Signal",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1680,
    1120
   ],
   "parameters": {
    "columnToMatchOn": "Signal ID",
    "dataMode": "autoMap",
    "operation": "upsert",
    "options": {},
    "resource": "worksheet",
    "workbook": {
     "__rl": true,
     "cachedResultName": "Grandeur_BD_Agent_V1",
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6"
    },
    "worksheet": {
     "__rl": true,
     "cachedResultName": "Signals",
     "mode": "list",
     "value": "{00000000-0001-0000-0400-000000000000}"
    }
   },
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "281d077e-8165-4847-9e56-3bacca397d21",
   "name": "Has Email?",
   "type": "n8n-nodes-base.if",
   "typeVersion": 2.3,
   "position": [
    1860,
    400
   ],
   "parameters": {
    "conditions": {
     "combinator": "and",
     "conditions": [
      {
       "id": "has-email-1",
       "leftValue": "={{ $json['Email'] }}",
       "operator": {
        "operation": "notEmpty",
        "singleValue": true,
        "type": "string"
       },
       "rightValue": ""
      }
     ],
     "options": {
      "caseSensitive": true,
      "leftValue": "",
      "typeValidation": "loose",
      "version": 2
     }
    },
    "options": {}
   }
  },
  {
   "id": "940bc731-ac55-4621-a17c-5a7245ddee83",
   "name": "Merge Contacts",
   "type": "n8n-nodes-base.merge",
   "typeVersion": 3.2,
   "position": [
    2580,
    400
   ],
   "parameters": {
    "mode": "append",
    "numberInputs": 2
   }
  },
  {
   "id": "2990a816-8a7d-4432-89dc-578ff57d8ab2",
   "name": "Scheduled Intake",
   "type": "n8n-nodes-base.scheduleTrigger",
   "typeVersion": 1.3,
   "position": [
    0,
    460
   ],
   "parameters": {
    "rule": {
     "interval": [
      {
       "field": "cronExpression",
       "expression": "30 9-21 * * *"
      }
     ]
    }
   }
  },
  {
   "id": "18bb5e15-db95-492e-8bb2-b87296d1904c",
   "name": "Get Research Queue",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    220,
    460
   ],
   "parameters": {
    "resource": "table",
    "operation": "getRows",
    "returnAll": true,
    "rawData": false,
    "filters": {},
    "workbook": {
     "__rl": true,
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6",
     "cachedResultName": "Grandeur_BD_Agent_V1"
    },
    "worksheet": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-0001-0000-0100-000000000000}",
     "cachedResultName": "Companies"
    },
    "table": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF00000000}",
     "cachedResultName": "tblCompanies"
    }
   },
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "alwaysOutputData": true,
   "executeOnce": true,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "e8e1fc15-6795-4471-af2b-a21199ae1edd",
   "name": "Pick Next Company",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    440,
    460
   ],
   "parameters": {
    "mode": "runOnceForAllItems",
    "language": "javaScript",
    "jsCode": "// Automatic intake: selects exactly ONE company per run.\n//\n// One at a time is deliberate, not a simplification. Every lookup node\n// downstream - Get Existing Companies, Get Existing Opportunities,\n// Get Existing Contacts, Get Existing Signals, Get Outreach History - is\n// marked executeOnce. In a multi-company batch each would read its table once\n// at the start of the run and never see rows appended mid-run, which would\n// hand the same Company ID or Opportunity ID to two different companies.\n// Running one company per tick and scheduling more often avoids that entirely.\n\n// Hard floor on re-research. Company Research writes a Next Research Date, and\n// without a floor a badly set date re-researches the same company every tick\n// and burns OpenAI credit re-deriving data already on file.\nconst MIN_DAYS_BETWEEN_RESEARCH = 14;\n\nconst SKIP_STATUS = ['excluded', 'suppressed', 'do not contact', 'client', 'closed', 'disqualified'];\n\nconst norm = (v) => (v == null ? '' : String(v)).trim();\nconst lower = (v) => norm(v).toLowerCase();\n\n// Excel returns dates as serial numbers (days since 1899-12-30), not strings.\n// new Date(46260) yields 1970 and would make every company look overdue.\nconst toDate = (v) => {\n  const s = norm(v);\n  if (s === '') return null;\n  if (/^\\d+(\\.\\d+)?$/.test(s)) {\n    const serial = Number(s);\n    if (serial > 20000 && serial < 90000) {\n      return new Date(Math.round((serial - 25569) * 86400000));\n    }\n  }\n  const d = new Date(s);\n  return isNaN(d.getTime()) ? null : d;\n};\n\nconst DAY = 86400000;\nconst now = Date.now();\n\nconst rows = $input.all()\n  .map(i => i.json)\n  .filter(r => r && norm(r['Company Name']) && norm(r['Website']));\n\nconst candidates = [];\n\nfor (const r of rows) {\n  if (SKIP_STATUS.indexOf(lower(r['Company Status'])) !== -1) continue;\n\n  // Next Research Date is a deliberate deferral and outranks everything below,\n  // INCLUDING the never-researched fast path. The contact gate defers exactly\n  // those rows: discovery found the company, Hunter found no email at its\n  // domain, so research never ran and Last Researched is still blank. Checking\n  // this only in the already-researched branch - as it was - would re-pick a\n  // deferred company on the very next tick, forever, which is the one outcome\n  // the gate exists to prevent.\n  const nextDue = toDate(r['Next Research Date']);\n  if (nextDue !== null && nextDue.getTime() > now) continue;\n\n  const lastResearched = toDate(r['Last Researched']);\n\n  // Never researched - straight to the front of the queue.\n  if (lastResearched === null) {\n    candidates.push({ row: r, priority: 0, daysSince: null });\n    continue;\n  }\n\n  const daysSince = Math.floor((now - lastResearched.getTime()) / DAY);\n  if (daysSince < MIN_DAYS_BETWEEN_RESEARCH) continue;\n\n  candidates.push({ row: r, priority: 1, daysSince: daysSince });\n}\n\nif (!candidates.length) {\n  // Nothing due. Returning zero items stops the run here - a node with no input\n  // does not execute in n8n - and the next scheduled tick looks again. This is\n  // the normal idle state, not a failure.\n  return [];\n}\n\n// New companies first, then the most overdue.\ncandidates.sort((a, b) => {\n  if (a.priority !== b.priority) return a.priority - b.priority;\n  return (b.daysSince || 0) - (a.daysSince || 0);\n});\n\nconst picked = candidates[0].row;\n\n// Emit exactly the six field names the research chain already reads, so nothing\n// downstream needed changing to accept a queued company instead of a typed one.\nreturn [{ json: {\n  'Company Name': norm(picked['Company Name']),\n  'website': norm(picked['Website']),\n  'country': norm(picked['Country']),\n  'industry': norm(picked['Industry']),\n  'company_type': norm(picked['Company Type']),\n  'revenue': Number(picked['Revenue']) || 0\n} }];"
   }
  },
  {
   "id": "25cf4e92-81bb-48ff-9c96-f42c7a2c2bb2",
   "name": "Normalize Domain",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    640,
    240
   ],
   "parameters": {
    "mode": "runOnceForAllItems",
    "language": "javaScript",
    "jsCode": "const norm = (v) => (v == null ? '' : String(v)).trim();\n\nconst domainOf = (w) => {\n  let s = norm(w).toLowerCase().replace(/^https?:\\/\\//, '').replace(/^www\\./, '');\n  return s.split('/')[0].split('?')[0].split('#')[0].trim();\n};\n\n// Both entry points - the scheduled queue and the manual test input - emit the\n// same six lowercase keys, so this node accepts either and adds the domain that\n// Hunter needs. The domain is derivable without any AI call, which is the whole\n// reason the enrichment lookup can run before the expensive stages.\nconst out = [];\nfor (const item of $input.all()) {\n  const c = item.json || {};\n  const website = norm(c['website'] || c['Website']);\n  out.push({ json: {\n    'Company Name': norm(c['Company Name']),\n    'website': website,\n    'country': norm(c['country'] || c['Country']),\n    'industry': norm(c['industry'] || c['Industry']),\n    'company_type': norm(c['company_type'] || c['Company Type']),\n    'revenue': Number(c['revenue'] || c['Revenue']) || 0,\n    'domain': domainOf(website)\n  }});\n}\nreturn out;"
   }
  },
  {
   "id": "413704ef-813a-4b11-a22e-23e46fae5741",
   "name": "Findymail Enrich",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    2200,
    560
   ],
   "parameters": {
    "language": "javaScript",
    "mode": "runOnceForAllItems",
    "jsCode": "const KEY = 'Bearer <<FINDYMAIL_API_KEY>>';\nconst NAME_URL = 'https://app.findymail.com/api/search/name';\nconst LINKEDIN_URL = 'https://app.findymail.com/api/search/linkedin';\n\nconst helpers = this.helpers;\nconst norm = (v) => (v == null ? '' : String(v)).trim();\nconst domainOf = (w) => {\n  let s = norm(w).toLowerCase().replace(/^https?:\\/\\//, '').replace(/^www\\./, '');\n  return s.split('/')[0].split('?')[0].split('#')[0].trim();\n};\nconst isLinkedIn = (u) => /linkedin\\.com\\/in\\//i.test(norm(u));\n\nconst company = $('Assign Company ID').first().json;\nconst domain = domainOf(company['Website']);\n\nasync function findymail(url, body) {\n  try {\n    const res = await helpers.httpRequest({\n      method: 'POST',\n      url: url,\n      headers: { Authorization: KEY, 'Content-Type': 'application/json', Accept: 'application/json' },\n      body: body,\n      json: true,\n      returnFullResponse: true,\n      ignoreHttpStatusErrors: true,\n      timeout: 20000\n    });\n    const status = Number(res.statusCode) || 0;\n    const contact = (res && res.body && res.body.contact) ? res.body.contact : null;\n    return { status: status, contact: contact };\n  } catch (e) {\n    return { status: 0, contact: null };\n  }\n}\n\nconst out = [];\nfor (const item of $input.all()) {\n  const c = Object.assign({}, item.json);\n  const name = norm(c['Name']);\n  const li = norm(c['LinkedIn URL']);\n\n  let found = null;\n  let via = '';\n\n  // 1) LinkedIn URL first - highest accuracy\n  if (isLinkedIn(li)) {\n    const r = await findymail(LINKEDIN_URL, { linkedin_url: li });\n    if (r.contact && norm(r.contact.email).indexOf('@') !== -1) { found = r.contact; via = 'LinkedIn URL'; }\n  }\n\n  // 2) Fallback: name + company domain\n  if (!found && name && domain) {\n    const r = await findymail(NAME_URL, { name: name, domain: domain });\n    if (r.contact && norm(r.contact.email).indexOf('@') !== -1) { found = r.contact; via = 'name + domain'; }\n  }\n\n  if (found) {\n    c['Email'] = norm(found.email);\n    c['Email Verification Status'] = 'Verified';\n    if (!norm(c['Job Title']) && norm(found.job_title)) c['Job Title'] = norm(found.job_title);\n    if (!norm(c['LinkedIn URL']) && norm(found.linkedin_url)) c['LinkedIn URL'] = norm(found.linkedin_url);\n    const note = 'Email found via Findymail (' + via + ')';\n    c['Notes'] = norm(c['Notes']) ? norm(c['Notes']) + ' | ' + note : note;\n  }\n\n  out.push({ json: c });\n}\nreturn out;"
   }
  }
 ],
 "connections": {
  "When clicking ‘Execute workflow’": {
   "main": [
    [
     {
      "node": "Test Company Input",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Company Research AI": {
   "main": [
    [
     {
      "node": "Normalize Research Output",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Opportunity Research": {
   "main": [
    [
     {
      "node": "Map Opportunity Output",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Normalize Research Output": {
   "main": [
    [
     {
      "node": "Get Existing Companies",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Get Existing Companies": {
   "main": [
    [
     {
      "node": "Assign Company ID",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Assign Company ID": {
   "main": [
    [
     {
      "node": "Upsert Company",
      "type": "main",
      "index": 0
     },
     {
      "node": "Opportunity Research",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Map Opportunity Output": {
   "main": [
    [
     {
      "node": "Get Existing Opportunities",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Get Existing Opportunities": {
   "main": [
    [
     {
      "node": "Assign Opportunity ID",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Assign Opportunity ID": {
   "main": [
    [
     {
      "node": "Upsert Opportunity",
      "type": "main",
      "index": 0
     },
     {
      "node": "Contact Research AI",
      "type": "main",
      "index": 0
     },
     {
      "node": "Get Existing Signals",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Get Existing Contacts": {
   "main": [
    [
     {
      "node": "Assign Contact IDs",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Check Outreach Eligibility": {
   "main": [
    [
     {
      "node": "Eligible?",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Eligible?": {
   "main": [
    [
     {
      "node": "Outreach Draft AI",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Outreach Draft AI": {
   "main": [
    [
     {
      "node": "Build Outreach Row",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Build Outreach Row": {
   "main": [
    [
     {
      "node": "Append Outreach Draft",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Get Company Contacts": {
   "main": [
    [
     {
      "node": "Get Outreach History",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Get Outreach History": {
   "main": [
    [
     {
      "node": "Get Suppression List",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Get Suppression List": {
   "main": [
    [
     {
      "node": "Get Clients",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Get Clients": {
   "main": [
    [
     {
      "node": "Check Outreach Eligibility",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Get Existing Signals": {
   "main": [
    [
     {
      "node": "Assign Signal ID",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Assign Signal ID": {
   "main": [
    [
     {
      "node": "Upsert Signal",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Assign Contact IDs": {
   "main": [
    [
     {
      "node": "Has Email?",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Has Email?": {
   "main": [
    [
     {
      "node": "Merge Contacts",
      "type": "main",
      "index": 0
     }
    ],
    [
     {
      "node": "Findymail Enrich",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Merge Contacts": {
   "main": [
    [
     {
      "node": "Upsert Contact",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Scheduled Intake": {
   "main": [
    [
     {
      "node": "Get Research Queue",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Get Research Queue": {
   "main": [
    [
     {
      "node": "Pick Next Company",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Upsert Contact": {
   "main": [
    [
     {
      "node": "Get Company Contacts",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Pick Next Company": {
   "main": [
    [
     {
      "node": "Normalize Domain",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Test Company Input": {
   "main": [
    [
     {
      "node": "Normalize Domain",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Normalize Domain": {
   "main": [
    [
     {
      "node": "Company Research AI",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Contact Research AI": {
   "main": [
    [
     {
      "node": "Get Existing Contacts",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Findymail Enrich": {
   "main": [
    [
     {
      "node": "Merge Contacts",
      "type": "main",
      "index": 1
     }
    ]
   ]
  }
 },
 "settings": {
  "executionOrder": "v1",
  "binaryMode": "separate",
  "timeSavedMode": "fixed",
  "callerPolicy": "workflowsFromSameOwner",
  "timezone": "Asia/Kolkata"
 },
 "meta": {
  "originalId": "jIghxNOFdVshn2d3",
  "exportedAt": "2026-11-20"
 }
}
```

### A3. Grandeur BD Agent - Outreach Sender (`sEaRV2WFAshZ9uFu`)

```json
{
 "name": "Grandeur BD Agent - Outreach Sender",
 "nodes": [
  {
   "id": "bddae91a-48c6-4a06-87a9-b5c0d194885c",
   "name": "Check For Approvals",
   "type": "n8n-nodes-base.scheduleTrigger",
   "typeVersion": 1.3,
   "position": [
    0,
    0
   ],
   "parameters": {
    "rule": {
     "interval": [
      {
       "expression": "*/10 15-23 * * 1-5",
       "field": "cronExpression"
      },
      {
       "expression": "*/10 0-1 * * 2-6",
       "field": "cronExpression"
      }
     ]
    }
   }
  },
  {
   "id": "f6099d3a-4685-4391-84ed-58a38760b68b",
   "name": "Get Outreach Rows",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    240,
    0
   ],
   "parameters": {
    "filters": {},
    "operation": "getRows",
    "rawData": false,
    "resource": "table",
    "returnAll": true,
    "table": {
     "__rl": true,
     "cachedResultName": "Table6",
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF04000000}"
    },
    "workbook": {
     "__rl": true,
     "cachedResultName": "Grandeur_BD_Agent_V1",
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6"
    },
    "worksheet": {
     "__rl": true,
     "cachedResultName": "Outreach",
     "mode": "list",
     "value": "{00000000-0001-0000-0500-000000000000}"
    }
   },
   "alwaysOutputData": true,
   "executeOnce": true,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "a07d3bfe-e7df-4896-8db8-c430ae736ed6",
   "name": "Get Contacts",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    480,
    0
   ],
   "parameters": {
    "filters": {},
    "operation": "getRows",
    "rawData": false,
    "resource": "table",
    "returnAll": true,
    "table": {
     "__rl": true,
     "cachedResultName": "tblContacts",
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF02000000}"
    },
    "workbook": {
     "__rl": true,
     "cachedResultName": "Grandeur_BD_Agent_V1",
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6"
    },
    "worksheet": {
     "__rl": true,
     "cachedResultName": "Contacts",
     "mode": "list",
     "value": "{00000000-0001-0000-0300-000000000000}"
    }
   },
   "alwaysOutputData": true,
   "executeOnce": true,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "cb7ae220-ebef-4508-bc0d-0c340e17850c",
   "name": "Build Send Queue",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    720,
    0
   ],
   "parameters": {
    "jsCode": "const contacts = $input.all()\n  .map(i => i.json)\n  .filter(r => r && String(r['Contact ID'] || '').trim());\n\nconst outreach = $('Get Outreach Rows').all()\n  .map(i => i.json)\n  .filter(r => r && String(r['Outreach ID'] || '').trim());\n\nconst norm = (v) => (v == null ? '' : String(v)).trim();\nconst lower = (v) => norm(v).toLowerCase();\n\n// Excel silently converts \"001\" to the number 1, so compare IDs on a\n// canonical form: pure digits collapse to their integer value.\nconst idKey = (v) => {\n  const s = norm(v);\n  if (s === '') return '';\n  if (/^\\d+$/.test(s)) return String(parseInt(s, 10));\n  return s.toLowerCase();\n};\n\nconst hasValue = (v) => norm(v) !== '';\n\n// ---------------------------------------------------------------------------\n// HTML body construction\n//\n// The email is sent as HTML so the signature can carry the logo and linked text.\n// That makes converting the draft mandatory rather than optional: the AI writes\n// plain text with blank lines between paragraphs, and HTML collapses every\n// newline to a single space. Sent raw, a carefully structured six-paragraph\n// email would arrive as one unbroken block.\n// ---------------------------------------------------------------------------\n\nconst escapeHtml = (s) => String(s)\n  .replace(/&/g, '&amp;')\n  .replace(/</g, '&lt;')\n  .replace(/>/g, '&gt;')\n  .replace(/\"/g, '&quot;');\n\n// Turn bare URLs into real anchors. The trailing character class deliberately\n// excludes sentence punctuation, so a full stop after a link stays outside the\n// href - the same trap that broke the body link when it was plain text.\nconst linkify = (s) => s.replace(\n  /(https?:\\/\\/[^\\s<]*[^\\s<.,;:!?)\\]])/g,\n  '<a href=\"$1\" style=\"color:#1155cc;\">$1</a>'\n);\n\nconst toHtmlBody = (text) => linkify(escapeHtml(text)).replace(/\\n/g, '<br>');\n\n// The owner's signature. Built here rather than in Outlook: an Outlook signature\n// is applied by the Outlook client when a human composes, while this workflow\n// posts through the Graph sendMail API, which appends nothing.\n//\n// The logo is a hosted image on the company's own domain - not a data URI, which\n// mail clients strip, and not a third-party host, whose URLs rotate and whose\n// hotlink protection would silently turn the signature into a broken box weeks\n// later. It carries alt text so a recipient whose client blocks images (most of\n// them, by default) still reads the firm name instead of seeing an empty gap.\n//\n// Website, LinkedIn and Instagram are plain text links by the owner's decision:\n// icon images would need three more hosted files and would be blocked in exactly\n// the same way, on the one email where that looks worst.\n//\n// The address below MUST match the sending address. It read accounting@ until\n// 2026-09-03, when sending moved to info@ so that replies land in the mailbox\n// reply detection polls. Leaving the two different would have split replies in\n// two: Reply reaches info@ and is detected, clicking the signature reaches\n// accounting@ and is invisible to both the Responses sheet and the follow-up\n// suppression that stops us chasing someone who already answered.\nconst LOGO_URL = 'https://grandeuradvisory.com/images/Grandeur-Advisors-Logo.png';\nconst CONTACT_EMAIL = 'info@grandeuradvisory.com';\n\nconst SIGNATURE_HTML = [\n  '<br>',\n  '<div style=\"font-family:Arial,Helvetica,sans-serif;font-size:13px;line-height:1.5;color:#333333;\">',\n  '<div style=\"border-top:1px solid #dddddd;width:280px;margin:14px 0 12px 0;\"></div>',\n  '<div style=\"margin-bottom:8px;\">',\n  '<a href=\"https://grandeuradvisory.com/\" style=\"text-decoration:none;\">',\n  '<img src=\"' + LOGO_URL + '\" alt=\"Grandeur Advisors LLP\" width=\"110\" style=\"display:block;border:0;outline:none;width:110px;height:auto;\">',\n  '</a>',\n  '</div>',\n  '<div><span style=\"font-size:15px;font-weight:bold;color:#111111;\">Yash Bhutada</span></div>',\n  '<div style=\"color:#666666;\">CEO &amp; Founder</div>',\n  '<div style=\"font-weight:bold;color:#111111;\">Grandeur Advisors LLP</div>',\n  '<div style=\"margin-top:6px;\">',\n  '<a href=\"mailto:' + CONTACT_EMAIL + '\" style=\"color:#1155cc;text-decoration:none;\">' + CONTACT_EMAIL + '</a>',\n  '</div>',\n  '<div style=\"margin-top:8px;\">',\n  '<a href=\"https://grandeuradvisory.com/\" style=\"color:#1155cc;text-decoration:none;\">Website</a>',\n  '<span style=\"color:#bbbbbb;\">&nbsp;&nbsp;|&nbsp;&nbsp;</span>',\n  '<a href=\"https://www.linkedin.com/in/ca-yash-radheshyam-bhutada-223ab1100/\" style=\"color:#1155cc;text-decoration:none;\">LinkedIn</a>',\n  '<span style=\"color:#bbbbbb;\">&nbsp;&nbsp;|&nbsp;&nbsp;</span>',\n  '<a href=\"https://www.instagram.com/grandeuradvisorsllp/\" style=\"color:#1155cc;text-decoration:none;\">Instagram</a>',\n  '</div>',\n  '</div>'\n].join('');\n\n// Owner rule: emails leave at 10-minute intervals, never in a burst. The schedule\n// polls every 10 minutes and each run sends at most one email, so a backlog of\n// approved drafts drains one at a time instead of arriving together. This protects\n// sending reputation on the grandeuradvisory.com domain - a batch of cold emails\n// leaving in one second is the single clearest spam signal a mail provider sees.\nconst SEND_BATCH_SIZE = 1;\n\n// Owner rule: outbound email only between 15:00 and 02:00 IST, Monday to Friday.\n// The window spans midnight on purpose, so 00:00-01:59 on Tue-Sat is the tail of\n// the previous weekday evening and is allowed; Sunday, and Monday before 15:00,\n// are not. Research and discovery run all seven days, but SENDING is still\n// weekdays only - that rule was set separately and has not been changed.\n//\n// $now is Luxon in the workflow timezone, which is pinned to Asia/Kolkata on this\n// workflow. The container clock is UTC, so new Date() must never be used here or\n// for the send date - between 18:30 and 00:00 IST it reports the previous day.\nconst SEND_START_HOUR = 15;\nconst SEND_END_HOUR = 2;\n\nconst weekday = $now.weekday; // 1 = Monday ... 7 = Sunday\nconst hour = $now.hour;\n\nconst eveningLeg = weekday >= 1 && weekday <= 5 && hour >= SEND_START_HOUR;\nconst afterMidnightLeg = weekday >= 2 && weekday <= 6 && hour < SEND_END_HOUR;\n\nif (!eveningLeg && !afterMidnightLeg) {\n  // Outside the window: queue nothing. A node with zero input items does not\n  // execute in n8n, so the Outlook node cannot fire however this workflow was\n  // started - scheduled, manual, or re-run.\n  return [];\n}\n\nconst today = $now.toFormat('yyyy-LL-dd');\n\nconst contactById = {};\nfor (const c of contacts) {\n  contactById[idKey(c['Contact ID'])] = c;\n}\n\nconst queue = [];\n\nfor (const row of outreach) {\n  if (lower(row['Approval Status']) !== 'approved') continue;\n  if (hasValue(row['Sent Date'])) continue;\n\n  const subject = norm(row['Subject']);\n  const body = norm(row['Draft/Message']);\n  if (!subject || !body) continue;\n\n  const contact = contactById[idKey(row['Contact ID'])];\n  if (!contact) continue;\n\n  const email = norm(contact['Email']);\n  if (!email || email.indexOf('@') === -1) continue;\n  if (lower(contact['Do Not Contact']) === 'yes') continue;\n\n  queue.push({ json: {\n    'Outreach ID': norm(row['Outreach ID']),\n    'Company ID': norm(row['Company ID']),\n    'Opportunity ID': norm(row['Opportunity ID']),\n    'Contact ID': norm(row['Contact ID']),\n    'Recipient Name': norm(contact['Name']),\n    'Recipient Email': email,\n    'Subject': subject,\n    // The approved wording is sent verbatim; only markup and the signature are added.\n    'Body': toHtmlBody(body) + SIGNATURE_HTML,\n    'Send Date': today,\n    'Queue Depth': 0\n  }});\n}\n\n// Record how many approved drafts were waiting, so a run makes the backlog visible\n// rather than silently sending one of many.\nfor (const item of queue) item.json['Queue Depth'] = queue.length;\n\nreturn queue.slice(0, SEND_BATCH_SIZE);",
    "language": "javaScript",
    "mode": "runOnceForAllItems"
   }
  },
  {
   "id": "9c64fb0b-be32-4553-8eaf-13a87fe5491f",
   "name": "Create Draft",
   "type": "n8n-nodes-base.microsoftOutlook",
   "typeVersion": 2,
   "position": [
    960,
    0
   ],
   "parameters": {
    "additionalFields": {
     "bodyContentType": "html",
     "from": "info@grandeuradvisory.com",
     "toRecipients": "={{ $json['Recipient Email'] }}"
    },
    "bodyContent": "={{ $json['Body'] }}",
    "operation": "create",
    "resource": "draft",
    "subject": "={{ $json['Subject'] }}"
   },
   "onError": "continueErrorOutput",
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "webhookId": "1e174ffa-4f4e-4c59-827b-d3c64652b979",
   "credentials": {
    "microsoftOutlookOAuth2Api": {
     "id": "NmkBgylCa1gGZEob",
     "name": "Microsoft Outlook account"
    }
   }
  },
  {
   "id": "41344a8f-10ff-499b-8175-6baabc6fd4eb",
   "name": "Mark Outreach Sent",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1200,
    -80
   ],
   "parameters": {
    "columnToMatchOn": "Outreach ID",
    "dataMode": "define",
    "fieldsUi": {
     "values": [
      {
       "column": "Sent Date",
       "fieldValue": "={{ $json['Send Date'] }}"
      },
      {
       "column": "Outreach Status",
       "fieldValue": "Sent"
      },
      {
       "column": "Draft Status",
       "fieldValue": "Sent"
      },
      {
       "column": "Sequence Step",
       "fieldValue": "0"
      },
      {
       "column": "Sent Message ID",
       "fieldValue": "={{ $json['Sent Message ID'] }}"
      },
      {
       "column": "Conversation ID",
       "fieldValue": "={{ $json['Conversation ID'] }}"
      }
     ]
    },
    "operation": "upsert",
    "options": {},
    "resource": "worksheet",
    "valueToMatchOn": "={{ $json['Outreach ID'] }}",
    "workbook": {
     "__rl": true,
     "cachedResultName": "Grandeur_BD_Agent_V1",
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6"
    },
    "worksheet": {
     "__rl": true,
     "cachedResultName": "Outreach",
     "mode": "list",
     "value": "{00000000-0001-0000-0500-000000000000}"
    }
   },
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "3666ea0b-87ca-4a04-8a40-3a6f6d52485a",
   "name": "Stamp Opportunity Last Outreach",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1440,
    -80
   ],
   "parameters": {
    "columnToMatchOn": "Opportunity ID",
    "dataMode": "define",
    "fieldsUi": {
     "values": [
      {
       "column": "Last Outreach Date",
       "fieldValue": "={{ $json['Send Date'] }}"
      }
     ]
    },
    "operation": "upsert",
    "options": {},
    "resource": "worksheet",
    "valueToMatchOn": "={{ $json['Opportunity ID'] }}",
    "workbook": {
     "__rl": true,
     "cachedResultName": "Grandeur_BD_Agent_V1",
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6"
    },
    "worksheet": {
     "__rl": true,
     "cachedResultName": "Opportunities",
     "mode": "list",
     "value": "{00000000-0001-0000-0200-000000000000}"
    }
   },
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "2d0fda23-4e53-4c59-bb9b-2ccc30725262",
   "name": "Mark Send Failed",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1200,
    160
   ],
   "parameters": {
    "columnToMatchOn": "Outreach ID",
    "dataMode": "define",
    "fieldsUi": {
     "values": [
      {
       "column": "Outreach Status",
       "fieldValue": "Send Failed"
      },
      {
       "column": "Notes",
       "fieldValue": "={{ 'Send failed ' + $now.toFormat('yyyy-LL-dd') + ': ' + ($json.error && $json.error.message ? $json.error.message : 'unknown error') }}"
      }
     ]
    },
    "operation": "upsert",
    "options": {},
    "resource": "worksheet",
    "valueToMatchOn": "={{ $('Build Send Queue').first().json['Outreach ID'] }}",
    "workbook": {
     "__rl": true,
     "cachedResultName": "Grandeur_BD_Agent_V1",
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6"
    },
    "worksheet": {
     "__rl": true,
     "cachedResultName": "Outreach",
     "mode": "list",
     "value": "{00000000-0001-0000-0500-000000000000}"
    }
   },
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "14de9799-0ed9-4602-af40-ce73cddb1258",
   "name": "Send Draft",
   "type": "n8n-nodes-base.microsoftOutlook",
   "typeVersion": 2,
   "position": [
    1160,
    0
   ],
   "parameters": {
    "draftId": {
     "__rl": true,
     "mode": "id",
     "value": "={{ $json['id'] }}"
    },
    "operation": "send",
    "resource": "draft"
   },
   "onError": "continueErrorOutput",
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "webhookId": "0d4fe223-cf94-40a5-9dc8-6686bcae7ac4",
   "credentials": {
    "microsoftOutlookOAuth2Api": {
     "id": "NmkBgylCa1gGZEob",
     "name": "Microsoft Outlook account"
    }
   }
  },
  {
   "id": "86a1bd83-7b86-42d6-8962-58e59664e400",
   "name": "Record Send",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    1360,
    0
   ],
   "parameters": {
    "jsCode": "// Exactly one email is processed per run (SEND_BATCH_SIZE = 1), so .first() is\n// unambiguous and, unlike .item, does not depend on pairedItem surviving the\n// Outlook nodes between here and Build Send Queue.\nconst q = $('Build Send Queue').first().json;\nconst d = $('Create Draft').first().json;\n\n// draft/create assigns both ids at creation and send/draft keeps them, so the\n// draft's id IS the sent message's id and threads a later reply onto this mail.\nreturn [{ json: {\n  'Outreach ID': q['Outreach ID'],\n  'Opportunity ID': q['Opportunity ID'],\n  'Send Date': q['Send Date'],\n  'Sent Message ID': d && d.id ? d.id : '',\n  'Conversation ID': d && d.conversationId ? d.conversationId : ''\n} }];",
    "language": "javaScript",
    "mode": "runOnceForAllItems"
   }
  }
 ],
 "connections": {
  "Get Outreach Rows": {
   "main": [
    [
     {
      "node": "Get Contacts",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Get Contacts": {
   "main": [
    [
     {
      "node": "Build Send Queue",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Build Send Queue": {
   "main": [
    [
     {
      "node": "Create Draft",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Check For Approvals": {
   "main": [
    [
     {
      "node": "Get Outreach Rows",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Create Draft": {
   "main": [
    [
     {
      "node": "Send Draft",
      "type": "main",
      "index": 0
     }
    ],
    [
     {
      "node": "Mark Send Failed",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Send Draft": {
   "main": [
    [
     {
      "node": "Record Send",
      "type": "main",
      "index": 0
     }
    ],
    [
     {
      "node": "Mark Send Failed",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Record Send": {
   "main": [
    [
     {
      "node": "Mark Outreach Sent",
      "type": "main",
      "index": 0
     },
     {
      "node": "Stamp Opportunity Last Outreach",
      "type": "main",
      "index": 0
     }
    ]
   ]
  }
 },
 "settings": {
  "executionOrder": "v1",
  "timezone": "Asia/Kolkata"
 },
 "meta": {
  "originalId": "sEaRV2WFAshZ9uFu",
  "exportedAt": "2026-11-20"
 }
}
```

### A4. Grandeur BD - Follow-Up Sequencer (`ie6wPd70DBL6IPD8`)

```json
{
 "name": "Grandeur BD - Follow-Up Sequencer",
 "nodes": [
  {
   "id": "568c4d0a-5939-4467-9ffd-dcfea04f032b",
   "name": "Follow-Up Tick",
   "type": "n8n-nodes-base.scheduleTrigger",
   "typeVersion": 1.2,
   "position": [
    0,
    0
   ],
   "parameters": {
    "rule": {
     "interval": [
      {
       "field": "cronExpression",
       "expression": "*/10 17-21 * * 1-5"
      }
     ]
    }
   }
  },
  {
   "id": "81f11251-45b0-45b4-8dc1-208186196d8a",
   "name": "Read Outreach",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    220,
    0
   ],
   "parameters": {
    "resource": "table",
    "operation": "getRows",
    "returnAll": true,
    "filters": {},
    "workbook": {
     "__rl": true,
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6",
     "cachedResultName": "Grandeur_BD_Agent_V1"
    },
    "worksheet": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-0001-0000-0500-000000000000}",
     "cachedResultName": "Outreach"
    },
    "table": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF04000000}",
     "cachedResultName": "Table6"
    }
   },
   "executeOnce": true,
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "alwaysOutputData": true,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "187cbade-525c-45d9-bfa6-8e2f6c2925a2",
   "name": "Read Contacts",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    440,
    0
   ],
   "parameters": {
    "resource": "table",
    "operation": "getRows",
    "returnAll": true,
    "filters": {},
    "workbook": {
     "__rl": true,
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6",
     "cachedResultName": "Grandeur_BD_Agent_V1"
    },
    "worksheet": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-0001-0000-0300-000000000000}",
     "cachedResultName": "Contacts"
    },
    "table": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF02000000}",
     "cachedResultName": "tblContacts"
    }
   },
   "executeOnce": true,
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "alwaysOutputData": true,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "b83b0446-96e5-44d8-a409-f291a8c3e396",
   "name": "Read Responses",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    660,
    0
   ],
   "parameters": {
    "resource": "table",
    "operation": "getRows",
    "returnAll": true,
    "filters": {},
    "workbook": {
     "__rl": true,
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6",
     "cachedResultName": "Grandeur_BD_Agent_V1"
    },
    "worksheet": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-0001-0000-0600-000000000000}",
     "cachedResultName": "Responses"
    },
    "table": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF05000000}",
     "cachedResultName": "tblResponses"
    }
   },
   "executeOnce": true,
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "alwaysOutputData": true,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "d5fc22e4-39f7-45b5-9833-6aa8307a989e",
   "name": "Pick Follow-Up",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    880,
    0
   ],
   "parameters": {
    "mode": "runOnceForAllItems",
    "language": "javaScript",
    "jsCode": "const MAX_FOLLOWUPS = 3;\nconst WORKING_DAYS_AFTER_SEND = 2;\n\nconst norm = (v) => (v == null ? '' : String(v)).trim();\nconst lower = (v) => norm(v).toLowerCase();\nconst idKey = (v) => {\n  const s = norm(v);\n  if (s === '') return '';\n  if (/^\\d+$/.test(s)) return String(parseInt(s, 10));\n  return s.toLowerCase();\n};\n\nconst toDate = (v) => {\n  const s = norm(v);\n  if (s === '') return null;\n  if (/^\\d+(\\.\\d+)?$/.test(s)) {\n    const serial = Number(s);\n    if (serial > 20000 && serial < 90000) return new Date(Math.round((serial - 25569) * 86400000));\n  }\n  const d = new Date(s);\n  return isNaN(d.getTime()) ? null : d;\n};\n\nconst addWorkingDays = (from, n) => {\n  const d = new Date(from.getTime());\n  let added = 0;\n  while (added < n) {\n    d.setUTCDate(d.getUTCDate() + 1);\n    const wd = d.getUTCDay();\n    if (wd !== 0 && wd !== 6) added += 1;\n  }\n  return d.toISOString().slice(0, 10);\n};\n\nconst outreach   = $('Read Outreach').all().map(i => i.json).filter(r => r && norm(r['Outreach ID']));\nconst contacts   = $('Read Contacts').all().map(i => i.json).filter(r => r && norm(r['Contact ID']));\nconst responses  = $('Read Responses').all().map(i => i.json).filter(r => r && norm(r['Response ID']));\nconst suppression = $('Read Suppression').all().map(i => i.json).filter(r => r && norm(r['Suppression ID']));\n\nconst stopped = {};\nfor (const r of outreach) if (lower(r['Outreach Status']) === 'replied') stopped[idKey(r['Company ID'])] = true;\nfor (const r of responses) if (norm(r['Company ID'])) stopped[idKey(r['Company ID'])] = true;\nfor (const s of suppression) if (norm(s['Company ID'])) stopped[idKey(s['Company ID'])] = true;\n\nconst suppressedContacts = {};\nfor (const s of suppression) if (norm(s['Contact ID'])) suppressedContacts[idKey(s['Contact ID'])] = true;\n\nconst contactById = {};\nfor (const c of contacts) contactById[idKey(c['Contact ID'])] = c;\n\nconst FAIL = { 'send failed': 1, 'follow-up failed': 1, 'draft': 1 };\nconst latest = {};\nconst convByCompany = {};\nlet maxOutreachId = 0;\nfor (const r of outreach) {\n  const m = norm(r['Outreach ID']).match(/(\\d+)\\s*$/);\n  if (m) { const n = parseInt(m[1], 10); if (n > maxOutreachId) maxOutreachId = n; }\n  const co = idKey(r['Company ID']);\n  if (!co) continue;\n\n  // Thread target: the earliest Conversation ID on record for this company, so\n  // every follow-up stays in the ORIGINAL thread.\n  const conv = norm(r['Conversation ID']);\n  const cstep = Number(r['Sequence Step']) || 0;\n  if (conv) {\n    const cur = convByCompany[co];\n    if (!cur || cstep < cur.step) convByCompany[co] = { conv, step: cstep };\n  }\n\n  if (!norm(r['Sent Date'])) continue;\n  if (FAIL[lower(r['Outreach Status'])]) continue;\n  const step = Number(r['Sequence Step']) || 0;\n  const prev = latest[co];\n  if (!prev || step > prev.step ||\n      (step === prev.step && (Number(r['Outreach ID']) || 0) > (Number(prev.row['Outreach ID']) || 0))) {\n    latest[co] = { row: r, step };\n  }\n}\n\nconst todayStr = $now.toFormat('yyyy-LL-dd');\nconst due = [];\n\nfor (const co of Object.keys(latest)) {\n  if (stopped[co]) continue;\n  const { row, step } = latest[co];\n  if (step >= MAX_FOLLOWUPS) continue;\n\n  const convId = (convByCompany[co] || {}).conv || '';\n  if (!convId) continue; // thread-only: skip rows with no conversation on record\n\n  const sentDate = toDate(row['Sent Date']);\n  if (!sentDate) continue;\n  const dueDate = addWorkingDays(sentDate, WORKING_DAYS_AFTER_SEND);\n  if (todayStr < dueDate) continue;\n\n  const contact = contactById[idKey(row['Contact ID'])];\n  if (!contact) continue;\n  if (suppressedContacts[idKey(row['Contact ID'])]) continue;\n  const email = norm(contact['Email']);\n  if (!email || email.indexOf('@') === -1) continue;\n  if (lower(contact['Do Not Contact']) === 'yes') continue;\n\n  due.push({ row, step, contact, email, convId, dueDate });\n}\n\nif (!due.length) return [];\n\ndue.sort((a, b) => (a.dueDate < b.dueDate ? -1 : a.dueDate > b.dueDate ? 1 : 0));\nconst p = due[0];\nconst nextStep = p.step + 1;\nconst firstName = norm(p.contact['Name']).split(/\\s+/)[0] || 'there';\n\nconst T = {\n  1: 'Hi ' + firstName + ',<br><br>Just following up on my earlier note, in case it slipped past a busy inbox. If exploring outsourced finance and accounting support is worth a short conversation, I would be glad to find a time that suits you.<br><br>If the timing is not right, a quick word to say so is welcome and I will not keep chasing.',\n  2: 'Hi ' + firstName + ',<br><br>Following up once more. Even fifteen minutes would let me show how Grandeur Advisors could take routine finance and accounting work off your team as things scale. Would sometime next week work for a brief call?',\n  3: 'Hi ' + firstName + ',<br><br>This is my last note on this, I do not want to crowd your inbox. If outsourced finance or accounting support is ever useful down the line, my details are below and I would be glad to help. Wishing you and the team continued success.'\n};\n\nconst SIGNATURE = [\n  '<br><br>',\n  '<div style=\"font-family:Arial,Helvetica,sans-serif;font-size:13px;line-height:1.5;color:#333333;\">',\n  '<div>Yash Bhutada</div>',\n  '<div style=\"font-weight:bold;\">Grandeur Advisors LLP</div>',\n  '<div><a href=\"mailto:info@grandeuradvisory.com\" style=\"color:#1155cc;text-decoration:none;\">info@grandeuradvisory.com</a></div>',\n  '</div>'\n].join('');\n\nreturn [{ json: {\n  'New Outreach ID': maxOutreachId + 1,\n  'Company ID': norm(p.row['Company ID']),\n  'Opportunity ID': norm(p.row['Opportunity ID']),\n  'Contact ID': norm(p.row['Contact ID']),\n  'Recipient Email': p.email,\n  'Recipient Name': norm(p.contact['Name']),\n  'Conversation ID': p.convId,\n  'Sequence Step': nextStep,\n  'Body': (T[nextStep] || T[3]) + SIGNATURE,\n  'Send Date': todayStr\n} }];\n"
   }
  },
  {
   "id": "c4ff9ade-6ee7-4bd3-b00c-e583f060f4d8",
   "name": "Build Follow-Up Row",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    1320,
    0
   ],
   "parameters": {
    "mode": "runOnceForAllItems",
    "language": "javaScript",
    "jsCode": "const p = $('Resolve Reply Target').first().json;\n\nreturn [{ json: {\n  'Outreach ID': p['New Outreach ID'],\n  'Company ID': p['Company ID'],\n  'Opportunity ID': p['Opportunity ID'],\n  'Contact ID': p['Contact ID'],\n  'Channel': 'Email',\n  'Approval Status': 'Auto Follow-Up',\n  'Draft Status': 'Sent',\n  'Draft/Message': p['Body'],\n  'Sent Date': p['Send Date'],\n  'Outreach Status': 'Follow-Up Sent',\n  'Sequence Step': p['Sequence Step'],\n  'Sent Message ID': '',\n  'Conversation ID': p['Conversation ID'],\n  'Notes': 'Auto follow-up #' + p['Sequence Step'] + ' (threaded) to ' + p['Recipient Name'] + ' <' + p['Recipient Email'] + '> on ' + p['Send Date']\n} }];\n"
   }
  },
  {
   "id": "02e4d47e-5458-4927-b99d-67a95d6dfdf4",
   "name": "Append Follow-Up Row",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1540,
    -80
   ],
   "parameters": {
    "resource": "table",
    "operation": "append",
    "dataMode": "autoMap",
    "workbook": {
     "__rl": true,
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6",
     "cachedResultName": "Grandeur_BD_Agent_V1"
    },
    "worksheet": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-0001-0000-0500-000000000000}",
     "cachedResultName": "Outreach"
    },
    "table": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF04000000}",
     "cachedResultName": "Table6"
    },
    "options": {}
   },
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "fecf665a-1200-4b7e-9feb-08262bc5c194",
   "name": "Stamp Opportunity Last Outreach",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1540,
    100
   ],
   "parameters": {
    "resource": "worksheet",
    "operation": "upsert",
    "dataMode": "define",
    "columnToMatchOn": "Opportunity ID",
    "valueToMatchOn": "={{ $json[\"Opportunity ID\"] }}",
    "fieldsUi": {
     "values": [
      {
       "column": "Last Outreach Date",
       "fieldValue": "={{ $json[\"Sent Date\"] }}"
      }
     ]
    },
    "workbook": {
     "__rl": true,
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6",
     "cachedResultName": "Grandeur_BD_Agent_V1"
    },
    "worksheet": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-0001-0000-0200-000000000000}",
     "cachedResultName": "Opportunities"
    },
    "options": {}
   },
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "c0feec48-388f-4b97-a540-b96522e92c28",
   "name": "Read Suppression",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    770,
    160
   ],
   "parameters": {
    "resource": "table",
    "operation": "getRows",
    "returnAll": true,
    "filters": {},
    "workbook": {
     "__rl": true,
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6",
     "cachedResultName": "Grandeur_BD_Agent_V1"
    },
    "worksheet": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-0001-0000-0700-000000000000}",
     "cachedResultName": "Suppression"
    },
    "table": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF06000000}",
     "cachedResultName": "tblSuppression"
    }
   },
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "alwaysOutputData": true,
   "executeOnce": true,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "1a062acc-b1e7-48cc-aab8-35faaf1459da",
   "name": "Find Thread Msg",
   "type": "n8n-nodes-base.httpRequest",
   "typeVersion": 4.5,
   "position": [
    1100,
    -160
   ],
   "parameters": {
    "method": "GET",
    "url": "https://graph.microsoft.com/v1.0/me/messages",
    "authentication": "predefinedCredentialType",
    "nodeCredentialType": "microsoftOutlookOAuth2Api",
    "sendQuery": true,
    "specifyQuery": "keypair",
    "queryParameters": {
     "parameters": [
      {
       "name": "$filter",
       "value": "=conversationId eq '{{ $json['Conversation ID'] }}'"
      },
      {
       "name": "$select",
       "value": "id,conversationId"
      },
      {
       "name": "$top",
       "value": "1"
      }
     ]
    },
    "options": {
     "response": {
      "response": {
       "neverError": true
      }
     }
    }
   },
   "credentials": {
    "microsoftOutlookOAuth2Api": {
     "id": "NmkBgylCa1gGZEob",
     "name": "Microsoft Outlook account"
    }
   }
  },
  {
   "id": "c1ab7f33-fad4-464e-a6ba-e2174fa04974",
   "name": "Resolve Reply Target",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    1100,
    0
   ],
   "parameters": {
    "language": "javaScript",
    "mode": "runOnceForAllItems",
    "jsCode": "const p = $('Pick Follow-Up').first().json;\nconst resp = $input.first().json;\nconst msgs = (resp && resp.value) ? resp.value : [];\nif (!msgs.length || !msgs[0].id) return []; // no live message to thread into; skip this tick\nreturn [{ json: Object.assign({}, p, { 'Reply Message ID': msgs[0].id }) }];\n"
   }
  },
  {
   "id": "70c8cef1-ea2c-4a9e-bd36-a4bb7f38e194",
   "name": "Send Reply",
   "type": "n8n-nodes-base.microsoftOutlook",
   "typeVersion": 2,
   "position": [
    1100,
    160
   ],
   "parameters": {
    "resource": "message",
    "operation": "reply",
    "messageId": {
     "__rl": true,
     "mode": "id",
     "value": "={{ $json['Reply Message ID'] }}"
    },
    "replyToSenderOnly": true,
    "message": "={{ $json['Body'] }}",
    "additionalFields": {
     "from": "info@grandeuradvisory.com",
     "bodyContentType": "html",
     "toRecipients": "={{ $json['Recipient Email'] }}"
    },
    "options": {
     "saveAsDraft": false
    }
   },
   "webhookId": "06897877-45b7-4742-bed6-ff8282b5e749",
   "credentials": {
    "microsoftOutlookOAuth2Api": {
     "id": "NmkBgylCa1gGZEob",
     "name": "Microsoft Outlook account"
    }
   }
  }
 ],
 "connections": {
  "Follow-Up Tick": {
   "main": [
    [
     {
      "node": "Read Outreach",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Read Outreach": {
   "main": [
    [
     {
      "node": "Read Contacts",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Read Contacts": {
   "main": [
    [
     {
      "node": "Read Responses",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Pick Follow-Up": {
   "main": [
    [
     {
      "node": "Find Thread Msg",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Build Follow-Up Row": {
   "main": [
    [
     {
      "node": "Append Follow-Up Row",
      "type": "main",
      "index": 0
     },
     {
      "node": "Stamp Opportunity Last Outreach",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Read Responses": {
   "main": [
    [
     {
      "node": "Read Suppression",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Read Suppression": {
   "main": [
    [
     {
      "node": "Pick Follow-Up",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Find Thread Msg": {
   "main": [
    [
     {
      "node": "Resolve Reply Target",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Resolve Reply Target": {
   "main": [
    [
     {
      "node": "Send Reply",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Send Reply": {
   "main": [
    [
     {
      "node": "Build Follow-Up Row",
      "type": "main",
      "index": 0
     }
    ]
   ]
  }
 },
 "settings": {
  "executionOrder": "v1",
  "timezone": "Asia/Kolkata"
 },
 "meta": {
  "originalId": "ie6wPd70DBL6IPD8",
  "exportedAt": "2026-11-20"
 }
}
```

### A5. Grandeur BD - Reply Detection (`lAufPqbyL5XBBbEv`)

```json
{
 "name": "Grandeur BD - Reply Detection",
 "nodes": [
  {
   "id": "c15aab7a-6ea4-41ee-bf8f-b3ef5df70d13",
   "name": "Reply Poll",
   "type": "n8n-nodes-base.scheduleTrigger",
   "typeVersion": 1.2,
   "position": [
    0,
    0
   ],
   "parameters": {
    "rule": {
     "interval": [
      {
       "field": "cronExpression",
       "expression": "*/30 * * * *"
      }
     ]
    }
   }
  },
  {
   "id": "4c083982-996a-4986-a04f-ec973642ca4f",
   "name": "Fetch Recent Mail",
   "type": "n8n-nodes-base.microsoftOutlook",
   "typeVersion": 2,
   "position": [
    200,
    0
   ],
   "parameters": {
    "resource": "message",
    "operation": "getAll",
    "returnAll": false,
    "limit": 60,
    "output": "fields",
    "fields": [
     "from",
     "subject",
     "body",
     "bodyPreview",
     "conversationId",
     "receivedDateTime",
     "internetMessageId",
     "isDraft",
     "toRecipients"
    ],
    "filtersUI": {
     "values": {
      "filterBy": "filters",
      "filters": {
       "readStatus": "both",
       "receivedAfter": "={{ $now.minus(4, \"days\").toISO() }}"
      }
     }
    },
    "options": {}
   },
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "webhookId": "1f9adbb6-e711-49c6-a6a8-1fdf432d7b7d",
   "credentials": {
    "microsoftOutlookOAuth2Api": {
     "id": "NmkBgylCa1gGZEob",
     "name": "Microsoft Outlook account"
    }
   }
  },
  {
   "id": "8f56ab87-0bb9-4573-9c21-698fa5542dd3",
   "name": "Read Outreach",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    400,
    0
   ],
   "parameters": {
    "resource": "table",
    "operation": "getRows",
    "returnAll": true,
    "filters": {},
    "workbook": {
     "__rl": true,
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6",
     "cachedResultName": "Grandeur_BD_Agent_V1"
    },
    "worksheet": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-0001-0000-0500-000000000000}",
     "cachedResultName": "Outreach"
    },
    "table": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF04000000}",
     "cachedResultName": "Table6"
    }
   },
   "executeOnce": true,
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "alwaysOutputData": true,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "015eb5a1-1701-4c66-8ad9-55a7d7999b20",
   "name": "Read Contacts",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    600,
    0
   ],
   "parameters": {
    "resource": "table",
    "operation": "getRows",
    "returnAll": true,
    "filters": {},
    "workbook": {
     "__rl": true,
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6",
     "cachedResultName": "Grandeur_BD_Agent_V1"
    },
    "worksheet": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-0001-0000-0300-000000000000}",
     "cachedResultName": "Contacts"
    },
    "table": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF02000000}",
     "cachedResultName": "tblContacts"
    }
   },
   "executeOnce": true,
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "alwaysOutputData": true,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "6ed813d5-200e-44e4-b9d4-c617b5826b53",
   "name": "Read Responses",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    800,
    0
   ],
   "parameters": {
    "resource": "table",
    "operation": "getRows",
    "returnAll": true,
    "filters": {},
    "workbook": {
     "__rl": true,
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6",
     "cachedResultName": "Grandeur_BD_Agent_V1"
    },
    "worksheet": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-0001-0000-0600-000000000000}",
     "cachedResultName": "Responses"
    },
    "table": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF05000000}",
     "cachedResultName": "tblResponses"
    }
   },
   "executeOnce": true,
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "alwaysOutputData": true,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "a9a4e92a-50ca-490e-8bf4-4deaf022e6eb",
   "name": "Match Replies",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    1000,
    0
   ],
   "parameters": {
    "mode": "runOnceForAllItems",
    "language": "javaScript",
    "jsCode": "\nconst OUR_ADDRESSES = ['accounting@grandeuradvisory.com', 'info@grandeuradvisory.com'];\n\nconst norm = (v) => (v == null ? '' : String(v)).trim();\nconst lower = (v) => norm(v).toLowerCase();\nconst idKey = (v) => {\n  const s = norm(v);\n  if (s === '') return '';\n  if (/^\\d+$/.test(s)) return String(parseInt(s, 10));\n  return s.toLowerCase();\n};\n\n// Outlook returns the body as HTML. Store readable text: the owner reads this\n// column directly, and the classifier below matches on words, not markup.\nconst stripHtml = (h) => norm(h)\n  .replace(/<style[\\s\\S]*?<\\/style>/gi, ' ')\n  .replace(/<script[\\s\\S]*?<\\/script>/gi, ' ')\n  .replace(/<br\\s*\\/?>/gi, '\\n')\n  .replace(/<\\/p>/gi, '\\n')\n  .replace(/<[^>]+>/g, ' ')\n  .replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&lt;/g, '<')\n  .replace(/&gt;/g, '>').replace(/&quot;/g, '\"').replace(/&#39;/g, \"'\")\n  .replace(/[ \\t]+/g, ' ')\n  .replace(/\\n{3,}/g, '\\n\\n')\n  .trim();\n\n// Rule-based on purpose. An AI call per inbound message would add cost to the\n// one part of the pipeline that has to run all day, and the owner reads the body\n// anyway. Anything unmatched lands as Needs Review rather than being guessed at.\nconst classify = (subject, body) => {\n  const t = lower(subject + ' ' + body);\n  if (/out of (the )?office|annual leave|on vacation|auto-?reply|automatic reply|currently away/.test(t)) return 'Out of Office';\n  if (/unsubscribe|remove me|opt ?out|do not contact|stop emailing/.test(t)) return 'Opt Out';\n  if (/undeliverable|delivery has failed|address not found|mailbox is full|recipient .{0,20}rejected|550 5\\./.test(t)) return 'Bounce';\n  if (/not interested|no thanks|no thank you|we are all set|we're all set|already have|not a fit|not at this time|no need/.test(t)) return 'Not Interested';\n  if (/interested|happy to|glad to|let'?s (talk|chat|connect|discuss)|book a|schedule a|set up a call|calendar|sounds good|tell me more|send .{0,20}details/.test(t)) return 'Interested';\n  return 'Needs Review';\n};\n\nconst messages  = $('Fetch Recent Mail').all().map(i => i.json);\nconst outreach  = $('Read Outreach').all().map(i => i.json).filter(r => r && norm(r['Outreach ID']));\nconst contacts  = $('Read Contacts').all().map(i => i.json).filter(r => r && norm(r['Contact ID']));\nconst responses = $('Read Responses').all().map(i => i.json).filter(r => r && norm(r['Response ID']));\n\n// Idempotency. Responses has no column for the Outlook message id, and adding one\n// is the owner's call, so it rides in Notes behind a marker and is read back here.\n// Without this a 30-minute poll would re-append the same reply every run.\nconst seenMsg = {};\nfor (const r of responses) {\n  const m = /msgid:([^\\s|]+)/.exec(norm(r['Notes']));\n  if (m) seenMsg[m[1]] = true;\n}\n\nconst contactByEmail = {};\nfor (const c of contacts) {\n  if (lower(c['Email'])) contactByEmail[lower(c['Email'])] = c;\n}\n\n// Conversation ID is the exact match, but the sender only started recording it\n// once the column existed, so older sends have none. Falling back to the sender's\n// address covers those, and covers a reply that starts a fresh thread.\nconst outreachByConv = {};\nfor (const r of outreach) {\n  const cv = norm(r['Conversation ID']);\n  if (cv) outreachByConv[cv] = r;\n}\n\nconst sentByContact = {};\nfor (const r of outreach) {\n  if (!norm(r['Sent Date'])) continue;\n  const k = idKey(r['Contact ID']);\n  if (!k) continue;\n  const prev = sentByContact[k];\n  if (!prev || (Number(r['Outreach ID']) || 0) > (Number(prev['Outreach ID']) || 0)) sentByContact[k] = r;\n}\n\nlet maxId = 0;\nfor (const r of responses) {\n  const m = norm(r['Response ID']).match(/(\\d+)\\s*$/);\n  if (m) {\n    const n = parseInt(m[1], 10);\n    if (!isNaN(n) && n > maxId) maxId = n;\n  }\n}\n\nconst out = [];\n\nfor (const m of messages) {\n  if (m.isDraft) continue;\n\n  const msgId = norm(m.id) || norm(m.internetMessageId);\n  if (!msgId || seenMsg[msgId]) continue;\n\n  const fromEmail = lower(m.from && m.from.emailAddress ? m.from.emailAddress.address : '');\n  if (!fromEmail) continue;\n  // Our own sent mail shows up in the same mailbox; it is not a reply.\n  if (OUR_ADDRESSES.indexOf(fromEmail) !== -1) continue;\n\n  const conv = norm(m.conversationId);\n  let row = conv ? (outreachByConv[conv] || null) : null;\n\n  const contact = contactByEmail[fromEmail] || null;\n  if (!row && contact) row = sentByContact[idKey(contact['Contact ID'])] || null;\n\n  // No outreach on file for this sender: ordinary mail, not a reply to us.\n  if (!row) continue;\n\n  const subject = norm(m.subject);\n  const body = stripHtml(m.body && m.body.content ? m.body.content : m.bodyPreview);\n\n  maxId += 1;\n  seenMsg[msgId] = true;\n\n  out.push({ json: {\n    'Response ID': maxId,\n    'Outreach ID': row['Outreach ID'],\n    'Company ID': norm(row['Company ID']),\n    'Contact ID': contact ? contact['Contact ID'] : row['Contact ID'],\n    'Received Date': norm(m.receivedDateTime).slice(0, 10),\n    'From Email': fromEmail,\n    'From Name': norm(m.from && m.from.emailAddress ? m.from.emailAddress.name : ''),\n    'Subject': subject,\n    // Excel caps a cell at 32767 characters; a long quoted thread would blow it.\n    'Body': body.slice(0, 30000),\n    'Intent': classify(subject, body),\n    'Conversation ID': conv,\n    'Notes': 'msgid:' + msgId + ' | matched via ' + (conv && outreachByConv[conv] ? 'conversation id' : 'sender address')\n  }});\n}\n\nreturn out;\n"
   }
  },
  {
   "id": "7f224f5b-925d-4171-b752-78612739b56b",
   "name": "Append Response",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1200,
    0
   ],
   "parameters": {
    "resource": "table",
    "operation": "append",
    "dataMode": "autoMap",
    "workbook": {
     "__rl": true,
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6",
     "cachedResultName": "Grandeur_BD_Agent_V1"
    },
    "worksheet": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-0001-0000-0600-000000000000}",
     "cachedResultName": "Responses"
    },
    "table": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-000C-0000-FFFF-FFFF05000000}",
     "cachedResultName": "tblResponses"
    },
    "options": {}
   },
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  },
  {
   "id": "e270fa21-4c10-46f7-9dc1-ae8a2f9f471f",
   "name": "Build Replied Rows",
   "type": "n8n-nodes-base.code",
   "typeVersion": 2,
   "position": [
    1400,
    0
   ],
   "parameters": {
    "mode": "runOnceForAllItems",
    "language": "javaScript",
    "jsCode": "\nconst norm = (v) => (v == null ? '' : String(v)).trim();\nconst lower = (v) => norm(v).toLowerCase();\nconst idKey = (v) => {\n  const s = norm(v);\n  if (s === '') return '';\n  if (/^\\d+$/.test(s)) return String(parseInt(s, 10));\n  return s.toLowerCase();\n};\n\n// Read from the match node, not from this node's input: Append Response is an\n// Excel node and its output items describe sheet rows, not the replies.\nconst replies = $('Match Replies').all().map(i => i.json);\nconst outreach = $('Read Outreach').all().map(i => i.json).filter(r => r && norm(r['Outreach ID']));\n\n// A reply stops automated mail for the whole COMPANY, not just the thread it\n// arrived on. Owner's rule: once they answer, we stop chasing.\nconst repliedCompanies = {};\nfor (const r of replies) repliedCompanies[idKey(r['Company ID'])] = true;\n\nconst out = [];\nfor (const r of outreach) {\n  if (!repliedCompanies[idKey(r['Company ID'])]) continue;\n  if (lower(r['Outreach Status']) === 'replied') continue;\n\n  // Carry the whole row forward. A worksheet upsert writes the columns it is\n  // handed, so sending two of them would blank the rest.\n  const updated = Object.assign({}, r);\n  updated['Outreach Status'] = 'Replied';\n  updated['Follow-Up Plan'] = 'Stopped - prospect replied';\n  out.push({ json: updated });\n}\n\nreturn out;\n"
   }
  },
  {
   "id": "4b4c66c6-87c4-4923-aeb9-ec4d3b70e2ee",
   "name": "Mark Outreach Replied",
   "type": "n8n-nodes-base.microsoftExcel",
   "typeVersion": 2.2,
   "position": [
    1600,
    0
   ],
   "parameters": {
    "resource": "worksheet",
    "operation": "upsert",
    "dataMode": "autoMap",
    "columnToMatchOn": "Outreach ID",
    "workbook": {
     "__rl": true,
     "mode": "list",
     "value": "01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6",
     "cachedResultName": "Grandeur_BD_Agent_V1"
    },
    "worksheet": {
     "__rl": true,
     "mode": "list",
     "value": "{00000000-0001-0000-0500-000000000000}",
     "cachedResultName": "Outreach"
    },
    "options": {}
   },
   "retryOnFail": true,
   "maxTries": 3,
   "waitBetweenTries": 2000,
   "credentials": {
    "microsoftExcelOAuth2Api": {
     "id": "t05ZuN05jLPuMapG",
     "name": "Microsoft Excel account"
    }
   }
  }
 ],
 "connections": {
  "Reply Poll": {
   "main": [
    [
     {
      "node": "Fetch Recent Mail",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Fetch Recent Mail": {
   "main": [
    [
     {
      "node": "Read Outreach",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Read Outreach": {
   "main": [
    [
     {
      "node": "Read Contacts",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Read Contacts": {
   "main": [
    [
     {
      "node": "Read Responses",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Read Responses": {
   "main": [
    [
     {
      "node": "Match Replies",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Match Replies": {
   "main": [
    [
     {
      "node": "Append Response",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Append Response": {
   "main": [
    [
     {
      "node": "Build Replied Rows",
      "type": "main",
      "index": 0
     }
    ]
   ]
  },
  "Build Replied Rows": {
   "main": [
    [
     {
      "node": "Mark Outreach Replied",
      "type": "main",
      "index": 0
     }
    ]
   ]
  }
 },
 "settings": {
  "executionOrder": "v1"
 },
 "meta": {
  "originalId": "lAufPqbyL5XBBbEv",
  "exportedAt": "2026-11-20"
 }
}
```
