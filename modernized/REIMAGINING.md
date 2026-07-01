# Reimagining the Dealer-Incentive Claim Path

## Slice covered

This conversion covers **one vertical slice**: the forward eligibility + pricing
decision for a single dealer-incentive claim, from structural validation through
payout-method determination, plus the reversal/clawback path.

---

## What changes

### Batch to synchronous

The legacy path is a nightly COBOL batch (`INCMAIN` driving `INCEDIT` / `INCEXC`
/ `INCVAL` / `INCELIG` / `INCCALC` / `INCPAY` / `INCREV`) that reads a
flat-file feed and writes a fixed-width payout register. The reimagined service
exposes the same decision as a synchronous REST endpoint:

```
POST /api/claims/process
{ claimId, vin, dealerId, programId, saleDate, salePrice, claimType, priorOwn, custBank }
  ->  { status, reasonCode, amount, method, payeeType }
```

This lets the online tier call the same rules at point-of-sale, eliminating the
gap where a dealer sees "eligible" from the weaker `SP_ELIGIBILITY` stored
procedure but the claim is held overnight.

### Copybook offsets to typed domain

Legacy fields are identified by byte offsets in 7 copybooks (`CLAIMREC`,
`PAYOUTREC`, `PROGREC`, `DEALERREC`, `INCRESULT`, `INCCONST`, `ERRCODES`).
Implied decimals (`PIC 9(07)V99`), condition-name flags (`88 CLM-LOYALTY`), and
sign conventions (`SIGN IS LEADING SEPARATE`) carry no semantic label beyond a
COBOL name.

The new model uses Java records (`ClaimRequest`, `PayoutResponse`, `DealerRef`,
`ProgramRef`) and enums (`ClaimType`, `ReasonCode`) that make the domain
self-documenting.

### Triple-duplicated rules to one source

Two system-wide constants were maintained in three places:

| Constant | COBOL copybook | DB2 PARM table | JCL control card |
|----------|----------------|----------------|------------------|
| Global payout cap ($10,000) | `INCCONST.cpy` `WC-GLOBAL-PAYOUT-CAP` | `PARM('GCAP')` | `INCPARM.txt` line `GC` |
| Loyalty bonus ($500) | `INCCONST.cpy` `WC-LOYALTY-BONUS` | `PARM('LBON')` | `INCPARM.txt` line `LB` |

The values are currently aligned, but nothing enforces that. A DBA can update
`PARM('GCAP')` without recompiling the copybook; operations can edit the control
card without touching either.

In the reimagined service both live in `IncentiveConstants.java` — a single
source of truth, version-controlled and deployed atomically.

### Implicit reason codes to an enum

Legacy reason codes are 4-byte literals scattered across `ERRCODES.cpy`
(`'DLRN'`, `'PRGW'`, `'LOYX'`, etc.) and compared by byte equality. The new
`ReasonCode` enum gives each a name, a `legacyCode()` accessor for parity, and
prevents typo-class bugs.

---

## What intentionally stays the same

- **Reason codes** — `OK`, `DLRN`, `DLRE`, `DLRI`, `PRGN`, `PRGW`, `RGNX`,
  `LOYX`, `DUP`, `EDIT` are byte-identical to the legacy `PAY-REASON` field.
- **Amount semantics** — dollar values use `BigDecimal` with the same precision
  as `PIC S9(7)V99`, and the pricing formula (`base + loyalty bonus`, then
  program cap, then global cap) preserves the exact order-of-operations from
  `INCCALC` paragraphs `1000-COMPUTE-BASE`, `2000-APPLY-LOYALTY`,
  `3000-APPLY-CAPS`.
- **Reversal policy** — clawbacks force the claim type to `RETAIL` before
  re-pricing and negate the result, preserving Policy 7.1 (loyalty bonus is
  not clawed back).
- **First-failure-wins** — the eligibility pipeline short-circuits at the
  first failing check, identical to the COBOL `EVALUATE` / cascading-`IF`
  pattern.

---

## Drift resolved: the missing loyalty check

The comprehension pass identified a **HIGH-risk online/batch drift**: the DB2
stored procedure `SP_ELIGIBILITY` does not enforce the loyalty/prior-ownership
rule (paragraph `3000-CHECK-LOYALTY` in `INCELIG`). A dealer submitting a
loyalty-program claim online sees "eligible" even without prior ownership; the
claim then fails in the nightly batch with hold-code `LOYX`.

The reimagined service includes the loyalty check in `ClaimProcessor
.checkEligibility()`, resolving this drift. Both online and batch callers will
see the same eligibility decision.

---

## Equivalence proof

The oracle harness compiles and runs the legacy COBOL batch under GnuCOBOL,
then the same 17 test fixtures are driven through the Spring Boot service.
The payout registers are compared field-for-field by `harness/compare.py`:

```
$ ./harness/build.sh && ./harness/run_legacy.sh
$ ./modernized/equivalence/run_modern.sh
$ python3 harness/compare.py testdata/expected/payout.dat build/out/modern_payout.dat
EQUIVALENT: 17 claims match across all 9 fields
```

The fixtures cover: flat and percentage programs, dealer credit / ACH / check
payout methods, loyalty bonus with stacking, program-level and global-level
caps, all hold/reject reason codes (DLRN, DLRE, DLRI, PRGN, PRGW, RGNX, LOYX,
DUP, EDIT), a reversal/clawback, and a structural-edit rejection.

---

## What this slice does NOT prove

- **Reversals at scale** — the test set includes one reversal. Production
  reversal patterns (partial clawbacks, reversals of loyalty claims, reversals
  arriving days after the original) are not exercised.
- **GL feed** — the downstream general-ledger extract (`INCGLFD.jcl`) sorts and
  filters the payout register. This service does not produce that feed.
- **Online exception screens** — the Struts / Spring MVC front-end screens that
  display held claims and let analysts adjudicate them are not covered by this
  slice.
- **Unseen production input shapes** — the 17 fixtures are synthetic. Real
  production data may contain edge cases (17-char VINs with special characters,
  dates near DST boundaries, programs with extreme rate/cap combinations) that
  these fixtures do not exercise.
- **Service boundaries and data ownership** — where dealer, program, and claim
  data lives in the target architecture (shared database vs. per-service store,
  event sourcing, CQRS) remains a human architectural decision outside this
  conversion.
- **Non-functional concerns** — throughput, latency, connection pooling,
  circuit-breaking, and observability are not addressed by this proof-of-concept
  service.
