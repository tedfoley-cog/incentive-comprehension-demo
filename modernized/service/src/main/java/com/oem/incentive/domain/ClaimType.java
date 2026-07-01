package com.oem.incentive.domain;

public enum ClaimType {

    RETAIL, CUSTCASH, LOYALTY, REVERSAL;

    public static ClaimType fromLegacy(String raw) {
        if (raw == null) {
            return null;
        }
        return switch (raw.trim()) {
            case "RETAIL"   -> RETAIL;
            case "CUSTCASH" -> CUSTCASH;
            case "LOYALTY"  -> LOYALTY;
            case "REVERSAL" -> REVERSAL;
            default         -> null;
        };
    }
}
