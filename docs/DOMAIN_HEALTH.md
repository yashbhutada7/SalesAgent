# Domain Health — `grandeuradvisory.com`

Checked **2026-08-27** against the authoritative Route 53 nameservers
(`ns-9.awsdns-01.com` and friends), not just a cached resolver.

This matters to the BD agent directly: the Outreach Sender sends cold B2B mail as
`accounting@grandeuradvisory.com` through Outlook. Two of the findings below are the
difference between the inbox and the spam folder.

---

## Verdict

| Area | State |
|---|---|
| DNS hosting | ✅ Route 53, four NS delegated, SOA clean |
| Mail routing (MX) | ✅ Microsoft 365, correct single MX |
| SPF | ✅ Correct and strict — 1 of 10 lookups used |
| **DKIM** | 🔴 **Not configured for the domain** |
| **DMARC** | 🔴 **No record at all** |
| `www` | 🟠 Does not resolve — NXDOMAIN |
| `autodiscover` | 🟠 Broken CNAME, points at a dead ACM target |
| Domain reputation | ✅ Not listed on Spamhaus DBL, SURBL or URIBL |
| CAA / DNSSEC / MTA-STS | ⚪ Absent — hardening, not breakage |

Tenant confirmed as **`grandeuradvisory.onmicrosoft.com`** (verified via its MX record) —
that is what the DKIM values below are built from.

---

## What is actually published today

```
grandeuradvisory.com          NS     ns-9.awsdns-01.com, ns-632.awsdns-15.net,
                                     ns-1361.awsdns-42.org, ns-1957.awsdns-52.co.uk
grandeuradvisory.com          A      18.238.176.28/71/93/101   (CloudFront)
grandeuradvisory.com          MX     0 grandeuradvisory-com.mail.protection.outlook.com
grandeuradvisory.com          TXT    "v=spf1 include:spf.protection.outlook.com -all"
autodiscover                  CNAME  _35baef5e609bba02792c9bd70593a8cb.mhbtsbpdnt.acm-validations.aws
```

Everything else queried came back **NXDOMAIN**: `www`, `_dmarc`, `selector1._domainkey`,
`selector2._domainkey`, `_mta-sts`, `_smtp._tls`, `default._bimi`, `lyncdiscover`,
`enterpriseregistration`, `enterpriseenrollment`, and the SIP/autodiscover SRV records.
No `AAAA`, no `CAA`, no `DS`.

---

## 1. No DKIM on the sending domain 🔴

`selector1._domainkey.grandeuradvisory.com` and `selector2._domainkey.grandeuradvisory.com`
do not exist. With no custom-domain DKIM published, Exchange Online falls back to signing
outbound mail with the tenant's default key, so the signature carries
`d=grandeuradvisory.onmicrosoft.com` — **not** `grandeuradvisory.com`.

That signature is valid, but it is not *aligned*: to a receiver running DMARC, the DKIM
identity does not match the From: domain, so DKIM contributes nothing. Every outreach mail
is currently leaning on SPF alone, and SPF breaks the moment a message is forwarded or
passes through a mailing list.

### Fix — two records in Route 53

| Name | Type | Value |
|---|---|---|
| `selector1._domainkey.grandeuradvisory.com` | CNAME | `selector1-grandeuradvisory-com._domainkey.grandeuradvisory.onmicrosoft.com` |
| `selector2._domainkey.grandeuradvisory.com` | CNAME | `selector2-grandeuradvisory-com._domainkey.grandeuradvisory.onmicrosoft.com` |

Then turn signing on — the records alone do nothing:

**security.microsoft.com** → Email & collaboration → Policies & rules → Threat policies →
Email authentication settings → **DKIM** → select `grandeuradvisory.com` → toggle
**Sign messages for this domain with DKIM signatures** to on.

Needs Global Admin or Exchange Admin. If the toggle errors with "CNAME record does not
exist", DNS has not propagated yet — wait and retry.

**Verify:** send to a Gmail address, open the message → Show original → `DKIM: 'PASS' with
domain grandeuradvisory.com`. The domain must read `grandeuradvisory.com`, not the
`onmicrosoft.com` one.

