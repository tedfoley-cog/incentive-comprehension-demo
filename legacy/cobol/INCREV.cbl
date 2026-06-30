       IDENTIFICATION DIVISION.
       PROGRAM-ID. INCREV.
      *================================================================*
      * INCREV - REVERSAL / CLAWBACK PROCESSING                       *
      *                                                                *
      * WHEN A SALE IS UNWOUND, THE ORIGINAL INCENTIVE MUST BE        *
      * CLAWED BACK. INCREV RECOMPUTES THE BASE INCENTIVE FOR THE     *
      * VIN+PROGRAM (VIA INCCALC) AND NEGATES IT, PRODUCING A         *
      * NEGATIVE PAYOUT THAT THE GL FEED POSTS AS A DEBIT.            *
      *                                                                *
      * LOYALTY STACK BONUSES ARE NOT CLAWED BACK (POLICY 7.1), SO    *
      * THE CLAIM TYPE IS FORCED TO RETAIL BEFORE RECALCULATION.      *
      *                                                                *
      * CALLED BY: INCMAIN     CALLS: INCCALC                         *
      * COPYBOOKS: CLAIMREC PROGREC INCRESULT                         *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY CLAIMREC REPLACING ==CLAIM-REC== BY ==WS-CLAIM-WORK==.
      *
       LINKAGE SECTION.
       COPY CLAIMREC.
       COPY PROGREC.
       COPY INCRESULT.
      *
       PROCEDURE DIVISION USING CLAIM-REC PROGRAM-REC CALC-RESULT.
       0000-MAIN.
      *    RECALCULATE THE BASE AMOUNT WITHOUT ANY LOYALTY BONUS BY
      *    PRESENTING THE CLAIM TO INCCALC AS A RETAIL CLAIM.
           MOVE CLAIM-REC TO WS-CLAIM-WORK
           MOVE 'RETAIL  ' TO CLM-CLAIM-TYPE OF WS-CLAIM-WORK
           CALL 'INCCALC' USING WS-CLAIM-WORK PROGRAM-REC CALC-RESULT
           COMPUTE CALC-AMOUNT = CALC-AMOUNT * -1
           GOBACK.
