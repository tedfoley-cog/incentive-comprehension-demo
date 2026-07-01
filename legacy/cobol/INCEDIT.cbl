       IDENTIFICATION DIVISION.
       PROGRAM-ID. INCEDIT.
      *================================================================*
      * INCEDIT - FRONT-END FIELD EDIT / STANDARDISATION              *
      *                                                                *
      * FIRST PASS OVER EVERY INBOUND CLAIM. REJECTS STRUCTURALLY      *
      * INVALID RECORDS BEFORE ANY ELIGIBILITY WORK IS ATTEMPTED:      *
      *   - CLAIM-ID MUST BE NON-BLANK                                *
      *   - VIN MUST BE 17 CHARACTERS (NON-BLANK)                     *
      *   - SALE-DATE MUST BE A REAL CCYYMMDD VALUE                   *
      *   - SALE-PRICE MUST BE GREATER THAN ZERO                      *
      *   - CLAIM-TYPE MUST BE A KNOWN VALUE                          *
      *                                                                *
      * CALLED BY: INCMAIN                                            *
      * COPYBOOKS: CLAIMREC INCRESULT ERRCODES                        *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY ERRCODES.
       01  WS-MONTH                   PIC 9(02).
       01  WS-DAY                     PIC 9(02).
      *
       LINKAGE SECTION.
       COPY CLAIMREC.
       COPY INCRESULT.
      *
       PROCEDURE DIVISION USING CLAIM-REC ELIG-RESULT.
       0000-MAIN.
           MOVE 00 TO ELIG-RC
           MOVE RC-OK TO ELIG-REASON
           EVALUATE TRUE
               WHEN CLM-CLAIM-ID = SPACES
                   PERFORM 9000-REJECT
               WHEN CLM-VIN = SPACES
                   PERFORM 9000-REJECT
               WHEN CLM-SALE-DATE-ZERO
                   PERFORM 9000-REJECT
               WHEN CLM-SALE-PRICE = ZERO
                   PERFORM 9000-REJECT
               WHEN NOT (CLM-RETAIL OR CLM-CUSTCASH
                         OR CLM-LOYALTY OR CLM-REVERSAL)
                   PERFORM 9000-REJECT
               WHEN OTHER
                   PERFORM 1000-CHECK-DATE-PARTS
           END-EVALUATE
           GOBACK.
      *
       1000-CHECK-DATE-PARTS.
           MOVE CLM-SALE-DATE(5:2) TO WS-MONTH
           MOVE CLM-SALE-DATE(7:2) TO WS-DAY
           IF WS-MONTH < 01 OR WS-MONTH > 12
              OR WS-DAY < 01 OR WS-DAY > 31
               PERFORM 9000-REJECT
           END-IF.
      *
       9000-REJECT.
           MOVE 90 TO ELIG-RC
           MOVE RC-EDIT-REJECT TO ELIG-REASON.
