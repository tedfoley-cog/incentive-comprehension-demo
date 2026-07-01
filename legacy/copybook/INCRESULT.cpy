      *================================================================*
      * INCRESULT - INTER-PROGRAM RESULT AREAS                        *
      *                                                                *
      * PASSED BY REFERENCE BETWEEN INCMAIN AND ITS SUBPROGRAMS SO    *
      * THE LAYOUTS ARE IDENTICAL ON BOTH SIDES OF EACH CALL. THIS    *
      * IS THE SPINE OF THE END-TO-END CLAIM TRACE.                   *
      *================================================================*
       01  ELIG-RESULT.
           05  ELIG-RC                PIC 9(02).
               88  ELIG-PASSED            VALUE 00.
           05  ELIG-REASON            PIC X(04).
      *
       01  CALC-RESULT.
           05  CALC-AMOUNT            PIC S9(7)V99.
           05  CALC-CAPPED            PIC X(01).
               88  CALC-WAS-CAPPED        VALUE 'Y'.
      *
       01  PAY-RESULT.
           05  PAYR-METHOD            PIC X(06).
           05  PAYR-PAYEE-TYPE        PIC X(01).
