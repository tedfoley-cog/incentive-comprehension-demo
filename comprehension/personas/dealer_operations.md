# Dealer Operations View

*What happens to a claim a dealer submits, why it might be held, and how a
clawback affects them.*

---

## The Claim Lifecycle (from a dealer's perspective)

1. **Submission**: After selling a vehicle, the dealer submits a claim through
   the online portal (the Struts/Spring web application). The claim names the
   VIN, incentive program, sale date, and sale price.

2. **Immediate feedback**: The portal calls `SP_ELIGIBILITY` and returns a
   pass/fail response within seconds. If the dealer is enrolled, active, and the
   sale is within the program window and region, the dealer sees "eligible."

   > **Caveat**: The online check does NOT validate the loyalty/prior-ownership
   > rule. A loyalty claim may show "eligible" online but later be held in
   > batch. This is a known gap.

3. **Nightly batch**: That evening, `INCDAILY` picks up all submitted claims
   and runs the full pipeline: edit checks, duplicate screen, dealer + program
   eligibility (including loyalty), pricing, and payout method determination.

4. **Payout or Hold**: The next morning, the dealer can see the result:
   - **PAID** — the incentive has been approved and will be disbursed.
   - **HOLD** — the claim failed a rule and is queued for analyst review.

---

## Why a Claim Gets Held

| Reason Code | Meaning | What to do |
|-------------|---------|------------|
| `DLRN` | Your dealer ID wasn't found in the master | Contact program admin — you may not be on file |
| `DLRE` | You're not enrolled in the incentive program | Enroll before re-submitting |
| `DLRI` | Your dealership is currently inactive | Contact your regional rep |
| `PRGN` | The program ID on the claim doesn't exist | Check the program code — typo? |
| `PRGW` | The sale date is outside the program's valid window | Confirm the sale date; program may have closed |
| `RGNX` | Your region isn't eligible for this program | Some programs are region-restricted |
| `LOYX` | Loyalty program requires proof of prior ownership and it's missing | Submit proof of prior vehicle ownership |
| `DUP ` | Same VIN + program already paid in this run | Likely a double-submission; will go to exception queue |

Hold claims are NOT rejected — they sit in the exception queue for an operations
analyst to adjudicate. You may be asked for additional documentation.

---

## How Payouts Work

| Program Payee | Method | What you receive |
|---------------|--------|------------------|
| Dealer (D) | CREDIT | A credit memo applied to your account |
| Customer (C) + bank on file | ACH | Customer receives electronic funds transfer |
| Customer (C) + no bank | CHECK | Customer receives a mailed check |

Dealer-paid programs always credit your account directly. Customer-paid programs
go to the buyer — you don't touch the money.

---

## Clawbacks (Reversals)

If a sale is unwound (the vehicle is returned or the deal unwinds), the OEM
claws back the original incentive.

**What happens**:
- A REVERSAL claim is submitted for the same VIN/program.
- The system recalculates the original base incentive and negates it.
- A **negative** payout record is written — your account is debited.

**Important**: If the original claim earned a loyalty stack bonus ($500), that
bonus is **NOT** clawed back (per Policy 7.1). You only lose the base incentive.

---

## Key Things to Know

- The online portal gives you a quick eligibility check, but it's **not the
  final answer** — the nightly batch is the system of record.
- The loyalty rule is only enforced in batch. If the portal says "eligible" for
  a loyalty program but you have no proof of prior ownership, it will still be
  held overnight.
- Duplicate claims (same VIN + same program) in a single day are held, not
  rejected. An analyst will review them.
- The maximum incentive for any single claim is capped at **$10,000**, regardless
  of what the program formula computes.
