package com.oem.incentive.model;

import java.math.BigDecimal;

public record ProgramRef(
        String programId,
        String description,
        String type,
        BigDecimal flatAmount,
        BigDecimal pctRate,
        int startDate,
        int endDate,
        char payee,
        String region,
        boolean stackable,
        boolean reqPriorOwn,
        BigDecimal maxIncentive
) { }
