# Business Capability Map — Dealer-Incentive Claims Platform

## How this was indexed

The estate was inventoried directly from the repository tree and cross-referenced
with DeepWiki (note: repo not yet indexed by DeepWiki; manual deep-read was used
as fallback).

| Category | Count | Artifacts |
|----------|-------|-----------|
| COBOL programs | 8 | INCMAIN, INCEDIT, INCEXC, INCVAL, INCELIG, INCCALC, INCPAY, INCREV |
| Copybooks | 7 | CLAIMREC, DEALERREC, PROGREC, PAYOUTREC, INCRESULT, INCCONST, ERRCODES |
| JCL members | 2 | INCDAILY, INCGLFD |
| Cataloged proc | 1 | INCPROC |
| DB2 stored procs | 2 | SP_ELIGIBILITY, SP_RATE_LOOKUP |
| DB2 DDL/DCLGEN | 2 | SCHEMA.sql, DCLCLAIM.cpy |
| Front-end (Struts) | 4 | ClaimEntryAction.java, ClaimForm.java, claimEntry.jsp, struts-config.xml |
| Front-end (Spring) | 1 | ClaimController.java (partial migration) |
| Scheduler / control | 2 | SCHEDULE.txt, INCPARM.txt |

### Call / Job graph at a glance

```
Scheduler: INCFEED -> INCDAILY -+-> INCGLFD (ON RC INCDAILY EQ 0)
                               |       \-> INCMTH (RUNAFTER INCGLFD AND ON LASTWORKDAY)
                               +-> INCREP  (payout + exception reports)

INCDAILY.jcl STEP010 (PGM=INCMAIN):
  INCMAIN
    -> INCEDIT  (structural validation)
    -> INCEXC   (duplicate screen)
    -> INCVAL   (dealer checks)
       -> INCELIG  (program eligibility)
    -> INCCALC  (pricing)
    -> INCPAY   (payout method)
    -> INCREV   (reversal/clawback)
       -> INCCALC  (reprice for clawback)
```

---

## Business Capabilities

### 1. Claim Intake

> The system receives a daily flat-file feed of dealer-submitted vehicle-sale
> incentive claims. Each claim represents a dealer asking for a payment tied to
> a sold vehicle under a specific incentive program.

| | |
|---|---|
| **Artifacts** | `INCMAIN` 1000-INIT (opens CLAIM file); JCL DD `CLAIMS`; scheduler job `INCFEED` stages the feed |
| **Inputs** | `OEM.INCENT.CLAIMS(+0)` — daily claim flat file (80-byte CLAIMREC layout) |
| **Outputs** | In-memory claim record ready for pipeline processing |

### 2. Structural Validation (Field Edits)

> Before any business rules run, each claim is checked for data quality: non-blank
> identifiers, valid date format, positive sale price, and a recognised claim type.
> Invalid records are rejected immediately.

| | |
|---|---|
| **Artifacts** | `INCEDIT` 0000-MAIN, 1000-CHECK-DATE-PARTS; reason code `EDIT` |
| **Inputs** | CLAIM-REC (linkage) |
| **Outputs** | ELIG-RESULT: RC 00 (pass) or RC 90 + reason `EDIT` (reject) |

### 3. Duplicate Control (Exception Screening)

> A claim is flagged as a duplicate if the same VIN + Program combination was
> already paid in the current run. Duplicates are held (not rejected) so an
> analyst can manually adjudicate them in the exception queue.

| | |
|---|---|
| **Artifacts** | `INCMAIN` 7000-CHECK-DUPLICATE (builds in-core paid-key table); `INCEXC` 0000-MAIN; reason code `DUP` |
| **Inputs** | CLAIM-REC, WS-DUP-FLAG (from INCMAIN table scan) |
| **Outputs** | ELIG-RESULT: RC 00 (pass) or RC 30 + reason `DUP` (hold) |

### 4. Dealer Eligibility

> A claim is only payable if the submitting dealer exists in the master, is
> enrolled in the incentive program, and has an active status. Failures are
> held for research.

