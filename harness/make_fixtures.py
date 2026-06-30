#!/usr/bin/env python3
"""Generate fixed-width input fixtures for the INCMAIN batch.

The legacy programs read three flat files whose layouts are defined by the
copybooks in legacy/copybook (CLAIMREC, DEALERREC, PROGREC). Hand-counting
columns is error prone, so the record layouts are encoded here once and the
fixtures are generated deterministically. Re-run this script to regenerate
testdata/input/*.dat; the golden payout register is produced by running the
batch (see run_legacy.sh) and checked in under testdata/expected.
"""
from pathlib import Path

INPUT_DIR = Path(__file__).resolve().parent.parent / "testdata" / "input"


def s(value: str, width: int) -> str:
    """Left-justified alphanumeric field (PIC X), space padded."""
    if len(value) > width:
        raise ValueError(f"value {value!r} exceeds width {width}")
    return value.ljust(width)


def n(value: int, width: int) -> str:
    """Unsigned zoned-decimal field (PIC 9), zero padded."""
    text = str(value)
    if len(text) > width:
        raise ValueError(f"number {value} exceeds width {width}")
    return text.zfill(width)


def money(dollars: float, digits: int) -> str:
    """PIC 9(n)V99 with the implied decimal dropped (cents, zero padded)."""
    return n(round(dollars * 100), digits)


# ----------------------------------------------------------------------------
# DEALERREC - 80 bytes: id6 name30 region4 enrolled1 status1 filler38
# ----------------------------------------------------------------------------
def dealer(dealer_id, name, region, enrolled, status):
    rec = s(dealer_id, 6) + s(name, 30) + s(region, 4) + s(enrolled, 1) \
        + s(status, 1) + s("", 38)
    assert len(rec) == 80, len(rec)
    return rec


# ----------------------------------------------------------------------------
# PROGREC - 100 bytes
# ----------------------------------------------------------------------------
def program(pid, desc, ptype, flat, pct, start, end, payee, region,
            stackable, req_prior, maxinc):
    rec = (
        s(pid, 6) + s(desc, 30) + s(ptype, 4)
        + money(flat, 9) + n(round(pct * 100), 5)
        + n(start, 8) + n(end, 8)
        + s(payee, 1) + s(region, 4) + s(stackable, 1) + s(req_prior, 1)
        + money(maxinc, 9) + s("", 14)
    )
    assert len(rec) == 100, len(rec)
    return rec


# ----------------------------------------------------------------------------
# CLAIMREC - 80 bytes
# ----------------------------------------------------------------------------
def claim(cid, vin, dealer_id, pid, sale_date, sale_price, ctype,
          prior_own, bank):
    rec = (
        s(cid, 10) + s(vin, 17) + s(dealer_id, 6) + s(pid, 6)
        + n(sale_date, 8) + money(sale_price, 9) + s(ctype, 8)
        + s(prior_own, 1) + s(bank, 1) + s("", 14)
    )
    assert len(rec) == 80, len(rec)
    return rec


DEALERS = [
    dealer("D00001", "RIVERSIDE MOTORS", "NE", "Y", "A"),
    dealer("D00002", "PACIFIC AUTO GROUP", "WST", "Y", "A"),
    dealer("D00003", "LAKEFRONT CARS", "MW", "N", "A"),
    dealer("D00004", "SUMMIT DEALERSHIP", "NE", "Y", "I"),
    dealer("D00005", "VALLEY AUTOPLEX", "STH", "Y", "A"),
]

PROGRAMS = [
    program("PFLAT1", "Q2 RETAIL CASH FLAT", "FLAT", 750.00, 0.0,
            20250101, 20251231, "D", "ALL", "N", "N", 1000.00),
    program("PCUST1", "CUSTOMER CASH REBATE", "FLAT", 500.00, 0.0,
            20250101, 20251231, "C", "ALL", "N", "N", 1000.00),
    program("PLOYL1", "LOYALTY CONQUEST PCT", "PCT", 0.0, 2.00,
            20250101, 20251231, "D", "ALL", "Y", "Y", 5000.00),
    program("PRGNW1", "WEST REGION BONUS", "FLAT", 600.00, 0.0,
            20250101, 20251231, "D", "WST", "N", "N", 1000.00),
    program("PCAP01", "HIGH PCT PROGRAM CAP", "PCT", 0.0, 50.00,
            20250101, 20251231, "D", "ALL", "N", "N", 2000.00),
    program("PGCAP1", "GLOBAL CAP STRESS", "PCT", 0.0, 50.00,
            20250101, 20251231, "D", "ALL", "N", "N", 99999.99),
]

