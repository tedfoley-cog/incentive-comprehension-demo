# comprehension/ — generated live by Devin

This directory is **intentionally empty** in the starting state. It is the
output target for the comprehension pass that Devin runs **live** during the
demo (driven by [`.devin/playbooks/comprehend-incentive-platform.md`](../.devin/playbooks/comprehend-incentive-platform.md)).

When the playbook runs, Devin populates:

| File | What it contains |
|------|------------------|
| `business_capability_map.md` | Plain-English map of the platform's business capabilities (claim intake, eligibility, pricing, payout, reversal, GL feed) cross-referenced to the COBOL/JCL/DB2 artifacts that implement each one. |
| `claim_trace.md` | End-to-end trace of a single claim through every system it touches — feed → edit → eligibility → calc → payout → GL — with the exact programs, paragraphs, and stored procedures on the path. |
| `cross_artifact_linkage.md` | The duplicated-logic findings: the eligibility date-window rule and the global payout cap that each exist in **three** places (COBOL, DB2, control card) and have drifted. |
| `personas/` | The same system explained for different stakeholders (dealer operations, compliance, finance) — not a code decomposition. |
| `validation_log.md` | The SME validation loop: each generated claim about the system, the SME verdict (confirm / challenge), and how Devin reconciled challenges against the source. |

Nothing here is pre-written: the whole point of the demo is that Devin
produces it from the source estate during the session.
