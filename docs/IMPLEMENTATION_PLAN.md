# Implementation Plan — Dealer Incentive Claims Platform (Mainframe Comprehension → Conversion Demo)

> This is the planning artifact required by the demo-scaffold process. It is committed first, before
> the rest of the repo, so the approach can be audited. Sources for every non-obvious syntax/format
> decision are cited inline.

## 1. What the demo proves

A large OEM runs a **dealer-incentive / claims platform** on the mainframe (COBOL + JCL + DB2 stored
procedures), with a Struts web front end currently being migrated to Spring MVC. They have no living
SME who understands the whole thing end to end. Before they commit to *reimagining* the platform (not
a lift-and-shift), they need **comprehension first**: a top-down, business-readable map of the system,
an end-to-end trace of how a claim is processed across all artifact types, and confidence that the
3–5 real claim-processing paths are fully understood. This demo shows Devin doing exactly that —
DeepWiki indexing → business-capability mapping → end-to-end claim trace + cross-artifact linkage +
persona views + an SME validation loop → and finally a slice of conversion into a modern platform
with an automated legacy-vs-modern equivalence check.

## 2. What Devin does live (one sentence)

Devin indexes the estate with DeepWiki, produces a top-down business-capability → process-flow →
program/job comprehension map (including an end-to-end claim trace across COBOL/JCL/stored procedures,
persona views, and an SME validation loop), then converts one claim path into a modern Spring Boot
service and proves behavioral equivalence against the running legacy COBOL.

## 3. Stack and rationale (with sources)

| Artifact / tech | Why it's here | Source confirmed against |
|---|---|---|
| COBOL-85 batch programs (fixed format, cols 7–72) | The backend business logic lives here per the discovery call ("COBOL, JCL and the stored pro"). | GnuCOBOL 3.x programmer's guide; existing `cobol-ims-demo` conventions |
| JCL job streams + cataloged PROC | Batch orchestration; the estate is "predominantly batch" per the comprehension brief. | IBM z/OS MVS JCL Reference (`EXEC PGM=`, `DD`, `PROC`/`PEND`) |
| DB2 stored procedures (SQL PL) + DDL + DCLGEN copybook | "Stored procedures" called out as where logic also lives; demonstrates cross-artifact linkage (logic split COBOL↔DB2). | IBM Db2 for z/OS `CREATE PROCEDURE` (SQL PL) reference; DCLGEN output format |
| Control cards / parm files | Runtime configuration governing program behavior (comprehension brief lists these as required artifacts). | IBM utilities (SYSIN control cards) |
| Control-M-style job-scheduling export (JSON) | Batch-flow graph reconstruction (comprehension brief: scheduler metadata from CA-7/Control-M). | Control-M Automation API job JSON shape |
| Struts 1.x front end (`struts-config.xml`, Action, JSP) | Their current front end. | Apache Struts 1.x `struts-config` DTD |
| Spring MVC controller (partial) | "Front end is on struts which we are migrating to spring MVC" — migration already underway. | Spring MVC `@Controller` reference |
| GnuCOBOL (`cobc`) runnable harness | Restores the agent feedback loop (conversion brief): compile + run the COBOL batch on a Linux VM against known I/O pairs — this is the validation oracle. | GnuCOBOL 3.1 `cobc`/`cobcrun` |
| Java 21 + Spring Boot 3 (conversion target) | Reimagined modern platform: domain service with externalized state, REST contract replacing file interfaces (addresses the batch→synchronous problems in the conversion brief). Aligns with their Struts→Spring direction. | Spring Boot 3 reference |

## 4. Repo layout

