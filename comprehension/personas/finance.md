# Finance View

*How PAID/RVSD records become GL debits/credits, the payout methods, and where
the caps protect spend.*

---

## From Payout Register to General Ledger

The nightly `INCDAILY` job produces the **payout register** — one record per
processed claim. The downstream `INCGLFD` job extracts the financially relevant
records and feeds them to the General Ledger.

### GL feed logic (`INCGLFD.jcl`)

```
INCLUDE COND=(40,4,CH,EQ,C'PAID',OR,40,4,CH,EQ,C'RVSD')
SORT FIELDS=(34,6,CH,A,1,10,CH,A)
```

- **Included**: PAID and RVSD records only (byte positions 40–43 = PAY-STATUS)
- **Excluded**: HOLD and REJ records (no financial impact until resolved)
- **Sorted by**: Program ID (ascending) then Claim ID (ascending)

### Debit / Credit mapping

| PAY-STATUS | PAY-AMOUNT | GL Effect |
|------------|-----------|-----------|
| PAID | Positive (e.g. +000075000 = $750.00) | **Credit** to incentive expense accrual |
| RVSD | Negative (e.g. -000075000 = -$750.00) | **Debit** (recovery) to incentive expense |

The PAY-AMOUNT field uses sign-leading-separate format (first character is `+`
or `-`), followed by 7 integer digits and 2 implied decimal digits.

---

## Payout Methods

| Method | Payee | Financial flow |
|--------|-------|----------------|
| CREDIT | Dealer (D) | Credit memo applied to the dealer's OEM account; netted against future purchases |
| ACH | Customer (C) | Electronic funds transfer to customer's bank account |
| CHECK | Customer (C) | Physical check mailed to customer (fallback when no bank on file) |

Method determination is in `INCPAY`:
- PRG-PAYEE = 'D' → always CREDIT to dealer
- PRG-PAYEE = 'C' + customer has bank on file → ACH
- PRG-PAYEE = 'C' + no bank → CHECK

---

## Incentive Calculation Logic

### Base calculation (`INCCALC`)

| Program Type | Formula | Example |
|--------------|---------|---------|
| FLAT | Amount = `PRG-FLAT-AMOUNT` | PFLAT1: $750 flat |
| PCT | Amount = `CLM-SALE-PRICE * PRG-PCT-RATE / 100` | PCAP01: 50% of sale price |

### Loyalty stack bonus

If the claim type is LOYALTY **and** the program is flagged as stackable
(`PRG-IS-STACKABLE = 'Y'`), an additional **$500** (`WC-LOYALTY-BONUS`) is
added to the base amount.

Example: Claim C000000004 — PLOYL1 program (PCT, 2%, stackable, dealer-paid)
- Sale price: $40,000.00
- Base: $40,000 * 2% = $800.00
- Loyalty bonus: +$500.00
- Gross: $1,300.00
- Payout: +000130000 (confirmed in harness output)

---

## Spend Protection: Cap Structure

### Two-tier cap enforcement (in order)

1. **Program cap** (`PRG-MAX-INCENTIVE`): Each program defines its own ceiling.
   If the computed amount exceeds it, the amount is clamped down.

2. **Global cap** (`WC-GLOBAL-PAYOUT-CAP` = **$10,000**): Absolute system-wide
   ceiling. No single claim payout can ever exceed $10,000, regardless of
   program configuration.

Both are applied sequentially in `INCCALC` 3000-APPLY-CAPS. The `CALC-CAPPED`
flag is set if either cap fires.

### Example: Claim C000000017 (PGCAP1 — "Global Cap Stress")

- Program: PCT at 50%, max incentive = $99,999.99 (effectively unlimited)
- Sale price: $30,000
- Base: $30,000 * 50% = $15,000
- Program cap: $15,000 < $99,999.99 → no cap
- Global cap: $15,000 > $10,000 → **capped at $10,000**
- Payout: +001000000 ($10,000.00) — confirmed in harness

### Example: Claim C000000012 (PCAP01 — "High PCT Program Cap")

- Program: PCT at 50%, max incentive = $2,000
- Sale price: $30,000
- Base: $30,000 * 50% = $15,000
- Program cap: $15,000 > $2,000 → **capped at $2,000**
- Global cap: $2,000 < $10,000 → no global cap
- Payout: +000200000 ($2,000.00) — confirmed in harness

---

## Reversal (Clawback) Financial Impact

When a sale unwinds:
- A REVERSAL claim triggers `INCREV`, which recalculates the **base** incentive
  only (loyalty bonus excluded per Policy 7.1) and negates it.
- The resulting negative payout produces a GL **debit** (expense recovery).

Example: Claim C000000014 (reversal of VIN `1FORDDEMOA0010000` / PFLAT1)
- Original incentive was $750 (flat)
- Reversal recalculates as RETAIL (forcing away from LOYALTY type) → $750
- Negated: -$750
- Payout: -000075000 — confirmed in harness

**Policy 7.1 implication**: If the original claim earned a loyalty bonus, that
$500 is NOT recovered in the clawback. Finance absorbs this as a cost of the
loyalty programme design.

---

## Financial Summary by Status (from test fixture)

| Status | Count | Net amount | GL impact |
|--------|-------|-----------|-----------|
| PAID | 6 | +$15,050.00 | Credit to expense |
| RVSD | 1 | -$750.00 | Debit (recovery) |
| HOLD | 8 | $0 | No GL entry (pending adjudication) |
| REJ | 2 | $0 | No GL entry (structurally invalid; EDIT failures only) |

Computed from harness output (rejections never reach pricing, hence zero):
- PAID total: $750 + $500 + $500 + $1,300 + $2,000 + $10,000 = $15,050
- RVSD total: -$750
- Total claims: 6 PAID + 8 HOLD + 1 RVSD + 2 REJ = 17

---

## Governance Concerns

1. **Cap value is triple-duplicated** (copybook, DB2 PARM, control card) with no
   sync — a unilateral DB2 change would only affect online pricing, not batch.
2. **No aggregate cap**: There is no daily/monthly total-spend cap. The $10K
   limit is per-claim only. A spike in volume could exceed budget without
   triggering any control.
3. **HOLD claims are zero-amount**: Finance has no exposure to held claims until
   they're released — good for cash management, but held claims represent
   contingent liabilities that should be disclosed.
