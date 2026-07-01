       IDENTIFICATION DIVISION.
       PROGRAM-ID. INCELIG.
      *================================================================*
      * INCELIG - PROGRAM-LEVEL ELIGIBILITY ENGINE                    *
      *                                                                *
      * APPLIES THE INCENTIVE-PROGRAM RULES TO A CLAIM:               *
      *   1. SALE DATE MUST FALL INSIDE THE PROGRAM WINDOW            *
      *   2. DEALER REGION MUST MATCH PROGRAM REGION (OR 'ALL')       *
      *   3. LOYALTY PROGRAMS REQUIRE PRIOR-OWNERSHIP ON THE CLAIM    *
      *                                                                *
      * CALLED BY: INCVAL                                             *
      * COPYBOOKS: CLAIMREC, PROGREC, DEALERREC, INCRESULT, ERRCODES  *
      *                                                                *
      * NOTE: THE DATE-WINDOW RULE IS DUPLICATED IN DB2 PROCEDURE     *
      * SP_ELIGIBILITY. COMPREHENSION MUST RECONCILE THE TWO.         *
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
       COPY PROGREC.
       COPY DEALERREC.
       COPY INCRESULT.
      *
       PROCEDURE DIVISION USING CLAIM-REC PROGRAM-REC DEALER-REC
                                ELIG-RESULT.
       0000-MAIN.
           MOVE 00 TO ELIG-RC
           MOVE RC-OK TO ELIG-REASON
           PERFORM 1000-CHECK-WINDOW
           IF ELIG-PASSED
               PERFORM 2000-CHECK-REGION
           END-IF
           IF ELIG-PASSED
               PERFORM 3000-CHECK-LOYALTY
           END-IF
           GOBACK.
      *
       1000-CHECK-WINDOW.
           IF CLM-SALE-DATE < PRG-START-DATE
              OR CLM-SALE-DATE > PRG-END-DATE
               MOVE 21 TO ELIG-RC
               MOVE RC-PROGRAM-WINDOW TO ELIG-REASON
           END-IF.
      *
       2000-CHECK-REGION.
           IF NOT PRG-REGION-ALL
               IF PRG-REGION NOT = DLR-REGION
                   MOVE 22 TO ELIG-RC
                   MOVE RC-REGION-INELIGIBLE TO ELIG-REASON
               END-IF
           END-IF.
      *
       3000-CHECK-LOYALTY.
           IF PRG-REQ-LOYALTY
               IF NOT CLM-HAS-PRIOR-OWN
                   MOVE 23 TO ELIG-RC
                   MOVE RC-LOYALTY-NOT-QUAL TO ELIG-REASON
               END-IF
           END-IF.
