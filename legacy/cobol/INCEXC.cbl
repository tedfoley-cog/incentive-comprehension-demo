       IDENTIFICATION DIVISION.
       PROGRAM-ID. INCEXC.
      *================================================================*
      * INCEXC - EXCEPTION / DUPLICATE-CLAIM SCREENING                *
      *                                                                *
      * GUARDS AGAINST DOUBLE PAYMENT. A CLAIM IS A DUPLICATE WHEN    *
      * THE SAME VIN + PROGRAM-ID HAS ALREADY BEEN PAID IN THE        *
      * CURRENT RUN. DUPLICATES ARE PLACED ON HOLD (NOT REJECTED) SO  *
      * AN ANALYST CAN ADJUDICATE THEM IN THE EXCEPTION QUEUE.        *
      *                                                                *
      * INCMAIN MAINTAINS THE PAID-KEY TABLE AND PASSES A MATCH FLAG; *
      * INCEXC TRANSLATES THAT INTO A REASON CODE.                    *
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
      *
       LINKAGE SECTION.
       COPY CLAIMREC.
       01  LK-DUP-FLAG                PIC X(01).
           88  CLAIM-IS-DUPLICATE         VALUE 'Y'.
       COPY INCRESULT.
      *
       PROCEDURE DIVISION USING CLAIM-REC LK-DUP-FLAG ELIG-RESULT.
       0000-MAIN.
           IF CLAIM-IS-DUPLICATE
               MOVE 30 TO ELIG-RC
               MOVE RC-DUPLICATE-CLAIM TO ELIG-REASON
           ELSE
               MOVE 00 TO ELIG-RC
               MOVE RC-OK TO ELIG-REASON
           END-IF
           GOBACK.
