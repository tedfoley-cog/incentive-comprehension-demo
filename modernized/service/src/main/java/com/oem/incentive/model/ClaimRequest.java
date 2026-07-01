package com.oem.incentive.model;

import java.math.BigDecimal;

public record ClaimRequest(
        String claimId,
        String vin,
        String dealerId,
        String programId,
        int saleDate,
        BigDecimal salePrice,
        String claimType,
        boolean priorOwn,
        boolean custBank
) { }
