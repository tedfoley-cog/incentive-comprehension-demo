---
name: comprehend-incentive-platform
description: Produce a business-readable comprehension of the legacy dealer-incentive claims platform (COBOL/JCL/DB2 + Struts→Spring) and validate it with an SME. Use when comprehending, mapping, tracing, or documenting the legacy estate before modernization.
---

# Comprehend the Incentive Platform

You are analyzing a poorly-documented dealer-incentive claims platform for a
large vehicle manufacturer ("the OEM"). The estate is a mix of COBOL batch,
JCL, DB2 SQL PL stored procedures, and a half-migrated Struts → Spring MVC
front end. The OEM does **not** want a lift-and-shift; they want to *reimagine*
the platform, and before they can, they need to **understand** it.

Your job in this session is to produce a business-readable comprehension of the
system — not a file-by-file code dump — and to validate it with a subject
matter expert (the presenter plays the SME). Write every artifact into
`comprehension/`.

Work in the repo root. The legacy source is under `legacy/`. A runnable
GnuCOBOL oracle of the batch is in `harness/` (see below).

> Each phase below maps to a specific ask from the discovery conversation.
> Keep the phases in order; they build on each other.

---

## Phase 0 — Index the codebase (ask: "start with DeepWiki")

1. Use DeepWiki to index this repository so the rest of the session can ask
   questions against the whole estate rather than one file at a time.
2. In `comprehension/business_capability_map.md`, open with a short "How this
   was indexed" note: how many programs, copybooks, JCL members, stored
   procedures, and front-end sources exist, and the call/Job graph at a glance.

Get the raw inventory from the repo itself:

```bash
find legacy -type f | sort
```

---

## Phase 1 — Business capability map (ask: "business-level understanding")

Read the actual source — `PROCEDURE DIVISION` logic, not just the header
comments — and produce a **business** view, not a code decomposition.

Programs and the order to read them (this is the claim lifecycle):

1. `legacy/cobol/INCMAIN.cbl` — batch driver / orchestration
2. `legacy/cobol/INCEDIT.cbl` — structural field edits
3. `legacy/cobol/INCEXC.cbl` — duplicate / exception screen
4. `legacy/cobol/INCVAL.cbl` — dealer-level eligibility
5. `legacy/cobol/INCELIG.cbl` — program-level eligibility engine
6. `legacy/cobol/INCCALC.cbl` — incentive calculation engine
7. `legacy/cobol/INCPAY.cbl` — payout method / payee determination
8. `legacy/cobol/INCREV.cbl` — reversal / clawback

Also read the shared copybooks in `legacy/copybook/` and the DB2 layer in
`legacy/db2/`.

In `comprehension/business_capability_map.md`, for each **business capability**
(claim intake, structural validation, duplicate control, eligibility, pricing,
payout disbursement, reversal/clawback, GL feed) write:

- one plain-English sentence a business owner would accept;
- the artifacts that implement it (program + paragraph, stored proc, JCL step);
- the inputs it consumes and outputs it produces.

---

## Phase 2 — End-to-end claim trace (ask: "trace a claim across systems")

Pick a single PAID claim and a single HOLD claim from the fixtures
(`testdata/input/claims.dat`; decode with the data dictionary in
`docs/data-dictionary.md`). For each, write the full path it travels in
`comprehension/claim_trace.md`:

- the scheduler job that triggers the run (`legacy/scheduler/SCHEDULE.txt`);
- the JCL step and DD bindings (`legacy/jcl/INCDAILY.jcl`);
- every COBOL paragraph the claim hits, in order, with the decision taken;
- the reason code and payout record produced.

Render the trace as a sequence/flow diagram (ASCII or Mermaid) so a
non-programmer can follow one claim end to end.

Prove the trace against the running system:

```bash
./harness/build.sh && ./harness/run_legacy.sh
# decode build/out/payout.dat using docs/data-dictionary.md
```

---

## Phase 3 — Cross-artifact linkage (ask: "logic connected across systems")

This estate has the same rule implemented in several places, and they have
drifted. Find and document them in `comprehension/cross_artifact_linkage.md`:

- **Eligibility date window** — `INCELIG` `1000-CHECK-WINDOW` vs DB2
  `SP_ELIGIBILITY`. Are they identical?
- **Loyalty / prior-ownership rule** — present in `INCELIG`
  `3000-CHECK-LOYALTY`; is it present in `SP_ELIGIBILITY`? (It is not — record
  the online/batch drift.)
- **Global payout cap & loyalty bonus** — `INCCONST` (`WC-GLOBAL-PAYOUT-CAP`,
  `WC-LOYALTY-BONUS`) vs DB2 `PARM` rows vs the `//INCPARM` control card.

For each, state where the truth lives, where the copies are, and the risk if
they disagree.

---

## Phase 4 — Persona views (ask: "persona-based views for stakeholders")

The same system, re-explained for three audiences. Write each to
`comprehension/personas/`:

- `dealer_operations.md` — what happens to a claim a dealer submits, why it
  might be held, and how a clawback affects them.
- `compliance.md` — the eligibility and duplicate controls, the audit trail,
  and the online/batch drift as a control gap.
- `finance.md` — how PAID/RVSD records become GL debits/credits, the payout
  methods, and where the caps protect spend.

These must be readable by a non-engineer in that role.

---

## Phase 5 — SME validation loop (ask: "human-in-the-loop validation")

Comprehension is only useful if the SME trusts it. Run a validation loop and
record it in `comprehension/validation_log.md`:

1. Restate 5–8 concrete claims about the system as testable statements (e.g.
   "a loyalty claim with no prior ownership is held with LOYX", "online entry
   does not enforce the loyalty rule").
2. Ask the SME (the presenter) to **confirm or challenge** each one.
3. For any challenge, go back to the source, resolve it, and record the
   correction. Use the running harness to settle disputes about behaviour.

The log should clearly show which findings are SME-confirmed vs open.

---

## Output checklist

- [ ] `comprehension/business_capability_map.md`
- [ ] `comprehension/claim_trace.md` (with diagram)
- [ ] `comprehension/cross_artifact_linkage.md`
- [ ] `comprehension/personas/{dealer_operations,compliance,finance}.md`
- [ ] `comprehension/validation_log.md`

When this is done and SME-confirmed, the team can decide which slice to
reimagine first — see the `convert-claim-path` skill.
