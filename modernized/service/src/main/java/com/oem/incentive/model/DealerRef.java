package com.oem.incentive.model;

public record DealerRef(
        String dealerId,
        String name,
        String region,
        boolean enrolled,
        char status
) { }
