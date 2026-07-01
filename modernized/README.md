# modernized/ — generated live by Devin

This directory is **intentionally empty** in the starting state. It is the
output target for the conversion slice that Devin builds **live** during the
demo (driven by [`.devin/playbooks/convert-claim-path.md`](../.devin/playbooks/convert-claim-path.md)).

The demo deliberately does **not** lift-and-shift the COBOL. Instead Devin
reimagines one vertical slice — the **eligibility + pricing path for a single
claim** — as a modern service, and proves behavioural parity against the
legacy batch using the equivalence harness.

When the playbook runs, Devin produces:

| Path | What it contains |
|------|------------------|
| `service/` | A small Spring Boot service exposing the eligibility + pricing decision as a synchronous REST endpoint, with the rules extracted from `INCELIG`/`INCCALC` into a clean domain model (not a transliteration). |
| `equivalence/` | A driver that runs the same claim fixtures through the new service and the legacy register and calls `harness/compare.py` to prove the two agree field-for-field. |
| `REIMAGINING.md` | The architectural argument: what changes (batch → synchronous, copybook → typed domain, duplicated rules → single source of truth) and what intentionally stays the same. |

The target stack is **Java 21 + Spring Boot 3** (synchronous REST), confirmed
with the team — chosen to align with the in-progress Struts → Spring MVC
migration and the batch → synchronous redesign.
