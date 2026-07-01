package com.oem.incentive.model;

import java.math.BigDecimal;

public record PayoutResponse(
        String claimId,
        String vin,
        String dealerId,
        String programId,
        String status,
        String method,
        String payeeType,
        String reasonCode,
        BigDecimal amount
) { }
