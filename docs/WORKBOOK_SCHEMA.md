# Workbook Schema — verified live 2026-08-25

Workbook `Grandeur_BD_Agent_V1` (`01XTNPD6XV4WCHZOPO5FHLHNSX75DOR6W6`)
Credential: Microsoft Excel account (`t05ZuN05jLPuMapG`)

## Worksheet / table IDs

| Sheet | Worksheet ID | Table | Table ID |
|---|---|---|---|
| Dashboard | `{...-0000-...}` | — | — |
| **Companies** | `{00000000-0001-0000-0100-000000000000}` | `tblCompanies` | `{00000000-000C-0000-FFFF-FFFF00000000}` |
| **Opportunities** | `{00000000-0001-0000-0200-000000000000}` | `tblOpportunities` | `{00000000-000C-0000-FFFF-FFFF01000000}` |
| **Contacts** | `{00000000-0001-0000-0300-000000000000}` | `tblContacts` | `{00000000-000C-0000-FFFF-FFFF02000000}` |
| Signals | `{00000000-0001-0000-0400-000000000000}` | — | — |
| **Outreach** | `{00000000-0001-0000-0500-000000000000}` | `Table6` ⚠️ | `{00000000-000C-0000-FFFF-FFFF04000000}` |
| Responses | `{00000000-0001-0000-0600-000000000000}` | — | — |
| Suppression | `{00000000-0001-0000-0700-000000000000}` | — | — |
| Clients | `{00000000-0001-0000-0800-000000000000}` | — | — |
| Competitors | `{00000000-0001-0000-0900-000000000000}` | — | — |
| Sources | `{00000000-0001-0000-0A00-000000000000}` | — | — |
| Settings | `{00000000-0001-0000-0B00-000000000000}` | — | — |
| Learning | `{00000000-0001-0000-0C00-000000000000}` | — | — |

⚠️ Outreach's table is named **`Table6`** (Excel default), not `tblOutreach` — cosmetic
inconsistency only; functionality unaffected. Rename at leisure.

## Companies — 40 columns

`Company Key` · `Company ID` · Company Name · Legal Name · Website · Country ·
State/Region · City · Parent Company ID · Company Type · Industry · Ownership Type ·
Revenue · Revenue Type · Revenue Band · Employee Count · Employee Count Type ·
Employee Band · **Finance Team Size** · Finance Hiring Activity · Growth Information ·
**ERP** · Accounting Software · Technology Stack · Number of Entities ·
Countries Operated · Existing Outsourcing · Current Provider · Company Status ·
First Discovered · Last Researched · Last Signal Date · Next Research Date ·
Primary Source ID · Verification Status · Notes · ICP Fit · Priority · Reason ·
Missing Information

`Company Key` (normalized domain) is the dedup match key; `Company ID` (`Grand NNN`)
is the display/join key. Finance Team Size and ERP headers confirmed correct.

## Opportunities — 22 columns

`Opportunity ID` · `Company ID` · Opportunity Type · Opportunity Description ·
Primary Signal · Signal Strength · First Detected · Last Verified · Expected Deadline ·
Urgency · Grandeur Service · Estimated Monthly Value · Estimated Annual Value ·
Estimate Type · Estimate Basis · Opportunity Score · Opportunity Status ·
Next Best Action · Recommended Contact Date · Recommended Contact Window ·
Primary Contact ID · Evidence Summary

Dedup match = `Company ID` + `Opportunity Type`. `Last Verified` drives the **72h
freshness** window.

## Contacts — 18 columns

Contact ID · Company ID · Name · Job Title · Department · Seniority · LinkedIn URL ·
**Email** · **Email Verification Status** · Phone · Phone Verification Status ·
Source ID · Last Verified · **Contact Confidence** · **Primary Decision-Maker** ·
**Backup Decision-Maker** · **Do Not Contact** · Notes

Well suited to the outreach gate: recipient comes from `Email`, guarded by
`Email Verification Status`, `Contact Confidence` and `Do Not Contact`.

## Outreach — 15 columns

Outreach ID · Company ID · **Opportunity ID** · Contact ID · Channel ·
**Approval Status** · Draft Status · **Draft/Message** · Recommended Send Date ·
Recommended Send Window · **Sent Date** · Follow-Up Date · Follow-Up Plan ·
Outreach Status · Notes

This is the approve→send spine: draft lands with `Approval Status = Pending Approval`,
owner sets `Approved`, sender fills `Sent Date` + `Outreach Status`.
`max(Sent Date) per Opportunity ID` is the **30-day re-engagement** source of truth.

### ⚠️ Gaps for the email build

1. **No `Subject` column** on Outreach — an email needs one. Either add `Subject`, or
   accept subject-in-`Notes` (not recommended).
2. **No `Last Outreach Date` on Opportunities** — required by the agreed "Both" design
   (history in Outreach + cached timestamp on Opportunities for fast filtering).