| | |
|---|---|
| **Artifacts** | `INCMAIN` 7100-LOOKUP-DEALER; `INCVAL` 0000-MAIN (EVALUATE: DEALER-WAS-FOUND, DLR-IS-ENROLLED, DLR-IS-INACTIVE); reason codes `DLRN`, `DLRE`, `DLRI` |
| **Inputs** | CLAIM-REC, DEALER-REC (from in-core table), LK-FOUND-FLAGS |
| **Outputs** | ELIG-RESULT: RC 10–12 + reason on failure; pass-through to INCELIG on success |

### 5. Program Eligibility

> The sale must fall within the program's valid date window, the dealer's region
> must match (or the program is region-unrestricted), and loyalty programs
> require proof of prior vehicle ownership. First failure wins.

| | |
|---|---|
| **Artifacts** | `INCELIG` 1000-CHECK-WINDOW, 2000-CHECK-REGION, 3000-CHECK-LOYALTY; DB2 `SP_ELIGIBILITY` (online mirror — missing loyalty rule); reason codes `PRGW`, `RGNX`, `LOYX` |
| **Inputs** | CLAIM-REC, PROGRAM-REC, DEALER-REC |
| **Outputs** | ELIG-RESULT: RC 21–23 + reason on failure |

### 6. Incentive Pricing (Calculation)

> Computes the dollar amount the OEM owes. Flat programs pay a fixed amount;
> percentage programs apply a rate to the sale price. Loyalty claims on
> stackable programs add a $500 bonus. The result is capped first at the
> program-level maximum, then at the global $10,000 ceiling.

| | |
|---|---|
| **Artifacts** | `INCCALC` 1000-COMPUTE-BASE, 2000-APPLY-LOYALTY, 3000-APPLY-CAPS; copybook `INCCONST` (WC-GLOBAL-PAYOUT-CAP = $10,000, WC-LOYALTY-BONUS = $500); DB2 `SP_RATE_LOOKUP` (online mirror, reads PARM table for cap) |
| **Inputs** | CLAIM-REC, PROGRAM-REC |
| **Outputs** | CALC-RESULT: CALC-AMOUNT (signed numeric), CALC-CAPPED flag |

### 7. Payout Disbursement (Method / Payee)

> Determines how the money reaches the recipient. Dealer-paid programs create a
> credit memo. Customer-paid programs use ACH if a bank account is on file,
> otherwise a mailed check.

| | |
|---|---|
| **Artifacts** | `INCPAY` 0000-MAIN |
| **Inputs** | CLAIM-REC (CLM-CUST-BANK), PROGRAM-REC (PRG-PAYEE) |
| **Outputs** | PAY-RESULT: PAYR-METHOD (CREDIT/ACH/CHECK), PAYR-PAYEE-TYPE (D/C) |

### 8. Reversal / Clawback

> When a sale is unwound (claim type REVERSAL), the original incentive is
> recalculated and negated. The loyalty stack bonus is NOT clawed back
> (Policy 7.1) — the claim type is forced to RETAIL before re-pricing.

| | |
|---|---|
| **Artifacts** | `INCMAIN` 6000-HANDLE-REVERSAL; `INCREV` 0000-MAIN; calls `INCCALC` with forced RETAIL type |
| **Inputs** | CLAIM-REC, PROGRAM-REC |
| **Outputs** | CALC-RESULT with negative CALC-AMOUNT; payout status `RVSD` |

### 9. General-Ledger Feed

> After all claims are adjudicated, PAID and RVSD records are extracted from the
> payout register, sorted by program + claim ID, and written as debit/credit
> transactions for the downstream GL system. HOLD and REJ records are excluded.

| | |
|---|---|
| **Artifacts** | `INCGLFD.jcl` STEP010 (SORT with INCLUDE COND); scheduler job `INCGLFD` |
| **Inputs** | `OEM.INCENT.PAYOUT(+0)` (output of INCDAILY) |
| **Outputs** | `OEM.INCENT.GLFEED(+1)` — sorted PAID/RVSD payout records |
