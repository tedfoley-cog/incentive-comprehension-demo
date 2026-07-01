#!/usr/bin/env python3
"""Equivalence driver: feeds legacy claim fixtures through the Spring Boot
service and emits a payout register in the identical PAYOUTREC layout so
compare.py can prove field-for-field parity.

Usage:
    driver.py <claims.dat> <output-payout.dat> [--base-url http://localhost:8080]
"""
import json
import sys
import urllib.request
from decimal import Decimal
from pathlib import Path

# CLAIMREC layout (80 bytes): offsets are 0-based.
#   claimId:10 vin:17 dealerId:6 programId:6 saleDate:8 salePrice:9
#   claimType:8 priorOwn:1 custBank:1 filler:14
CLAIM_FIELDS = [
    ("claimId",   0, 10),
    ("vin",       10, 17),
    ("dealerId",  27,  6),
    ("programId", 33,  6),
    ("saleDate",  39,  8),
    ("salePrice", 47,  9),
    ("claimType", 56,  8),
    ("priorOwn",  64,  1),
    ("custBank",  65,  1),
]


def parse_claim(line: str) -> dict:
    fields = {name: line[start:start + length]
              for name, start, length in CLAIM_FIELDS}
    sale_price_cents = int(fields["salePrice"])
    sale_price = Decimal(sale_price_cents) / Decimal(100)
    return {
        "claimId":   fields["claimId"],
        "vin":       fields["vin"],
        "dealerId":  fields["dealerId"],
        "programId": fields["programId"],
        "saleDate":  int(fields["saleDate"]),
        "salePrice": float(sale_price),
        "claimType": fields["claimType"].rstrip(),
        "priorOwn":  fields["priorOwn"] == "Y",
        "custBank":  fields["custBank"] == "Y",
    }


def format_payout(resp: dict) -> str:
    """Format a JSON response into an 80-byte PAYOUTREC line."""
    claim_id   = resp["claimId"].ljust(10)
    vin        = resp["vin"].ljust(17)
    dealer_id  = resp["dealerId"].ljust(6)
    program_id = resp["programId"].ljust(6)
    status     = resp["status"].ljust(4)
    method     = resp["method"].ljust(6)
    payee_type = resp["payeeType"][0]
    reason     = resp["reasonCode"].ljust(4)

    # Amount: PIC S9(7)V99 SIGN IS LEADING SEPARATE = sign + 9 digits
    amount = Decimal(str(resp["amount"]))
    sign = "-" if amount < 0 else "+"
    cents = abs(int(amount * 100))
    amount_str = sign + str(cents).zfill(9)

    filler = " " * 16
    rec = (claim_id + vin + dealer_id + program_id + status
           + method + payee_type + reason + amount_str + filler)
    assert len(rec) == 80, f"record length {len(rec)}, expected 80"
    return rec


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2

    claims_file = argv[1]
    output_file = argv[2]
    base_url = argv[3] if len(argv) > 3 else "http://localhost:8080"

    url = f"{base_url}/api/claims/process"
    lines = Path(claims_file).read_text().splitlines()
    results = []

    for raw in lines:
        if not raw.strip():
            continue
        claim = parse_claim(raw)
        body = json.dumps(claim).encode("utf-8")
        req = urllib.request.Request(
            url, data=body,
            headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req) as resp_http:
            resp = json.loads(resp_http.read())
        results.append(format_payout(resp))

    Path(output_file).write_text("\n".join(results) + "\n")
    print(f"wrote {len(results)} payout records to {output_file}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
