      *================================================================*
      * INCCONST - INCENTIVE PROCESSING CONSTANTS                     *
      *                                                                *
      * SYSTEM-WIDE TUNABLE CONSTANTS. IN PRODUCTION SOME OF THESE     *
      * ALSO EXIST IN THE DB2 PARM TABLE READ BY SP_RATE_LOOKUP -      *
      * A KNOWN DUPLICATION THAT COMPREHENSION MUST RECONCILE.         *
      *================================================================*
       01  INCENTIVE-CONSTANTS.
           05  WC-RETURN-OK           PIC 9(02) VALUE 00.
           05  WC-RETURN-FAIL         PIC 9(02) VALUE 12.
      *    HARD CEILING APPLIED TO ANY SINGLE PAYOUT REGARDLESS OF
      *    PROGRAM MAX (DEALER-AGREEMENT POLICY 4.2).
           05  WC-GLOBAL-PAYOUT-CAP   PIC 9(07)V99 VALUE 0010000.00.
      *    LOYALTY STACK BONUS APPLIED ON TOP OF THE BASE PROGRAM
           05  WC-LOYALTY-BONUS       PIC 9(07)V99 VALUE 0000500.00.
