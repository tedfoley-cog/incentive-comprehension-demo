# Compliance View

*Eligibility and duplicate controls, the audit trail, and the online/batch
drift as a control gap.*

---

## Control Framework Overview

The incentive platform enforces a layered set of controls to prevent incorrect
or fraudulent payouts. These operate at two levels:

1. **Online (point of entry)** — immediate feedback via `SP_ELIGIBILITY`
2. **Batch (system of record)** — comprehensive validation via INCMAIN pipeline

The batch layer is strictly **more restrictive** than the online layer due to
known drift (documented below).

---

## Eligibility Controls

| Control | Online (SP_ELIGIBILITY) | Batch (INCVAL → INCELIG) | Gap? |
|---------|------------------------|--------------------------|------|
| Dealer exists | Implicit (JOIN fails) | Explicit check (DLRN) | No |
| Dealer enrolled | Yes (DLRE) | Yes (DLRE) | No |
| Dealer active | Yes (DLRI) | Yes (DLRI) | No |
| Program exists | Implicit (JOIN fails) | Explicit check (PRGN) | No |
| Sale date within window | Yes (PRGW) | Yes (PRGW) | No |
| Region match | Yes (RGNX) | Yes (RGNX) | No |
| Loyalty / prior ownership | **NO** | Yes (LOYX) | **YES — CONTROL GAP** |

### Control Gap: Loyalty Rule (HIGH risk)

The online path (Struts `ClaimEntryAction` / Spring `ClaimController`) does NOT
enforce the loyalty/prior-ownership check. A dealer can submit a loyalty claim
online, receive an "eligible" response, and only discover the hold the next day
after the batch rejects it.

**Impact**: Dealers acting on the false "eligible" signal may promise customers
an incentive that will never be paid. This creates operational friction and
potential regulatory exposure if the OEM's dealer agreements mandate accurate
real-time eligibility responses.

**Recommendation**: Add the loyalty check to `SP_ELIGIBILITY` to close the gap,
or clearly label the online response as "preliminary."

---

## Duplicate Control

Duplicate detection is performed **within a single batch run only**:

- Key: VIN + PROGRAM-ID (23 bytes)
- Maintained in an in-core table by INCMAIN (`7000-CHECK-DUPLICATE`)
- Same-day duplicates are held (not rejected) with reason `DUP`
- Cross-day duplicates are NOT detected by this mechanism

**Limitation**: If the same VIN+Program was paid in a prior day's run, the
current duplicate control will not catch it. Cross-run duplicate detection
would require a persistent paid-claims database or a cumulative GDG lookup.

---

## Structural Edit Controls

`INCEDIT` rejects claims with:
- Blank claim ID or VIN
- Zero or invalid sale date (month > 12, day > 31)
- Zero sale price
- Unrecognised claim type (must be RETAIL/CUSTCASH/LOYALTY/REVERSAL)

These are **also partially duplicated** in the Struts `ClaimForm.validate()`
method (blank claimId, VIN length != 17, blank salePrice), creating another
minor online/batch duplication.

---

## Payout Caps (Spend Protection)

Two caps limit exposure:

1. **Program-level cap** (`PRG-MAX-INCENTIVE`): Per-program maximum defined in
   the program master.
2. **Global cap** (`WC-GLOBAL-PAYOUT-CAP` = $10,000): System-wide ceiling on
   any single payout, regardless of program.

Both are enforced in `INCCALC` 3000-APPLY-CAPS. The CALC-CAPPED flag is set
when either cap triggers, providing an audit signal.

### Cap Value Governance Risk

The global cap value exists in **three independent sources** with no automated
synchronisation:
- COBOL copybook `INCCONST` (compile-time constant)
- DB2 `PARM` table row `GCAP` (runtime-readable)
- JCL control card `INCPARM.txt` (not programmatically consumed)

A change to one without the others creates silent divergence between batch and
online pricing.

---

## Audit Trail

| Event | Record | Audit signal |
|-------|--------|--------------|
| Claim paid | PAYOUT-REC, status=PAID | Positive amount, GL credit |
| Claim held | PAYOUT-REC, status=HOLD | Zero amount, reason code identifies the failing rule |
| Claim rejected | PAYOUT-REC, status=REJ | Zero amount, reason=EDIT |
| Clawback | PAYOUT-REC, status=RVSD | Negative amount, GL debit |

The payout register (`OEM.INCENT.PAYOUT`) is a GDG, so historical generations
are preserved for audit. The downstream GL feed (`INCGLFD`) extracts only PAID
and RVSD records — HOLD and REJ records remain in the payout register only.

---

## Recommendations for Control Improvement

1. **Close the loyalty gap**: Add `3000-CHECK-LOYALTY` equivalent to
   `SP_ELIGIBILITY` so online and batch agree.
2. **Cross-run duplicate detection**: Extend the duplicate screen to query
   historical payout records (or a cumulative VIN+Program paid index).
3. **Single source for cap values**: Migrate to reading the DB2 PARM table at
   batch runtime (eliminate the compiled constant and the dead control card).
4. **CALC-CAPPED audit**: Surface capped claims in the exception report so
   finance can review whether caps are set correctly.
