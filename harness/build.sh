#!/usr/bin/env bash
# Compile the legacy incentive batch with GnuCOBOL.
#
# This is the "oracle harness" from the conversion brief: the COBOL that ran
# on the mainframe is transpiled and compiled on Linux so the batch can be
# exercised against known input/output pairs. INCMAIN is the main program;
# the eligibility, calculation, payout, reversal and exception subprograms
# are statically linked into a single executable.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COBOL="$ROOT/legacy/cobol"
COPY="$ROOT/legacy/copybook"
BUILD="$ROOT/build"

mkdir -p "$BUILD"

echo "==> compiling INCMAIN + subprograms (GnuCOBOL $(cobc --version | head -1 | awk '{print $NF}'))"
cobc -x -fixed -Wall \
    -I "$COPY" \
    -o "$BUILD/incmain" \
    "$COBOL/INCMAIN.cbl" \
    "$COBOL/INCEDIT.cbl" \
    "$COBOL/INCEXC.cbl" \
    "$COBOL/INCVAL.cbl" \
    "$COBOL/INCELIG.cbl" \
    "$COBOL/INCCALC.cbl" \
    "$COBOL/INCREV.cbl" \
    "$COBOL/INCPAY.cbl"

echo "==> built $BUILD/incmain"