---

## 2. No DMARC record 🔴

`_dmarc.grandeuradvisory.com` is NXDOMAIN. There is no policy telling receivers what to do
with mail that fails authentication, and no reporting stream showing who is sending as the
domain.

Since February 2024 Google and Yahoo have required a DMARC record from bulk senders, and
Microsoft applied the same requirement to high-volume senders into Outlook/Hotmail in May
2025. Volume here is deliberately low, so this is unlikely to be a hard block today — but
for cold outreach, an unauthenticated domain is one of the cheapest spam signals a filter
can act on. It also leaves the domain open to being spoofed with no visibility.

### Fix — start in monitor mode

| Name | Type | Value |
|---|---|---|
| `_dmarc.grandeuradvisory.com` | TXT | `v=DMARC1; p=none; rua=mailto:dmarc-reports@grandeuradvisory.com; fo=1; adkim=r; aspf=r` |

`p=none` changes nothing about delivery — it only starts the reports. That is deliberate:
publishing `p=reject` before DKIM is aligned and verified would kill legitimate mail.

**Do DKIM first.** Order matters: publish the DKIM CNAMEs, enable signing, confirm a Gmail
`DKIM: PASS` on `grandeuradvisory.com`, *then* add DMARC.

Two notes on the `rua` address:

- The mailbox must exist and accept external mail. If `dmarc-reports@` is not worth
  creating, point it at `info@grandeuradvisory.com`.
