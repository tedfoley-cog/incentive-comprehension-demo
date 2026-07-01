#!/usr/bin/env bash
# Run the legacy incentive batch over the test fixtures.
#
# Mirrors JCL/INCDAILY.jcl: the DD names in the COBOL SELECT clauses
# (CLAIMS, DEALERS, PROGRAMS, PAYOUT) are bound here to flat files via
# environment variables, exactly as GnuCOBOL resolves ASSIGN TO names.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build"
INPUT="$ROOT/testdata/input"
OUT_DIR="${1:-$ROOT/build/out}"

if [[ ! -x "$BUILD/incmain" ]]; then
    echo "==> incmain not built yet; running build.sh"
    "$ROOT/harness/build.sh"
fi

if [[ ! -f "$INPUT/claims.dat" ]]; then
    echo "==> fixtures missing; generating"
    python3 "$ROOT/harness/make_fixtures.py"
fi

mkdir -p "$OUT_DIR"

echo "==> running INCMAIN"
CLAIMS="$INPUT/claims.dat" \
DEALERS="$INPUT/dealers.dat" \
PROGRAMS="$INPUT/programs.dat" \
PAYOUT="$OUT_DIR/payout.dat" \
    "$BUILD/incmain"

echo "==> payout register written to $OUT_DIR/payout.dat"
