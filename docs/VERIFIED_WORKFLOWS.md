# Verified Live Workflow State — 2026-08-24

Read directly from the n8n instance via MCP (access enabled by owner on this date).
Supersedes the transcript-based reconstruction in `WORKFLOW_SPEC.md` where they differ.

---

## Grandeur BD Agent V1 — MAIN (`jIghxNOFdVshn2d3`) — the build target

```
When clicking 'Execute workflow' (manualTrigger)
  → Test Company Input        (set: BluePeak test fixture, 6 fields)
  → Company Research AI        (@n8n/n8n-nodes-langchain.openAi v2.3, model CHAT-LATEST,
                                web search ON, 39-field research prompt)
  → Normalize Research Output  (set: JSON.parse output → 39 named columns)
  → Test Append                (n8n-nodes-base.microsoftExcel v2.2, table append, autoMap)
```

Single AI stage, full 39-field schema, clean wiring. **This is the cleaner of the two
versions and the agreed base for further work.**

### The 39 normalized column names (as written to Excel via auto-map)

Company ID · Company Name · Legal Name · Website · Country · State/Region · City ·
Parent Company ID · Company Type · Industry · Ownership Type · Revenue · Revenue Type ·
Revenue Band · Employee Count · Employee Count Type · Employee Band ·
**=Finance Team Size** · Finance Hiring Activity · Growth Information · **=ERP** ·
Accounting Software · Technology Stack · Number of Entities · Countries Operated ·
Existing Outsourcing · Current Provider · Company Status · First Discovered ·
Last Researched · Last Signal Date · Next Research Date · Primary Source ID ·
Verification Status · Notes · ICP Fit · Priority · Reason · Missing Information

### 🐞 Confirmed bugs

1. **`=Finance Team Size`** and **`=ERP`** — the assignment *names* carry a stray `=`
   prefix (should be `Finance Team Size` and `ERP`). Auto-map therefore writes to
   non-existent columns; these two never land in Excel. Fix: rename the two assignments.

### Revenue band vocabulary (from the research prompt)

`Under $1M` · `$1M-$4.9M` · `$5M-$9.9M` · `$10M-$24.9M` · `$25M-$49.9M` ·
`$50M-$99.9M` · `$100M-$249.9M` · `$250M-$499.9M` · `$500M-$999.9M` · `$1B+`

### Gaps blocking the email feature

- No recipient **contact email** field, no decision-maker name/title fields.
- No **Status** column (the approval gate needs one).
- No **email draft** fields (Subject/Body).
- No contact-enrichment stage anywhere in the pipeline.

## Grandeur BD Agent V1 - Working Backup (`SSabnVfDT5xFEXIr`)

```
Manual Trigger → Edit Fields → Message a model (research, 18 fields, web search)
  → Edit Fields1 (parse → 18 columns) → Message a model1 (OPPORTUNITY analysis,
    22 fields, web search) → Append rows to table (autoMap)
```

- Original (un-renamed) node names + an extra opportunity-analysis AI stage.
- 🐞 **Wiring bug:** `Message a model1`'s output replaces the item, so `Append` receives
  the raw OpenAI response — both the 18 company columns and the 22 opportunity fields
  are lost. Opportunity data does not reach Excel as wired.
- The **opportunity-scoring prompt** here (0–100 score, signal strength, urgency,
  recommended Grandeur service, evidence summary) is good and worth porting into Main
  later, correctly wired via a parse+merge step.

## Excel workbook (both workflows target the same file)

| Item | Value |
|---|---|
| Workbook | `Grandeur_BD_Agent_V1` (id `01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6`) |
| Location | SharePoint / OneDrive — accounting_grandeuradvisory_com1 |
| Worksheet | `Companies` |
| Table | `tblCompanies` (range A1:AM2 → 39 columns) |
| n8n credential | Microsoft Excel account (`t05ZuN05jLPuMapG`) |

## Credentials present in n8n

| Name | ID | Type |
|---|---|---|
| OpenAI account | `Iny8RznkWYiFgD9G` | `openAiApi` |
| Microsoft Excel account | `t05ZuN05jLPuMapG` | `microsoftExcelOAuth2Api` |

**Missing for outreach:** a `microsoftOutlookOAuth2Api` credential — must be created in
the n8n UI (OAuth sign-in; cannot be created via the MCP API).