# VIN helper: 17 chars
def vin(suffix):
    return ("1FORDDEMO" + suffix).ljust(17, "0")[:17]


CLAIMS = [
    # 1 happy path: flat retail, dealer credit
    claim("C000000001", vin("A001"), "D00001", "PFLAT1",
          20250615, 28500.00, "RETAIL", "N", "N"),
    # 2 customer cash, bank on file -> ACH
    claim("C000000002", vin("A002"), "D00002", "PCUST1",
          20250620, 31000.00, "CUSTCASH", "N", "Y"),
    # 3 customer cash, no bank -> CHECK
    claim("C000000003", vin("A003"), "D00002", "PCUST1",
          20250620, 22000.00, "CUSTCASH", "N", "N"),
    # 4 loyalty, prior ownership, stackable -> base + bonus
    claim("C000000004", vin("A004"), "D00001", "PLOYL1",
          20250701, 40000.00, "LOYALTY", "Y", "N"),
    # 5 loyalty, no prior ownership -> HOLD LOYX
    claim("C000000005", vin("A005"), "D00001", "PLOYL1",
          20250701, 40000.00, "LOYALTY", "N", "N"),
    # 6 dealer not enrolled -> HOLD DLRE
    claim("C000000006", vin("A006"), "D00003", "PFLAT1",
          20250615, 25000.00, "RETAIL", "N", "N"),
    # 7 dealer inactive -> HOLD DLRI
    claim("C000000007", vin("A007"), "D00004", "PFLAT1",
          20250615, 25000.00, "RETAIL", "N", "N"),
    # 8 dealer not found -> HOLD DLRN
    claim("C000000008", vin("A008"), "D99999", "PFLAT1",
          20250615, 25000.00, "RETAIL", "N", "N"),
    # 9 program not found -> HOLD PRGN
    claim("C000000009", vin("A009"), "D00001", "P99999",
          20250615, 25000.00, "RETAIL", "N", "N"),
    # 10 sale date outside program window -> HOLD PRGW
    claim("C000000010", vin("A010"), "D00001", "PFLAT1",
          20240615, 25000.00, "RETAIL", "N", "N"),
    # 11 region ineligible (NE dealer, WST program) -> HOLD RGNX
    claim("C000000011", vin("A011"), "D00001", "PRGNW1",
          20250615, 25000.00, "RETAIL", "N", "N"),
    # 12 PCT program, program cap binds -> PAID 2000.00 capped
    claim("C000000012", vin("A012"), "D00001", "PCAP01",
          20250615, 30000.00, "RETAIL", "N", "N"),
    # 13 duplicate of claim 1 (same VIN + program) -> HOLD DUP
    claim("C000000013", vin("A001"), "D00001", "PFLAT1",
          20250616, 28500.00, "RETAIL", "N", "N"),
    # 14 reversal of claim 1's incentive -> RVSD negative
    claim("C000000014", vin("A001"), "D00001", "PFLAT1",
          20250630, 28500.00, "REVERSAL", "N", "N"),
    # 15 edit reject: zero sale price -> REJ EDIT
    claim("C000000015", vin("A015"), "D00001", "PFLAT1",
          20250615, 0.00, "RETAIL", "N", "N"),
    # 16 edit reject: unknown claim type -> REJ EDIT
    claim("C000000016", vin("A016"), "D00001", "PFLAT1",
          20250615, 25000.00, "BOGUS", "N", "N"),
    # 17 PCT program, global payout cap binds -> PAID 10000.00 capped
    claim("C000000017", vin("A017"), "D00001", "PGCAP1",
          20250615, 30000.00, "RETAIL", "N", "N"),
]


def main():
    INPUT_DIR.mkdir(parents=True, exist_ok=True)
    (INPUT_DIR / "dealers.dat").write_text("\n".join(DEALERS) + "\n")
    (INPUT_DIR / "programs.dat").write_text("\n".join(PROGRAMS) + "\n")
    (INPUT_DIR / "claims.dat").write_text("\n".join(CLAIMS) + "\n")
    print(f"wrote {len(DEALERS)} dealers, {len(PROGRAMS)} programs, "
          f"{len(CLAIMS)} claims to {INPUT_DIR}")


if __name__ == "__main__":
    main()
