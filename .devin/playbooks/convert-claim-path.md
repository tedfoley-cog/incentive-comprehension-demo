# Convert one claim path (reimagine, don't transliterate)

Prerequisite: the comprehension pass
(`.devin/playbooks/comprehend-incentive-platform.md`) has run and the SME has
confirmed the findings in `comprehension/`.

The OEM does not want a line-for-line COBOL → Java port. They want to see a
**slice** of what the reimagined platform looks like, with proof it behaves
like the system it replaces. In this session you convert exactly one vertical
slice — the **eligibility + pricing decision for a single claim** — and prove
parity. Write everything into `modernized/`.

> Confirm the target stack with the team before generating code. The proposed
> default is **Java 21 + Spring Boot 3** exposing a synchronous REST endpoint,
> chosen to align with the in-progress Struts → Spring MVC migration and the
> batch → synchronous redesign the OEM is after. If they prefer a different
> stack, adapt.

---

## Step 1 — Extract the rules into a clean domain model

From `INCELIG.cbl` (window, region, loyalty) and `INCCALC.cbl` (flat/pct,
loyalty bonus, program cap, global cap), extract the business rules into a
typed domain model — **not** a copybook transliteration. Eliminate the
duplicated constants you found in Phase 3: the global cap and loyalty bonus
should have a single source of truth in the new design.

Write the design rationale to `modernized/REIMAGINING.md`:

- what changes (batch → synchronous, copybook offsets → typed domain, triple-
  duplicated rules → one source, implicit reason codes → an enum);
- what intentionally stays the same (the reason codes and amounts, so behaviour
  is preserved);
- the online/batch drift you are resolving (the missing loyalty check in
  `SP_ELIGIBILITY`).

## Step 2 — Build the service

Under `modernized/service/`, build a small Spring Boot service exposing the
eligibility + pricing decision as a REST endpoint that takes a claim and
returns `{ status, reasonCode, amount, method }`.

## Step 3 — Prove equivalence (the oracle harness)

This is the trust step. Run the **same** claim fixtures through both systems
and prove they agree field-for-field.

1. Produce the legacy register (the oracle):

   ```bash
   ./harness/build.sh && ./harness/run_legacy.sh
   ```

2. Run the same fixtures through the new service and emit a payout register in
   the identical `PAYOUTREC` layout (write the driver under
   `modernized/equivalence/`).

3. Compare:

   ```bash
   python3 harness/compare.py testdata/expected/payout.dat <new-service-output>
   ```

   A clean `EQUIVALENT` result is the proof the reimagined slice preserves
   behaviour. Any `DIFF` line is a concrete, claim-level discrepancy to explain
   or fix — exactly the feedback loop the conversion brief calls for.

## Step 4 — Honest assessment

In `modernized/REIMAGINING.md`, close with what this slice does and does **not**
prove: the forward eligibility+pricing path is covered; reversals, the GL feed,
the online exception screens, and unseen production input shapes are not yet,
and the architectural decisions (service boundaries, data ownership) remain a
human call.

---

## Output checklist

- [ ] `modernized/REIMAGINING.md`
- [ ] `modernized/service/` (Spring Boot eligibility+pricing endpoint)
- [ ] `modernized/equivalence/` (driver + parity run)
- [ ] A clean `EQUIVALENT` from `harness/compare.py` against the legacy oracle