```
docs/
  IMPLEMENTATION_PLAN.md        # this file
  flowchart.html / .png         # demo-flow diagram
  data-dictionary.md            # field glossary (business + technical)
legacy/                         # the "before" estate Devin comprehends (initial state)
  cobol/                        # INCEDIT INCMAIN INCVAL INCELIG INCCALC INCPAY INCREV INCEXC INCRPT
  copybook/                     # CLAIMREC PROGREC DEALERREC PAYOUTREC INCCONST ERRORS DCLCLAIM
  jcl/                          # INCDAILY.jcl INCREVRS.jcl INCEXTR.jcl  + proc/INCPROC.prc
  proc/                         # (cataloged PROC lives here)
  db2/                          # schema.sql (DDL) + stored procs SP_ELIGIBILITY/SP_RATE_LOOKUP/SP_POST_PAYOUT
  control/                      # INCDAILY.parm, sort control cards
  scheduler/                    # controlm_incentive.json (batch-flow graph)
  frontend-struts/              # struts-config.xml, ClaimEntryAction.java, claimEntry.jsp
  frontend-spring/              # ClaimController.java (migration underway, partial)
testdata/
  input/                        # claim feed + master files (fixed-width) — the test fixtures
  expected/                     # golden output produced by the real COBOL (the oracle)
harness/
  build.sh run_legacy.sh        # compile + run the COBOL batch via GnuCOBOL
  compare.py                    # field-by-field equivalence: legacy vs modern
comprehension/                  # EMPTY (Devin fills live): business_capability_map, claim trace, personas, validation log
modernized/                     # EMPTY (Devin fills live): Spring Boot eligibility-incentive-service
.devin/playbooks/               # comprehend-incentive-platform.md, convert-claim-path.md
.github/workflows/ci.yml
README.md  DEMO_NOTES.md
```

~30 source files. **Override note:** the scaffold default is 10–25 source files; the user asked for an
"extremely thorough" demo touching every Ford requirement (top-down map, end-to-end claim trace,
cross-artifact linkage, personas, validation loop, scale, conversion), so the estate is deliberately
larger to make the comprehension story authentic. Noted in the PR description.

## 5. Flowchart outline (nodes/edges)

Trigger → DeepWiki index → **Comprehension phase** (business-capability map → process-flow drilldown →
end-to-end claim trace → cross-artifact linkage → persona views) → **SME validation loop** (review /
challenge / confirm; human-in-the-loop) → **Conversion phase** (pick one claim path → reimagine as
Spring Boot service → GnuCOBOL oracle vs modern equivalence test) → outputs (PR + comprehension docs).
Rendered with `htmlLabels:false`, no `fontFamily` in `themeVariables`, simple `[text]` labels (per the
scaffold's Mermaid anti-clipping rules).

## 6. Runtime plan

- **Genuinely runnable** legacy batch: `harness/build.sh` compiles the COBOL with `cobc`,
  `harness/run_legacy.sh` runs `INCMAIN` over `testdata/input/*` and writes a payout register +
  exception report; `testdata/expected/` holds the golden output captured from that run. This is the
  validation oracle the conversion brief describes (run COBOL on a Linux VM, test against known I/O).
- The **stored procedures + DDL** are authentic comprehension artifacts (logic that lives in DB2);
  they are *not* executed in the harness (no DB2), and that is called out. They exist to demonstrate
  cross-artifact linkage — including a deliberate, realistic "gotcha": the eligibility date-window rule
  exists in **both** `INCELIG.cbl` and `SP_ELIGIBILITY` (logic split across code and database).
- **Conversion** (modern Spring Boot service) is built live by Devin into `modernized/`; the dry-run
  builds it on a throwaway branch to prove the equivalence harness passes, then discards it so `main`
  ships initial-state-only.

## 7. Visual artifact plan

Primary visual = **the flowchart** (always built) + the **native comprehension outputs** Devin
produces live: a top-down business-capability map (Mermaid), an end-to-end claim-trace diagram, a
cross-artifact linkage table, persona views (markdown), and the conversion PR + equivalence report
(pass/fail table). **No live dashboard** — it fails the scaffold's Dashboard Decision Gate (this is a
one-shot comprehension/transformation whose output is documents + a PR, not an ongoing monitoring
surface), and the user explicitly does not want one. The "end-to-end process flow business
stakeholders can understand" — Ford's #1 gap — is served by the claim-trace diagram + persona views.

## 8. CI plan

`.github/workflows/ci.yml` (<50 lines): install GnuCOBOL, run `harness/build.sh` (COBOL compiles),
run `harness/run_legacy.sh`, diff output against `testdata/expected/` (golden output is stable), and
lint the harness Python with `ruff`. Green check proves the legacy oracle is reproducible.

## 9. Risks / unknowns

- Modern target framework is **Java 21 / Spring Boot 3** (confirmed with the team).
- DB2 SQL PL stored procs are not executed (no DB2 on the VM); they are reference artifacts only.
- File count exceeds the default cap (intentional; see §4).
- Real Ford validation depends on connectivity to their environment (per both briefs) — the demo's
  equivalence harness shows the *mechanism* on a runnable batch slice.
