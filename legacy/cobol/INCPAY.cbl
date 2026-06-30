       IDENTIFICATION DIVISION.
       PROGRAM-ID. INCPAY.
      *================================================================*
      * INCPAY - PAYOUT METHOD / PAYEE DETERMINATION                  *
      *                                                                *
      * DECIDES HOW AN APPROVED INCENTIVE IS PAID:                    *
      *   PROGRAM PAYEE 'D' (DEALER)   -> DEALER CREDIT MEMO          *
      *   PROGRAM PAYEE 'C' (CUSTOMER) -> ACH IF BANK ON FILE,        *
      *                                   OTHERWISE A MAILED CHECK    *
      *                                                                *
      * CALLED BY: INCMAIN                                            *
      * COPYBOOKS: CLAIMREC PROGREC INCRESULT                         *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *
       LINKAGE SECTION.
       COPY CLAIMREC.
       COPY PROGREC.
       COPY INCRESULT.
      *
       PROCEDURE DIVISION USING CLAIM-REC PROGRAM-REC PAY-RESULT.
       0000-MAIN.
           IF PRG-PAYEE-CUSTOMER
               MOVE 'C' TO PAYR-PAYEE-TYPE
               IF CLM-HAS-BANK
                   MOVE 'ACH   ' TO PAYR-METHOD
               ELSE
                   MOVE 'CHECK ' TO PAYR-METHOD
               END-IF
           ELSE
               MOVE 'D' TO PAYR-PAYEE-TYPE
               MOVE 'CREDIT' TO PAYR-METHOD
           END-IF
           GOBACK.
