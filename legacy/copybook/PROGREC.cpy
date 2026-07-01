      *================================================================*
      * PROGREC - INCENTIVE PROGRAM MASTER RECORD (100 BYTES)          *
      *                                                                *
      * ONE RECORD PER INCENTIVE PROGRAM. DEFINES THE RULES THAT THE   *
      * ELIGIBILITY ENGINE (INCELIG) AND CALCULATION ENGINE (INCCALC)  *
      * APPLY: PAYOUT BASIS, ELIGIBLE WINDOW, REGION, STACKING, CAP.   *
      *================================================================*
       01  PROGRAM-REC.
           05  PRG-PROGRAM-ID         PIC X(06).
           05  PRG-DESC               PIC X(30).
           05  PRG-TYPE               PIC X(04).
               88  PRG-IS-FLAT            VALUE 'FLAT'.
               88  PRG-IS-PCT             VALUE 'PCT '.
           05  PRG-FLAT-AMOUNT        PIC 9(07)V99.
           05  PRG-PCT-RATE           PIC 9(03)V99.
           05  PRG-START-DATE         PIC 9(08).
           05  PRG-END-DATE           PIC 9(08).
           05  PRG-PAYEE              PIC X(01).
               88  PRG-PAYEE-DEALER       VALUE 'D'.
               88  PRG-PAYEE-CUSTOMER     VALUE 'C'.
           05  PRG-REGION             PIC X(04).
               88  PRG-REGION-ALL         VALUE 'ALL '.
           05  PRG-STACKABLE          PIC X(01).
               88  PRG-IS-STACKABLE       VALUE 'Y'.
           05  PRG-REQ-PRIOR-OWN      PIC X(01).
               88  PRG-REQ-LOYALTY        VALUE 'Y'.
           05  PRG-MAX-INCENTIVE      PIC 9(07)V99.
           05  FILLER                 PIC X(14).
