#!/usr/bin/env python3
"""Field-by-field equivalence comparison for the payout register.

This is the equivalence harness described in the conversion brief: it parses
two payout-register files using the PAYOUTREC copybook layout and reports any
field that differs, keyed by claim id. It is used two ways:

  * regression   - compare a fresh legacy run against the checked-in golden
                   register (testdata/expected/payout.dat)
  * equivalence  - compare the modernized service output against the legacy
                   register to prove behavioural parity during conversion

Usage:
    compare.py <expected.dat> <actual.dat>

Exit status is non-zero if any field differs, so it can gate CI.
"""
import sys
from pathlib import Path

# PAYOUTREC layout: (field-name, start, length). Offsets are 0-based.
FIELDS = [
    ("claim-id", 0, 10),
    ("vin", 10, 17),
    ("dealer-id", 27, 6),
    ("program-id", 33, 6),
    ("status", 39, 4),
    ("method", 43, 6),
    ("payee-type", 49, 1),
    ("reason", 50, 4),
    ("amount", 54, 10),  # sign char + 9 digits (LEADING SEPARATE)
]


def parse(path):
    records = {}
    order = []
    collisions = []
    for raw in Path(path).read_text().splitlines():
        if not raw.strip():
            continue
        rec = {name: raw[start:start + length]
               for name, start, length in FIELDS}
        key = rec["claim-id"]
        # a claim id can appear twice (e.g. forward + reversal); disambiguate
        # by status so both legs are compared independently.
        key = f"{key}/{rec['status'].strip()}"
        if key in records:
            # two records share claim-id AND status: the key no longer
            # identifies a unique row, so a silent overwrite would mask a
            # real difference. Surface it instead of dropping a record.
            collisions.append(key)
        records[key] = rec
        order.append(key)
    return records, order, collisions


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 2
    expected, exp_order, exp_dups = parse(argv[1])
    actual, _, act_dups = parse(argv[2])

    mismatches = 0

    for label, dups in (("expected", exp_dups), ("actual", act_dups)):
        for key in dups:
            print(f"COLLISION in {label}: duplicate claim-id/status {key} "
                  f"(record dropped — comparison would be unreliable)")
            mismatches += 1

    only_expected = [k for k in exp_order if k not in actual]
    only_actual = [k for k in actual if k not in expected]
    for k in only_expected:
        print(f"MISSING in actual: {k}")
        mismatches += 1
    for k in only_actual:
        print(f"UNEXPECTED in actual: {k}")
        mismatches += 1

    for key in exp_order:
        if key not in actual:
            continue
        exp_rec, act_rec = expected[key], actual[key]
        for name, _, _ in FIELDS:
            if exp_rec[name] != act_rec[name]:
                print(f"DIFF {key} field={name}: "
                      f"expected={exp_rec[name]!r} actual={act_rec[name]!r}")
                mismatches += 1

    total = len(exp_order)
    if mismatches == 0:
        print(f"EQUIVALENT: {total} claims match across all "
              f"{len(FIELDS)} fields")
        return 0
    print(f"NOT EQUIVALENT: {mismatches} field/record difference(s) "
          f"over {total} claims")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
