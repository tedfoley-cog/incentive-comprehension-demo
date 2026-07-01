//INCGLFD  JOB (ACCT#),'INCENTIVE GL FEED',CLASS=A,MSGCLASS=X,
//             NOTIFY=&SYSUID
//*--------------------------------------------------------------------*
//* INCGLFD - GENERAL-LEDGER FEED EXTRACT                              *
//*                                                                    *
//* READS THE PAYOUT REGISTER FROM INCDAILY AND SPLITS IT INTO THE     *
//* DEBIT/CREDIT TRANSACTIONS POSTED TO THE GL. REVERSALS (NEGATIVE    *
//* PAY-AMOUNT) BECOME DEBITS; PAID CLAIMS BECOME CREDITS. HELD AND    *
//* REJECTED CLAIMS ARE FILTERED OUT BY THE SORT INCLUDE BELOW.        *
//*                                                                    *
//* RUNS AFTER:  INCDAILY (SEE scheduler/SCHEDULE.txt)                 *
//*--------------------------------------------------------------------*
//STEP010  EXEC PGM=SORT
//SYSOUT   DD SYSOUT=*
//SORTIN   DD DSN=OEM.INCENT.PAYOUT(+0),DISP=SHR
//SORTOUT  DD DSN=OEM.INCENT.GLFEED(+1),
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(CYL,(2,1),RLSE),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920)
//SYSIN    DD *
  INCLUDE COND=(40,4,CH,EQ,C'PAID',OR,40,4,CH,EQ,C'RVSD')
  SORT FIELDS=(34,6,CH,A,1,10,CH,A)
/*
//
