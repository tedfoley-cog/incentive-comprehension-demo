       IDENTIFICATION DIVISION.
       PROGRAM-ID. INCCALC.
      *================================================================*
      * INCCALC - INCENTIVE CALCULATION ENGINE                        *
      *                                                                *
      * COMPUTES THE GROSS INCENTIVE FOR AN ELIGIBLE CLAIM:           *
      *   FLAT PROGRAM : AMOUNT = PRG-FLAT-AMOUNT                     *
      *   PCT  PROGRAM : AMOUNT = SALE-PRICE * PRG-PCT-RATE / 100     *
      * LOYALTY CLAIMS ON A STACKABLE PROGRAM ADD WC-LOYALTY-BONUS.   *
      * RESULT IS CAPPED AT PRG-MAX-INCENTIVE THEN AT THE GLOBAL CAP. *
      *                                                                *
      * CALLED BY: INCMAIN, INCREV                                    *
      * COPYBOOKS: CLAIMREC PROGREC INCRESULT INCCONST                *
      *                                                                *
      * NOTE: PRODUCTION ALSO HOLDS A RATE TABLE IN DB2 (SP_RATE_     *
      * LOOKUP). THE PCT PATH BELOW IS THE COBOL FALLBACK COPY.       *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY INCCONST.
       01  WS-GROSS                   PIC S9(7)V99 VALUE 0.
      *
       LINKAGE SECTION.
       COPY CLAIMREC.
       COPY PROGREC.
       COPY INCRESULT.
      *
       PROCEDURE DIVISION USING CLAIM-REC PROGRAM-REC CALC-RESULT.
       0000-MAIN.
           MOVE 'N' TO CALC-CAPPED
           PERFORM 1000-COMPUTE-BASE
           PERFORM 2000-APPLY-LOYALTY
           PERFORM 3000-APPLY-CAPS
           MOVE WS-GROSS TO CALC-AMOUNT
           GOBACK.
      *
       1000-COMPUTE-BASE.
           IF PRG-IS-PCT
               COMPUTE WS-GROSS ROUNDED =
                   (CLM-SALE-PRICE * PRG-PCT-RATE) / 100
           ELSE
               MOVE PRG-FLAT-AMOUNT TO WS-GROSS
           END-IF.
      *
       2000-APPLY-LOYALTY.
           IF CLM-LOYALTY AND PRG-IS-STACKABLE
               ADD WC-LOYALTY-BONUS TO WS-GROSS
           END-IF.
      *
       3000-APPLY-CAPS.
           IF WS-GROSS > PRG-MAX-INCENTIVE
               MOVE PRG-MAX-INCENTIVE TO WS-GROSS
               MOVE 'Y' TO CALC-CAPPED
           END-IF
           IF WS-GROSS > WC-GLOBAL-PAYOUT-CAP
               MOVE WC-GLOBAL-PAYOUT-CAP TO WS-GROSS
               MOVE 'Y' TO CALC-CAPPED
           END-IF.
