# Demo Notes (presenter only)

This is the presenter's crib sheet. The audience-facing entry point is `README.md`. Do not commit
anything from `comprehension/` or `modernized/` to `main` — those are produced live so the demo is
demonstrably real, not pre-baked.

## The narrative

The OEM runs a dealer-incentive claims platform on the mainframe (COBOL + JCL + DB2 stored procedures)
with a Struts front end being migrated to Spring MVC. Nobody understands it end to end, and they want
to *reimagine* it rather than lift-and-shift. The demo arc is: **index → comprehend → validate with an
SME → reimagine one slice with proof of parity.**

## Each OEM ask → where it is fulfilled

| OEM ask | Fulfilled by |
|---------|--------------|
| "Start with DeepWiki" | Phase 0 of the comprehension playbook — index the repo first. |
| Business-level understanding (not a code dump) | `comprehension/business_capability_map.md`. |
| End-to-end process flow a business stakeholder can follow | `comprehension/claim_trace.md` (the OEM's #1 gap). |
| Logic connected across systems | `comprehension/cross_artifact_linkage.md` (COBOL ↔ DB2 ↔ control card). |
| Persona-based views | `comprehension/personas/{dealer_operations,compliance,finance}.md`. |
| Human-in-the-loop validation | `comprehension/validation_log.md` — SME confirms/challenges, Devin reconciles. |
| Reimagine, not lift-and-shift | `convert-claim-path.md` + `modernized/` — rules extracted to a typed domain model. |
| Feedback loop / known I/O validation | `harness/` GnuCOBOL oracle + `compare.py` field-by-field equivalence. |

## Planted "gotchas" to surface during comprehension

These make the comprehension story real — they are the kind of thing only a deep read (or Devin) finds:

1. **Online/batch drift.** The loyalty / prior-ownership rule is enforced in batch (`INCELIG`
   `3000-CHECK-LOYALTY`) but is **absent** from the online `SP_ELIGIBILITY` stored proc. A claim can
   pass the web screen and still be held by the nightly batch. This is a compliance control gap.
2. **Triple-duplicated constants.** The global payout cap and loyalty bonus live in three places:
   `INCCONST.cpy` (`WC-GLOBAL-PAYOUT-CAP`, `WC-LOYALTY-BONUS`), the DB2 `PARM` table, and the
   `//INCPARM` control card. If they disagree, online and batch quote different numbers.
3. **Eligibility date-window rule** is implemented in both `INCELIG` `1000-CHECK-WINDOW` and
   `SP_ELIGIBILITY` — same intent, two implementations to keep in sync.

The data dictionary (`docs/data-dictionary.md`) lists these duplications explicitly.

## Fixture coverage (17 claims)

The fixtures are generated deterministically by `harness/make_fixtures.py` and cover every path:
happy paths (flat retail, customer cash, loyalty-with-prior → `PAID`), eligibility holds (`DLRN`
`DLRE` `DLRI` `PRGN` `PRGW` `RGNX` `LOYX`), duplicate (`DUP`), reversal (`RVSD`), edit reject, and a
claim where the payout cap binds. Decode any record with the layouts in `docs/data-dictionary.md`.

## Live run cheat-sheet

```bash
./harness/build.sh && ./harness/run_legacy.sh
python3 harness/compare.py testdata/expected/payout.dat build/out/payout.dat   # -> EQUIVALENT
```

During the conversion slice, point the modern service's output register at `compare.py` the same way;
a clean `EQUIVALENT` is the proof, any `DIFF` line is a concrete claim-level discrepancy to explain.

## Open item to confirm with the team

The modern target stack — **Java 21 + Spring Boot 3**, synchronous REST — is a *proposal*, chosen to
align with the in-progress Struts → Spring MVC migration and the batch → synchronous redesign. Confirm
before the conversion slice; the `convert-claim-path.md` playbook flags it too.
