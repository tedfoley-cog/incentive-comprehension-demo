      *================================================================*
      * CLAIMREC - INCENTIVE CLAIM RECORD (80 BYTES)                   *
      *                                                                *
      * RECORD LAYOUT FOR THE DAILY DEALER-INCENTIVE CLAIM FEED.       *
      * ONE RECORD PER CLAIM SUBMITTED BY A DEALER FOR A VEHICLE SALE. *
      * SHARED BY: INCEDIT, INCMAIN, INCVAL, INCELIG, INCCALC,         *
      *            INCPAY, INCREV, INCEXC                              *
      * MIRRORS DB2 TABLE CLAIM (SEE DCLCLAIM / DB2/SCHEMA.SQL).       *
      *================================================================*
       01  CLAIM-REC.
           05  CLM-CLAIM-ID           PIC X(10).
           05  CLM-VIN                PIC X(17).
           05  CLM-DEALER-ID          PIC X(06).
           05  CLM-PROGRAM-ID         PIC X(06).
           05  CLM-SALE-DATE          PIC 9(08).
               88  CLM-SALE-DATE-ZERO     VALUE 0.
           05  CLM-SALE-PRICE         PIC 9(07)V99.
           05  CLM-CLAIM-TYPE         PIC X(08).
               88  CLM-RETAIL             VALUE 'RETAIL  '.
               88  CLM-CUSTCASH           VALUE 'CUSTCASH'.
               88  CLM-LOYALTY            VALUE 'LOYALTY '.
               88  CLM-REVERSAL           VALUE 'REVERSAL'.
           05  CLM-PRIOR-OWN          PIC X(01).
               88  CLM-HAS-PRIOR-OWN      VALUE 'Y'.
           05  CLM-CUST-BANK          PIC X(01).
               88  CLM-HAS-BANK           VALUE 'Y'.
           05  FILLER                 PIC X(14).
