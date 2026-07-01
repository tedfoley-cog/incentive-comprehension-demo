# Data Dictionary — Incentive Platform (legacy estate)

Generated reference for the record layouts and reason codes shared across the
COBOL batch, the DB2 tables, and the online application. The byte offsets are
authoritative for the flat-file fixtures in `testdata/`.

## Record layouts

### CLAIM-REC — daily claim feed (`CLAIMREC.cpy`, 80 bytes)

| Field | PIC | Bytes | Notes |
|-------|-----|-------|-------|
| CLM-CLAIM-ID | X(10) | 1–10 | Unique claim id |
| CLM-VIN | X(17) | 11–27 | Vehicle identification number |
| CLM-DEALER-ID | X(06) | 28–33 | FK to DEALER-REC |
| CLM-PROGRAM-ID | X(06) | 34–39 | FK to PROGRAM-REC |
| CLM-SALE-DATE | 9(08) | 40–47 | CCYYMMDD |
| CLM-SALE-PRICE | 9(07)V99 | 48–56 | Implied 2 decimals |
| CLM-CLAIM-TYPE | X(08) | 57–64 | RETAIL / CUSTCASH / LOYALTY / REVERSAL |
| CLM-PRIOR-OWN | X(01) | 65 | Y = prior ownership on file |
| CLM-CUST-BANK | X(01) | 66 | Y = customer bank account on file |
| FILLER | X(14) | 67–80 | |

### DEALER-REC — dealer master (`DEALERREC.cpy`, 80 bytes)

| Field | PIC | Bytes | Notes |
|-------|-----|-------|-------|
| DLR-DEALER-ID | X(06) | 1–6 | |
| DLR-NAME | X(30) | 7–36 | |
| DLR-REGION | X(04) | 37–40 | NE / WST / MW / STH |
| DLR-ENROLLED | X(01) | 41 | Y = enrolled in incentive program |
| DLR-STATUS | X(01) | 42 | A = active, I = inactive |
| FILLER | X(38) | 43–80 | |

### PROGRAM-REC — incentive program master (`PROGREC.cpy`, 100 bytes)

| Field | PIC | Bytes | Notes |
|-------|-----|-------|-------|
| PRG-PROGRAM-ID | X(06) | 1–6 | |
| PRG-DESC | X(30) | 7–36 | |
| PRG-TYPE | X(04) | 37–40 | FLAT / PCT |
| PRG-FLAT-AMOUNT | 9(07)V99 | 41–49 | Used when FLAT |
| PRG-PCT-RATE | 9(03)V99 | 50–54 | Percent, used when PCT |
| PRG-START-DATE | 9(08) | 55–62 | Window start (inclusive) |
| PRG-END-DATE | 9(08) | 63–70 | Window end (inclusive) |
| PRG-PAYEE | X(01) | 71 | D = dealer, C = customer |
| PRG-REGION | X(04) | 72–75 | ALL or a region code |
| PRG-STACKABLE | X(01) | 76 | Y = loyalty bonus may stack |
| PRG-REQ-PRIOR-OWN | X(01) | 77 | Y = requires prior ownership |
| PRG-MAX-INCENTIVE | 9(07)V99 | 78–86 | Program-level cap |
| FILLER | X(14) | 87–100 | |

### PAYOUT-REC — payout register (`PAYOUTREC.cpy`, 80 bytes)

| Field | PIC | Bytes | Notes |
|-------|-----|-------|-------|
| PAY-CLAIM-ID | X(10) | 1–10 | |
| PAY-VIN | X(17) | 11–27 | |
| PAY-DEALER-ID | X(06) | 28–33 | |
| PAY-PROGRAM-ID | X(06) | 34–39 | |
| PAY-STATUS | X(04) | 40–43 | PAID / HOLD / RVSD / REJ |
| PAY-METHOD | X(06) | 44–49 | CREDIT / ACH / CHECK |
| PAY-PAYEE-TYPE | X(01) | 50 | D / C |
| PAY-REASON | X(04) | 51–54 | Reason code (see below) |
| PAY-AMOUNT | S9(7)V99 | 55–64 | Sign leading separate; negative = clawback |
| FILLER | X(16) | 65–80 | |

## Reason codes (`ERRCODES.cpy`)

| Code | Meaning | Set by |
|------|---------|--------|
| `OK` | Eligible / paid | INCVAL, INCELIG |
| `DLRN` | Dealer not found | INCVAL |
| `DLRE` | Dealer not enrolled | INCVAL |
| `DLRI` | Dealer inactive | INCVAL |
| `PRGN` | Program not found | INCVAL |
| `PRGW` | Sale date outside program window | INCELIG / SP_ELIGIBILITY |
| `RGNX` | Dealer region not eligible | INCELIG / SP_ELIGIBILITY |
| `LOYX` | Loyalty program, no prior ownership | INCELIG |
| `DUP` | Duplicate VIN+program in run | INCEXC |
| `EDIT` | Structural field edit failure | INCEDIT |

## Known duplications (for comprehension)

| Rule | COBOL | DB2 | Control card |
|------|-------|-----|--------------|
| Eligibility date window | `INCELIG` 1000-CHECK-WINDOW | `SP_ELIGIBILITY` | — |
| Region eligibility | `INCELIG` 2000-CHECK-REGION | `SP_ELIGIBILITY` | `RC` codes in `INCPARM` |
| Loyalty / prior ownership | `INCELIG` 3000-CHECK-LOYALTY | **missing** (drift) | — |
| Global payout cap | `INCCONST` WC-GLOBAL-PAYOUT-CAP | `PARM('GCAP')` | `GC` in `INCPARM` |
| Loyalty bonus amount | `INCCONST` WC-LOYALTY-BONUS | `PARM('LBON')` | `LB` in `INCPARM` |
