# Grandeur BD Agent — Project Brief

**Owner:** Yash Bhutada, Grandeur Advisory LLP (info@grandeuradvisory.com)
**Platform:** n8n (personal project `HrT1qMUphHpg5fk0`)
**Status:** Phase 1, Stage 1 complete (single-company test pipeline working end-to-end)

---

## 1. What we are building

An **AI Business Development Agent** — a virtual BD manager for Grandeur Advisory that
continuously **finds, qualifies, enriches, scores, and prepares leads** for outreach.

Explicitly *not* a scraper. The distinction that governs every design decision:

> A scraper says "here are 500 companies."
> A BD agent says "this company is expanding into the UK and US, is hiring a finance
> manager, uses NetSuite, and has a multi-entity structure — strong potential for
> outsourced month-end and NetSuite support."

**Every lead must carry a reason.** That is the difference between a database and a
sales system.

## 2. What Grandeur sells (the ICP fit test)

A lead is only good if Grandeur can plausibly provide one of:

- Outsourced accounting
- Bookkeeping
- NetSuite support
- QuickBooks / Xero accounting
- Financial reporting
- Month-end close
- AP / AR
- Fractional CFO
- Interim finance / accounting support
- White-label accounting support for recruitment and CPA firms

## 3. Target markets (priority order)

USA → UK → Australia → Germany → Canada → Singapore → UAE → Netherlands → Ireland →
New Zealand → France → Switzerland → Belgium → Sweden → Denmark → Norway → Spain →
Italy → Hong Kong → Japan → South Korea → Saudi Arabia → Qatar

Target volume is **not** a fixed "100 per country" — it is the *maximum identifiable
relevant* agencies/companies, with the strongest prospects prioritised.

## 4. The five lead engines

| # | Engine | What it finds | Why it matters |
|---|--------|---------------|----------------|
| 1 | **Recruitment Agency** | Finance/accounting recruitment firms | Can refer or outsource work to Grandeur. Seeded by the earlier international agency research. |
| 2 | **Hiring Signal** | Companies hiring Accountant, Senior Accountant, Controller, Finance Manager, Bookkeeper, AP/AR Manager, NetSuite Accountant, ERP Accountant, Fractional CFO, Finance Operations | An open finance req means a finance workload problem *right now*. |
| 3 | **ERP Signal** | Companies on NetSuite, QuickBooks Online, Xero, Sage Intacct, Business Central — especially those implementing, migrating, or growing | Direct match to Grandeur's ERP expertise. |
| 4 | **E-commerce** | Sellers on Shopify, Amazon, TikTok Shop, WooCommerce, other marketplaces | Multi-country / multi-channel accounting complexity. Flagged as *particularly valuable*. |
| 5 | **CPA / Accounting Firm Partnership** | US/UK/AU/EU accounting firms needing white-label offshore capacity | A completely separate outbound channel. |

## 5. The seven-agent pipeline (Phase 1)

```
Agent 1 — Discover     Find new companies / opportunities
        ↓
Agent 2 — Verify       Remove duplicates, dead websites, irrelevant + poor-quality leads
        ↓
Agent 3 — Enrich       Company + decision-maker + legitimate business contact info
        ↓
Agent 4 — Qualify      Does Grandeur's service actually fit?
        ↓
Agent 5 — Score        Rank 0-100
        ↓
Agent 6 — Personalize  Short, human outreach angle based on the actual trigger
        ↓
Agent 7 — Deliver      Push qualified leads to the master database / CRM
```

## 6. Full target architecture

```
                    GRANDEUR AI BD AGENT
                           │
          ┌────────────────┼────────────────┐
          ↓                ↓                ↓
     Lead Discovery   Company Research   Job Signals
          │                │                │
          └────────────────┼────────────────┘
                           ↓
                    Lead Qualification
                           ↓
                    Contact Enrichment
                           ↓
                      Lead Scoring
                           ↓
                    Personalized Pitch
                           ↓
                   CRM / Lead Database
                           ↓
                     Human Approval      ← hard gate, never removed
                           ↓
                        Outreach
                           ↓
                   Follow-up Tracking
                           ↓
                     Reply Detection
                           ↓
                   Meeting Opportunity
```

## 7. What the agent must investigate per lead

**Company** — industry, country, revenue/size, website, accounting/ERP stack, growth
signals, number of finance employees

**Opportunity** — what they're hiring for, why they might need extra accounting
capacity, whether the role is remote, whether outsourcing makes sense

**Decision maker** — CFO, Controller, VP Finance, Founder/CEO, Head of Finance,
Accounting Manager

**Contact** — LinkedIn, business email where legitimately available, company website,
source/job URL, date identified

## 8. Lead scoring bands

| Score | Meaning |
|-------|---------|
| 90–100 | 🔥 Immediate outreach |
| 75–89 | High potential |
| 60–74 | Worth nurturing |
| <60 | Low priority |

## 9. Target output format

```
🔥 Lead #127 — Priority 94/100
Company:        XYZ Commerce
Country:        USA
Industry:       E-commerce
Signal:         Hiring Senior Accountant
ERP:            NetSuite
Complexity:     Multi-channel / multi-entity
Likely need:    Month-end close + NetSuite accounting support
Decision Maker: CFO
Contact:        Verified business contact
Source:         Job posting
Why Grandeur:   Strong match with NetSuite + e-commerce accounting expertise
Approach:       Offer flexible accounting capacity rather than another full-time hire
```

## 10. Master lead database schema (target)

```
Lead ID | Company | Country | Industry | Website | Contact | Title | Email | LinkedIn |
Trigger | ERP | Services Required | Source | Source Date | Lead Score | Priority |
Personalised Pitch | Status | Last Contact | Follow-up Date | Response | Meeting | Outcome
```

## 11. Phasing

**Phase 1 — Lead Intelligence Engine** *(current)*
`Find → Verify → Enrich → Qualify → Score → Personalize → Database`
Build this and make it reliable before any automated outreach.

**Phase 2 — Autonomous operation**
Every morning: search → research → dedupe → score → prepare outreach → update database.
Dashboard shows e.g.:

```
Today's Leads: 47
🔥 Priority: 8   🟢 High: 19   🟡 Medium: 20
New NetSuite opportunities: 11
New recruitment agencies: 14
New CPA firm prospects: 9
E-commerce prospects: 13
```

**Phase 3 — Outreach loop**
Outreach → Follow-ups → Reply analysis → Meeting booking → Pipeline management

## 12. Standing principles

1. **Human approval before any outbound communication.** Non-negotiable — protects the
   brand from becoming "a spam cannon."
2. **Never invent data.** The AI must return `""` for unknown fields, never a guess.
3. **Every lead carries a reason** tied to a real, observed trigger.
4. **Update, never blind-append** — the duplicate-company problem is a known hazard.
5. **Preserve working baselines** before modifying architecture.
6. The earlier international recruitment-agency research becomes the **seed database**,
   not discarded work.
7. **Send window: 15:00–02:00 IST, Monday to Friday.** No outbound email leaves outside
   that window. Owner rule, set 2026-08-26. The window spans midnight deliberately — it
   tracks the US working day, which is where the target markets are. Enforced twice: the
   sender's schedule only polls inside it, and `Build Send Queue` re-checks the clock and
   queues nothing outside it, so a manual run cannot bypass the rule.
