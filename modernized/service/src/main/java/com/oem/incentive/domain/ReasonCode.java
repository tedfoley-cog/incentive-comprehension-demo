package com.oem.incentive.domain;

/**
 * Eligibility / rejection reason codes preserved from the legacy ERRCODES copybook.
 * The 4-char {@link #legacyCode} is kept byte-identical for parity with the
 * PAYOUTREC PAY-REASON field.
 */
public enum ReasonCode {

    OK  ("OK  "),
    DLRN("DLRN"),
    DLRE("DLRE"),
    DLRI("DLRI"),
    PRGN("PRGN"),
    PRGW("PRGW"),
    RGNX("RGNX"),
    LOYX("LOYX"),
    DUP ("DUP "),
    EDIT("EDIT");

    private final String legacyCode;

    ReasonCode(String legacyCode) {
        this.legacyCode = legacyCode;
    }

    public String legacyCode() {
        return legacyCode;
    }
}
