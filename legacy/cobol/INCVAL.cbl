       IDENTIFICATION DIVISION.
       PROGRAM-ID. INCVAL.
      *================================================================*
      * INCVAL - CLAIM ELIGIBILITY VALIDATION (DEALER-LEVEL)          *
      *                                                                *
      * VALIDATES DEALER-LEVEL ELIGIBILITY, THEN DELEGATES PROGRAM-   *
      * LEVEL RULES TO INCELIG. RETURNS A SINGLE REASON CODE THAT     *
      * INCMAIN USES TO DECIDE PAY VS HOLD.                           *
      *                                                                *
      * ORDER OF CHECKS (FIRST FAILURE WINS):                         *
      *   DEALER FOUND -> ENROLLED -> ACTIVE -> PROGRAM FOUND ->      *
      *   (INCELIG) WINDOW -> REGION -> LOYALTY                       *
      *                                                                *
      * CALLED BY: INCMAIN     CALLS: INCELIG                         *
      * COPYBOOKS: CLAIMREC PROGREC DEALERREC INCRESULT ERRCODES      *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY ERRCODES.
      *
       LINKAGE SECTION.
       COPY CLAIMREC.
       COPY DEALERREC.
       COPY PROGREC.
       01  LK-FOUND-FLAGS.
           05  LK-DEALER-FOUND        PIC X(01).
               88  DEALER-WAS-FOUND       VALUE 'Y'.
           05  LK-PROGRAM-FOUND       PIC X(01).
               88  PROGRAM-WAS-FOUND      VALUE 'Y'.
       COPY INCRESULT.
      *
       PROCEDURE DIVISION USING CLAIM-REC DEALER-REC PROGRAM-REC
                                LK-FOUND-FLAGS ELIG-RESULT.
       0000-MAIN.
           MOVE 00 TO ELIG-RC
           MOVE RC-OK TO ELIG-REASON
           EVALUATE TRUE
               WHEN NOT DEALER-WAS-FOUND
                   MOVE 10 TO ELIG-RC
                   MOVE RC-DEALER-NOT-FOUND TO ELIG-REASON
               WHEN NOT DLR-IS-ENROLLED
                   MOVE 11 TO ELIG-RC
                   MOVE RC-DEALER-NOT-ENROLL TO ELIG-REASON
               WHEN DLR-IS-INACTIVE
                   MOVE 12 TO ELIG-RC
                   MOVE RC-DEALER-INACTIVE TO ELIG-REASON
               WHEN NOT PROGRAM-WAS-FOUND
                   MOVE 20 TO ELIG-RC
                   MOVE RC-PROGRAM-NOT-FOUND TO ELIG-REASON
               WHEN OTHER
                   CALL 'INCELIG' USING CLAIM-REC PROGRAM-REC
                                        DEALER-REC ELIG-RESULT
           END-EVALUATE
           GOBACK.