- Raw aggregate reports are gzipped XML and genuinely unpleasant to read by hand. A free
  aggregator (Postmark's DMARC Digests, dmarcian, Valimail) turns them into a weekly
  summary — worth doing before the first report lands.

### Then tighten, on a schedule

| When | Policy |
|---|---|
| After ~2–4 weeks of clean reports | `p=quarantine; pct=25` → step to `pct=100` |
| After another clean 2 weeks | `p=reject` |

Do not skip the monitoring window. The reports are what reveal any sending source nobody
remembered — a form handler, an invoicing tool, a booking page.

---

## 3. `www.grandeuradvisory.com` does not resolve 🟠

The apex serves from CloudFront, but `www` returns NXDOMAIN from the authoritative
nameservers. Anyone who types or pastes `www.grandeuradvisory.com` gets a browser error.

For a firm sending cold outreach this is worse than a normal broken link: a prospect who
gets an unexpected mail looks the sender up before replying, and some security gateways
fetch the sender's site as a reputation signal. A dead hostname is an avoidable own goal.

### Fix — in AWS, in this order

1. **ACM (us-east-1)** — the certificate on the distribution must cover
   `www.grandeuradvisory.com`. CloudFront only reads certificates from us-east-1,
   whatever region the rest of the stack lives in.
2. **CloudFront** — add `www.grandeuradvisory.com` to the distribution's *Alternate domain
   names (CNAMEs)*.
3. **Route 53** — add `www` as an **A record, Alias**, target = the CloudFront
   distribution. Add the AAAA alias too while there.

Decide whether `www` should redirect to the apex or serve the same content. A redirect is
cleaner for SEO; either beats NXDOMAIN.

*(I could not fetch the site itself to confirm what the apex serves — outbound HTTPS from
the session is filtered by an egress policy, and the TLS handshake I got back was the
proxy's own certificate, not the real one. The DNS findings above are unaffected: those
came over plain DNS straight from Route 53.)*

---

## 4. `autodiscover` is a broken record 🟠

```
autodiscover.grandeuradvisory.com  CNAME  _35baef5e609bba02792c9bd70593a8cb.mhbtsbpdnt.acm-validations.aws
```

That target resolves to nothing, so the hostname is dead. Two separate problems in one
record:

**It is in the wrong place.** ACM validation records are named `_<hash>.<domain>` — the
hash belongs in the *name*, not just the value. Someone pasted the ACM value against a
plain `autodiscover` name, so whichever certificate request this was for never validated.

**It is occupying a name Microsoft 365 needs.** For Outlook desktop and mobile to
auto-configure a mailbox, this should be `CNAME autodiscover.outlook.com`. Modern Outlook
has other discovery paths and mail is flowing, so this is not an outage — but manual server
setup on every new device is a real cost, and it will bite on the next laptop or phone.

### Fix

1. **Check ACM first.** If a certificate request covering `autodiscover.grandeuradvisory.com`
   is still pending validation, either recreate its validation record with the correct
   `_<hash>.autodiscover...` name or delete the request. Removing a validation record that
   an *issued, in-use* certificate still needs will break its renewal — so look before
   deleting.
2. Then repoint the record:

| Name | Type | Value |
|---|---|---|
| `autodiscover.grandeuradvisory.com` | CNAME | `autodiscover.outlook.com` |

---

## 5. SPF is correct — leave it alone ✅

```
v=spf1 include:spf.protection.outlook.com -all
```

Strict `-all`, and one DNS-lookup mechanism against the limit of ten. Nothing to fix.

One standing constraint: `-all` means **anything not sent through Microsoft 365 will fail
SPF outright**. Today the Outreach Sender goes through the Outlook node on delegated OAuth,
so it is inside the tenant and passes. If outbound mail ever moves to direct SMTP from n8n,
or to a sequencing tool, or a transactional provider, that provider must be added to this
record *before* the switch, not after.

---

## 6. Hardening, when there is time ⚪

| Gap | Record | Why |
|---|---|---|
| No CAA | `grandeuradvisory.com CAA 0 issue "amazon.com"` + `0 iodef "mailto:info@grandeuradvisory.com"` | Restricts which CAs may issue for the domain. Add every CA actually in use first — a CAA record that omits one blocks its renewals. |
| No TLS-RPT | `_smtp._tls TXT "v=TLSRPTv1; rua=mailto:tlsrpt@grandeuradvisory.com"` | Reports on failed inbound TLS. No delivery risk, pure visibility. |
| No MTA-STS | `_mta-sts TXT` + a policy file at `https://mta-sts.grandeuradvisory.com/.well-known/mta-sts.txt` | Enforces TLS on inbound mail. Needs a hosted file, so it is a project rather than a record. |
| No DNSSEC | Route 53 signing + DS at the registrar | Nice to have; the smallest win of the four. |
| No AAAA | Alias on the CloudFront distribution | IPv6-only clients. Free once the `www` work is being done anyway. |

---

## 7. A strategic note on sending cold mail from this domain

Every finding above is worth fixing on its own merits. But the BD agent introduces a risk
DNS cannot fix: `grandeuradvisory.com` is both the firm's primary mail domain and now its
cold-outreach domain. Spam complaints against outreach land on the same reputation that
carries client mail, invoices and engagement letters.

The usual mitigation is a separate sending domain — a lookalike such as
`grandeuradvisory.co` or `grandeur-advisory.com`, authenticated the same way, used only for
outreach. Sender reputation damage then stays contained.

That is a decision, not a defect, and it is not urgent at the current volume. Raising it
here so it is chosen deliberately rather than discovered after a deliverability problem.

---

## Suggested order of work

1. DKIM CNAMEs → enable signing → verify `DKIM: PASS` on `grandeuradvisory.com` **(do this first)**
2. DMARC at `p=none` + a report aggregator
3. `autodiscover` — check ACM, then repoint to `autodiscover.outlook.com`
4. `www` — ACM cert, CloudFront alias, Route 53 alias record
5. Watch DMARC reports for 2–4 weeks, then step to `p=quarantine`, then `p=reject`
6. CAA and TLS-RPT whenever the console is open anyway

Steps 1–2 are the ones that affect whether outreach reaches an inbox. The rest is
housekeeping.

---

## How to re-check

DNS only, no credentials needed. Against the authoritative nameserver so results are not
cached:

```bash
dig +short @ns-9.awsdns-01.com grandeuradvisory.com TXT
dig +short @ns-9.awsdns-01.com _dmarc.grandeuradvisory.com TXT
dig +short @ns-9.awsdns-01.com selector1._domainkey.grandeuradvisory.com CNAME
dig +short @ns-9.awsdns-01.com autodiscover.grandeuradvisory.com CNAME
dig +short @ns-9.awsdns-01.com www.grandeuradvisory.com A
```
