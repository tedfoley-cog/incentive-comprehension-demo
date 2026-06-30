      *================================================================*
      * PAYOUTREC - PAYOUT REGISTER RECORD (80 BYTES)                  *
      *                                                                *
      * OUTPUT OF INCMAIN: ONE RECORD PER PROCESSED CLAIM. CONSUMED BY *
      * INCRPT (REPORTING) AND BY THE DOWNSTREAM GENERAL-LEDGER FEED.  *
      * PAY-AMOUNT IS SIGNED: REVERSALS (CLAWBACKS) ARE NEGATIVE.      *
      *================================================================*
       01  PAYOUT-REC.
           05  PAY-CLAIM-ID           PIC X(10).
           05  PAY-VIN                PIC X(17).
           05  PAY-DEALER-ID          PIC X(06).
           05  PAY-PROGRAM-ID         PIC X(06).
           05  PAY-STATUS             PIC X(04).
               88  PAY-IS-PAID            VALUE 'PAID'.
               88  PAY-IS-HOLD            VALUE 'HOLD'.
               88  PAY-IS-REVERSED        VALUE 'RVSD'.
               88  PAY-IS-REJECTED        VALUE 'REJ '.
           05  PAY-METHOD             PIC X(06).
               88  PAY-VIA-CREDIT         VALUE 'CREDIT'.
               88  PAY-VIA-ACH            VALUE 'ACH   '.
               88  PAY-VIA-CHECK          VALUE 'CHECK '.
           05  PAY-PAYEE-TYPE         PIC X(01).
           05  PAY-REASON             PIC X(04).
           05  PAY-AMOUNT             PIC S9(7)V99
                                      SIGN IS LEADING SEPARATE.
           05  FILLER                 PIC X(16).
