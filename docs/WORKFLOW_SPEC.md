# Grandeur BD Agent V1 — Current Build State

> **Verification note:** reconstructed from the ChatGPT working transcript
> (`docs/SOURCE_TRANSCRIPT.md`). MCP access to the workflow is currently **disabled**,
> so node parameters have not been read back from the live instance. Credentials and
> workflow metadata below *are* verified via the n8n MCP API.

---

## Workflows in the account (verified 2026-08-23)

| Workflow | ID | Active | MCP access | Notes |
|---|---|---|---|---|
| Grandeur BD Agent V1 | `jIghxNOFdVshn2d3` | No | ❌ off | The live build |
| Grandeur BD Agent V1 - Working Backup | `SSabnVfDT5xFEXIr` | No | ❌ off | Snapshot taken 2026-08-23 11:29 |
| My workflow | `cXBDXRsgCyg5g7KE` | No | ❌ off | Scratch / abandoned |

Project: `HrT1qMUphHpg5fk0` — Yash Bhutada (personal)

## Credentials (verified)

| Name | ID | Type |
|---|---|---|
| OpenAI account | `Iny8RznkWYiFgD9G` | `openAiApi` |
| Microsoft Excel account | `t05ZuN05jLPuMapG` | `microsoftExcelOAuth2Api` |

## Current node chain (the working test path)

```
Test Company Input  →  Company Research AI  →  Normalize Research Output  →  Test Append
   (Set/Edit Fields)      (OpenAI message)         (Set/Edit Fields)          (Excel append)
```

Nodes were deliberately renamed from their defaults to mark this as the preserved
baseline:

| Original name | Renamed to | Role |
|---|---|---|
| Edit Fields | **Test Company Input** | Hand-entered single company, the test fixture |
| Message a model | **Company Research AI** | OpenAI call carrying the research prompt |
| Edit Fields1 | **Normalize Research Output** | Maps the model's JSON onto Excel columns |
| Append rows to table | **Test Append** | Writes one row to the Excel table |

**Nothing is to be deleted.** This path is the known-good backup.

## Excel destination

| Setting | Value |
|---|---|
| Resource | Table |
| Operation | Append |
| Workbook | `Grandeur_BD_Agent_V1` |
| Sheet | `Companies` |
| Table | `tblCompanies` |
| Data Mode | Auto-Map Input Data to Columns |

## Verified working test case

Input company **BluePeak Technology Services** flows end to end and lands in Excel:

| Field | Value |
|---|---|
| Company Name | BluePeak Technology Services |
| Website | `https://example.com` |
| Country | Australia |
| Company Type | Public |
| Industry | Technology |
| Revenue | 125000000 |
| Revenue Band | $100M–$249.9M |
| Verification Status | Unverified |
| ICP Fit | Unknown |
| Priority | Unknown |
| Notes / Reason / Missing Information | populated |

Employee Count, Employee Band, Finance Team Size, ERP, Accounting Software and
Technology Stack come back **blank** — correct behaviour, because the prompt forbids
invention and no web-research layer exists yet.

The `https://example.com` placeholder is a *useful* test: the agent correctly judged it
insufficient for verification rather than fabricating a profile.

## Field schema

### Requested by the prompt (18 fields)

`company_id`, `company_name`, `legal_name`, `website`, `country`, `state_region`,
`city`, `parent_company_id`, `company_type`, `industry`, `ownership_type`, `revenue`,
`revenue_type`, `revenue_band`, `icp_fit`, `priority`, `reason`, `missing_information`

### Additionally observed in live model output (not in the prompt spec)

`employee_count`, `employee_count_type`, `employee_band`, `finance_team_size`,
`finance_hiring_activity`, `growth_information`, `erp`, `accounting_software`,
`technology_stack`

### Additionally present in the Excel table

`verification_status`, `notes`

> ⚠️ **Schema drift.** Three different field lists are in play. See
> `docs/OPEN_QUESTIONS.md` §1.

### Constrained vocabularies

- `icp_fit` — exactly one of: `High`, `Medium`, `Low`, `Unknown`
- `priority` — exactly one of: `High`, `Medium`, `Low`, `Unknown`
- Ordinary missing data fields use `""`, **never** `"Unknown"`
- `"Unknown"` is reserved for `icp_fit` / `priority` only

## Next planned stage (Stage 2)

Build a **production path alongside** the test path — do not modify the working nodes:

```
Excel: Read companies needing research
        ↓
   Web / AI Research
        ↓
      Analysis
        ↓
   Structured JSON
        ↓
Find matching Company ID
        ↓
   UPDATE EXISTING ROW      ← not append
```

**The key design decision:** match on Company ID and update the existing row. A
read → research → *append* loop re-creates the same company on every run. This is the
duplicate-company problem already hit once.

The immediate mechanical step left off in the transcript: add a **Microsoft Excel 365**
node configured to *read rows* from `tblCompanies`, filtered to companies still needing
research.

## Known friction encountered so far

- Excel table columns not appearing in n8n dropdowns (needs a schema refresh in the node)
- No "Add rows" option surfaced where expected
- Duplicate company rows created during earlier experiments
- Model emitting fields beyond the prompt's declared JSON schema
