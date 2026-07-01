       IDENTIFICATION DIVISION.
       PROGRAM-ID. INCMAIN.
      *================================================================*
      * INCMAIN - DEALER-INCENTIVE CLAIM PROCESSING DRIVER            *
      *                                                                *
      * NIGHTLY BATCH THAT TURNS THE DAILY CLAIM FEED INTO A PAYOUT   *
      * REGISTER. FOR EACH CLAIM IT ORCHESTRATES THE FULL PIPELINE:   *
      *                                                                *
      *   INCEDIT  - STRUCTURAL FIELD EDITS                           *
      *   INCEXC   - DUPLICATE / EXCEPTION SCREEN                     *
      *   INCVAL   - DEALER + PROGRAM ELIGIBILITY (CALLS INCELIG)     *
      *   INCCALC  - INCENTIVE AMOUNT (FLAT / PCT, LOYALTY, CAPS)     *
      *   INCREV   - REVERSAL / CLAWBACK (NEGATIVE PAYOUT)            *
      *   INCPAY   - PAYOUT METHOD / PAYEE DETERMINATION              *
      *                                                                *
      * INPUT  DDS : CLAIMS  DEALERS  PROGRAMS                        *
      * OUTPUT DD  : PAYOUT  (PAYOUT REGISTER, ONE REC PER CLAIM)     *
      *                                                                *
      * SEE JCL/INCDAILY.jcl FOR THE PRODUCTION INVOCATION.           *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CLAIM-FILE   ASSIGN TO CLAIMS
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-CLAIM-STATUS.
           SELECT DEALER-FILE  ASSIGN TO DEALERS
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-DEALER-STATUS.
           SELECT PROGRAM-FILE ASSIGN TO PROGRAMS
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-PROGRAM-STATUS.
           SELECT PAYOUT-FILE  ASSIGN TO PAYOUT
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-PAYOUT-STATUS.
      *
       DATA DIVISION.
       FILE SECTION.
       FD  CLAIM-FILE.
       01  CLAIM-FILE-REC             PIC X(80).
       FD  DEALER-FILE.
       01  DEALER-FILE-REC            PIC X(80).
       FD  PROGRAM-FILE.
       01  PROGRAM-FILE-REC           PIC X(100).
       FD  PAYOUT-FILE.
       01  PAYOUT-FILE-REC            PIC X(80).
      *
       WORKING-STORAGE SECTION.
       COPY ERRCODES.
       01  WS-FILE-STATUS.
           05  WS-CLAIM-STATUS        PIC X(02).
           05  WS-DEALER-STATUS       PIC X(02).
           05  WS-PROGRAM-STATUS      PIC X(02).
           05  WS-PAYOUT-STATUS       PIC X(02).
      *
       01  WS-FLAGS.
           05  WS-EOF-CLAIMS          PIC X(01) VALUE 'N'.
               88  END-OF-CLAIMS          VALUE 'Y'.
           05  WS-EOF-DEALERS         PIC X(01) VALUE 'N'.
               88  END-OF-DEALERS         VALUE 'Y'.
           05  WS-EOF-PROGRAMS        PIC X(01) VALUE 'N'.
               88  END-OF-PROGRAMS        VALUE 'Y'.
           05  WS-DEALER-FOUND-FLAGS.
               10  LK-DEALER-FOUND    PIC X(01).
                   88  DEALER-WAS-FOUND   VALUE 'Y'.
               10  LK-PROGRAM-FOUND   PIC X(01).
                   88  PROGRAM-WAS-FOUND  VALUE 'Y'.
           05  WS-DUP-FLAG            PIC X(01).
      *
       01  WS-COUNTERS.
           05  WS-DEALER-COUNT        PIC 9(04) VALUE 0.
           05  WS-PROGRAM-COUNT       PIC 9(04) VALUE 0.
           05  WS-PAID-COUNT          PIC 9(04) VALUE 0.
           05  WS-DEALER-IDX          PIC 9(04).
           05  WS-PROGRAM-IDX         PIC 9(04).
           05  WS-PAID-IDX            PIC 9(04).
      *
      *    IN-CORE MASTER TABLES (LOADED ONCE AT START-UP).
       01  WS-DEALER-TABLE.
           05  WS-DEALER-ENTRY        OCCURS 100 TIMES
                                      INDEXED BY DLR-IX.
               10  WT-DEALER-REC      PIC X(80).
       01  WS-PROGRAM-TABLE.
           05  WS-PROGRAM-ENTRY       OCCURS 100 TIMES
                                      INDEXED BY PRG-IX.
               10  WT-PROGRAM-REC     PIC X(100).
      *
      *    PAID-KEY TABLE FOR DUPLICATE DETECTION (VIN + PROGRAM-ID).
       01  WS-PAID-TABLE.
           05  WS-PAID-ENTRY          OCCURS 1000 TIMES.
               10  WT-PAID-KEY        PIC X(23).
      *
       01  WS-WORK-KEY                PIC X(23).
      *
       COPY CLAIMREC.
       COPY DEALERREC.
       COPY PROGREC.
       COPY PAYOUTREC.
       COPY INCRESULT.
       COPY INCCONST.
      *
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INIT
           PERFORM 2000-LOAD-DEALERS
           PERFORM 3000-LOAD-PROGRAMS
           PERFORM 4000-PROCESS-CLAIMS UNTIL END-OF-CLAIMS
           PERFORM 9000-WRAPUP
           STOP RUN.
      *
       1000-INIT.
           OPEN INPUT  CLAIM-FILE DEALER-FILE PROGRAM-FILE
           OPEN OUTPUT PAYOUT-FILE
           IF WS-CLAIM-STATUS NOT = '00'
               DISPLAY 'INCMAIN: CANNOT OPEN CLAIMS, STATUS '
                       WS-CLAIM-STATUS
               MOVE 16 TO RETURN-CODE
               STOP RUN
           END-IF.
      *
       2000-LOAD-DEALERS.
           PERFORM UNTIL END-OF-DEALERS
               READ DEALER-FILE INTO DEALER-REC
                   AT END SET END-OF-DEALERS TO TRUE
                   NOT AT END
                       ADD 1 TO WS-DEALER-COUNT
                       MOVE DEALER-REC
                         TO WT-DEALER-REC(WS-DEALER-COUNT)
               END-READ
           END-PERFORM.
      *
       3000-LOAD-PROGRAMS.
           PERFORM UNTIL END-OF-PROGRAMS
               READ PROGRAM-FILE INTO PROGRAM-REC
                   AT END SET END-OF-PROGRAMS TO TRUE
                   NOT AT END
                       ADD 1 TO WS-PROGRAM-COUNT
                       MOVE PROGRAM-REC
                         TO WT-PROGRAM-REC(WS-PROGRAM-COUNT)
               END-READ
           END-PERFORM.
      *
       4000-PROCESS-CLAIMS.
           READ CLAIM-FILE INTO CLAIM-REC
               AT END SET END-OF-CLAIMS TO TRUE
               NOT AT END
                   PERFORM 5000-PROCESS-ONE-CLAIM THRU 5000-EXIT
           END-READ.
      *
       5000-PROCESS-ONE-CLAIM.
           PERFORM 5050-INIT-PAYOUT
      *    1) STRUCTURAL EDIT
           CALL 'INCEDIT' USING CLAIM-REC ELIG-RESULT
           IF NOT ELIG-PASSED
               MOVE 'REJ ' TO PAY-STATUS
               MOVE ELIG-REASON TO PAY-REASON
               PERFORM 8000-WRITE-PAYOUT
               GO TO 5000-EXIT
           END-IF
      *    2) REVERSAL PATH IS SEPARATE FROM THE FORWARD PATH
           IF CLM-REVERSAL
               PERFORM 6000-HANDLE-REVERSAL
               GO TO 5000-EXIT
           END-IF
      *    3) DUPLICATE SCREEN
           PERFORM 7000-CHECK-DUPLICATE
           CALL 'INCEXC' USING CLAIM-REC WS-DUP-FLAG ELIG-RESULT
           IF NOT ELIG-PASSED
               MOVE 'HOLD' TO PAY-STATUS
               MOVE ELIG-REASON TO PAY-REASON
               PERFORM 8000-WRITE-PAYOUT
               GO TO 5000-EXIT
           END-IF
      *    4) ELIGIBILITY (DEALER + PROGRAM + INCELIG)
           PERFORM 7100-LOOKUP-DEALER
           PERFORM 7200-LOOKUP-PROGRAM
           CALL 'INCVAL' USING CLAIM-REC DEALER-REC PROGRAM-REC
                               WS-DEALER-FOUND-FLAGS ELIG-RESULT
           IF NOT ELIG-PASSED
               MOVE 'HOLD' TO PAY-STATUS
               MOVE ELIG-REASON TO PAY-REASON
               PERFORM 8000-WRITE-PAYOUT
               GO TO 5000-EXIT
           END-IF
      *    5) CALCULATE INCENTIVE
           CALL 'INCCALC' USING CLAIM-REC PROGRAM-REC CALC-RESULT
      *    6) DETERMINE PAYOUT METHOD
           CALL 'INCPAY' USING CLAIM-REC PROGRAM-REC PAY-RESULT
           MOVE 'PAID' TO PAY-STATUS
           MOVE RC-OK  TO PAY-REASON
           MOVE PAYR-METHOD     TO PAY-METHOD
           MOVE PAYR-PAYEE-TYPE TO PAY-PAYEE-TYPE
           MOVE CALC-AMOUNT     TO PAY-AMOUNT
      *    STORE-THEN-INCREMENT: 7300 STORES AT WS-PAID-COUNT + 1,
      *    THEN THIS BUMP MAKES IT THE LIVE COUNT (ORDER MATTERS).
           PERFORM 7300-REMEMBER-PAID
           ADD 1 TO WS-PAID-COUNT
           PERFORM 8000-WRITE-PAYOUT.
       5000-EXIT.
           EXIT.
      *
       5050-INIT-PAYOUT.
           INITIALIZE PAYOUT-REC
           MOVE CLM-CLAIM-ID   TO PAY-CLAIM-ID
           MOVE CLM-VIN        TO PAY-VIN
           MOVE CLM-DEALER-ID  TO PAY-DEALER-ID
           MOVE CLM-PROGRAM-ID TO PAY-PROGRAM-ID
           MOVE 'CREDIT'       TO PAY-METHOD
           MOVE 'D'            TO PAY-PAYEE-TYPE
           MOVE ZERO           TO PAY-AMOUNT.
      *
       6000-HANDLE-REVERSAL.
           PERFORM 7200-LOOKUP-PROGRAM
           IF NOT PROGRAM-WAS-FOUND
               MOVE 'HOLD' TO PAY-STATUS
               MOVE RC-PROGRAM-NOT-FOUND TO PAY-REASON
               PERFORM 8000-WRITE-PAYOUT
           ELSE
               CALL 'INCREV' USING CLAIM-REC PROGRAM-REC CALC-RESULT
               MOVE 'RVSD' TO PAY-STATUS
               MOVE RC-OK  TO PAY-REASON
               MOVE CALC-AMOUNT TO PAY-AMOUNT
               PERFORM 8000-WRITE-PAYOUT
           END-IF.
      *
       7000-CHECK-DUPLICATE.
           MOVE 'N' TO WS-DUP-FLAG
           STRING CLM-VIN CLM-PROGRAM-ID DELIMITED BY SIZE
               INTO WS-WORK-KEY
           END-STRING
           PERFORM VARYING WS-PAID-IDX FROM 1 BY 1
                   UNTIL WS-PAID-IDX > WS-PAID-COUNT
               IF WT-PAID-KEY(WS-PAID-IDX) = WS-WORK-KEY
                   MOVE 'Y' TO WS-DUP-FLAG
               END-IF
           END-PERFORM.
      *
       7100-LOOKUP-DEALER.
           MOVE 'N' TO LK-DEALER-FOUND
           PERFORM VARYING WS-DEALER-IDX FROM 1 BY 1
                   UNTIL WS-DEALER-IDX > WS-DEALER-COUNT
               IF WT-DEALER-REC(WS-DEALER-IDX)(1:6) = CLM-DEALER-ID
                   MOVE WT-DEALER-REC(WS-DEALER-IDX) TO DEALER-REC
                   MOVE 'Y' TO LK-DEALER-FOUND
               END-IF
           END-PERFORM.
      *
       7200-LOOKUP-PROGRAM.
           MOVE 'N' TO LK-PROGRAM-FOUND
           PERFORM VARYING WS-PROGRAM-IDX FROM 1 BY 1
                   UNTIL WS-PROGRAM-IDX > WS-PROGRAM-COUNT
               IF WT-PROGRAM-REC(WS-PROGRAM-IDX)(1:6) = CLM-PROGRAM-ID
                   MOVE WT-PROGRAM-REC(WS-PROGRAM-IDX) TO PROGRAM-REC
                   MOVE 'Y' TO LK-PROGRAM-FOUND
               END-IF
           END-PERFORM.
      *
       7300-REMEMBER-PAID.
      *    INDEX IS COUNT + 1: THE CALLER BUMPS WS-PAID-COUNT ONLY
      *    AFTER THIS PERFORM (SEE 5000-PROCESS-ONE-CLAIM).
           MOVE WS-WORK-KEY TO WT-PAID-KEY(WS-PAID-COUNT + 1).
      *
       8000-WRITE-PAYOUT.
           WRITE PAYOUT-FILE-REC FROM PAYOUT-REC.
      *
       9000-WRAPUP.
           CLOSE CLAIM-FILE DEALER-FILE PROGRAM-FILE PAYOUT-FILE
           DISPLAY 'INCMAIN: DEALERS LOADED  = ' WS-DEALER-COUNT
           DISPLAY 'INCMAIN: PROGRAMS LOADED = ' WS-PROGRAM-COUNT
           DISPLAY 'INCMAIN: CLAIMS PAID     = ' WS-PAID-COUNT.
