package com.oem.incentive.domain;

import java.math.BigDecimal;

/**
 * Single source of truth for system-wide incentive parameters.
 *
 * In the legacy estate these values are triple-duplicated across the COBOL
 * copybook (INCCONST.cpy), the DB2 PARM table, and the JCL control card
 * (INCPARM.txt). The reimagined service collapses them here.
 */
public final class IncentiveConstants {

    /** Hard ceiling on any single payout (Dealer-Agreement Policy 4.2). */
    public static final BigDecimal GLOBAL_PAYOUT_CAP = new BigDecimal("10000.00");

    /** Loyalty-stack bonus added on top of the base program amount. */
    public static final BigDecimal LOYALTY_BONUS = new BigDecimal("500.00");

    private IncentiveConstants() { }
}
