# Cross-Artifact Linkage — Logic Drift & Duplication

This document identifies rules that are implemented in more than one place and
have drifted apart, creating control gaps and reconciliation risk.

---

## 1. Eligibility Date Window

### Where it lives

| Layer | Location | Logic |
|-------|----------|-------|
| **Batch (COBOL)** | `INCELIG.cbl` paragraph `1000-CHECK-WINDOW` | `IF CLM-SALE-DATE < PRG-START-DATE OR CLM-SALE-DATE > PRG-END-DATE` → reject PRGW |
| **Online (DB2)** | `SP_ELIGIBILITY.sql` line 62 | `IF V_SALE_DATE < V_PRG_START OR V_SALE_DATE > V_PRG_END` → reject PRGW |

### Assessment: IDENTICAL (no drift)

Both implementations use the same inclusive-range logic (`< start OR > end`).
The DB2 procedure uses DATE typed comparison; COBOL uses numeric CCYYMMDD
comparison. The semantic result is identical for all valid dates.

### Risk

Low — the two copies are functionally equivalent today. However, any future
change to the window logic must be applied to both or they will silently diverge.

---

## 2. Loyalty / Prior-Ownership Rule (BATCH-ONLY — ONLINE DRIFT)

### Where it lives

| Layer | Location | Logic |
|-------|----------|-------|
| **Batch (COBOL)** | `INCELIG.cbl` paragraph `3000-CHECK-LOYALTY` | If program requires prior-ownership (`PRG-REQ-LOYALTY`) and claim does not have it (`NOT CLM-HAS-PRIOR-OWN`), reject with `LOYX` |
| **Online (DB2)** | `SP_ELIGIBILITY.sql` | **NOT PRESENT** — commented as "intentionally absent" (line 73–74) |

### Assessment: DRIFTED — online path does NOT enforce loyalty rule

A dealer submitting a loyalty-program claim through the online UI
(`ClaimEntryAction` / `ClaimController`) will receive an "eligible" response
from `SP_ELIGIBILITY` even without prior ownership. The claim will then fail in
the nightly batch with hold-code `LOYX`.

### Risk: HIGH

- **False positive at point of sale**: Dealers see "eligible" online, then
  discover the claim is held after batch runs — causing rework and confusion.
- **Control gap**: The online tier is a weaker gate than batch, meaning the
  real eligibility surface is only enforced after the fact.
- **Root cause**: The Struts → Spring migration copied `SP_ELIGIBILITY` as-is
  without adding the missing loyalty check (see `ClaimController.java` comment).

---

## 3. Global Payout Cap — Triple Duplication

The system-wide $10,000 ceiling on any single payout exists in three places:

| Source | Location | Value |
|--------|----------|-------|
| **COBOL copybook** | `INCCONST.cpy` → `WC-GLOBAL-PAYOUT-CAP` | `0010000.00` ($10,000) |
| **DB2 PARM table** | `SCHEMA.sql` → `INSERT INTO PARM ('GCAP', 10000.00)` | $10,000 |
| **JCL control card** | `INCPARM.txt` line `GC 0010000.00` | $10,000 |

### How each is consumed

- **Batch**: `INCCALC.cbl` 3000-APPLY-CAPS uses `WC-GLOBAL-PAYOUT-CAP` from
  the compiled copybook. The `//INCPARM` DD is allocated in `INCPROC.prc` but
  the current COBOL source does NOT read it at runtime — it's a documentation
  artefact / planned extension.
- **Online**: `SP_RATE_LOOKUP.sql` reads `PARM('GCAP')` at execution time.
- **Control card**: `INCPARM.txt` line GC is referenced by operations but not
  programmatically consumed by the current batch programs.

### Assessment: VALUES IN SYNC today ($10,000 everywhere)

The three sources currently hold the same value. But they have **no automated
sync mechanism** — a DBA can update `PARM('GCAP')` without changing the copybook
(requires a recompile) or the control card (manually maintained).

### Risk: MEDIUM-HIGH

- A unilateral change to any one source causes silent divergence between batch
  and online pricing.
- The control card creates a false sense of governance: operators believe it
  controls the cap, but it is not read by any program.

---

## 4. Loyalty Bonus Amount — Triple Duplication

The $500 loyalty-stack bonus parallels the global cap pattern:

| Source | Location | Value |
|--------|----------|-------|
| **COBOL copybook** | `INCCONST.cpy` → `WC-LOYALTY-BONUS` | `0000500.00` ($500) |
| **DB2 PARM table** | `SCHEMA.sql` → `INSERT INTO PARM ('LBON', 500.00)` | $500 |
| **JCL control card** | `INCPARM.txt` line `LB 0000500.00` | $500 |

### How each is consumed

- **Batch**: `INCCALC.cbl` 2000-APPLY-LOYALTY uses `WC-LOYALTY-BONUS`.
- **Online**: `SP_RATE_LOOKUP.sql` does NOT add a loyalty bonus (it only
  computes base + caps). So this value is batch-only in practice.
- **Control card**: Not programmatically read.

### Assessment: VALUES IN SYNC today but the online path NEVER applies the bonus

This is a second dimension of online/batch drift: a loyalty claim processed
online will be quoted without the $500 bonus, while the batch will add it.

### Risk: MEDIUM

- Not a control failure (batch is the system of record for pricing), but it
  causes a discrepancy between the online "estimated amount" and the final
  payout, confusing dealers.

---

## Summary Table

| Rule | Truth Source | Copies | Drift? | Risk |
|------|-------------|--------|--------|------|
| Eligibility date window | INCELIG (batch) | SP_ELIGIBILITY (online) | No | Low |
| Loyalty rule | INCELIG 3000-CHECK-LOYALTY (batch) | **Missing online** | **Yes** | **High** |
| Global payout cap ($10K) | INCCONST (compile-time) | PARM('GCAP'), INCPARM GC | Values match; no sync mechanism | Medium-High |
| Loyalty bonus ($500) | INCCONST (compile-time) | PARM('LBON'), INCPARM LB | Values match; online never applies bonus | Medium |
