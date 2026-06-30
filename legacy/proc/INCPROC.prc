//INCPROC  PROC HLQ='OEM.INCENT',CYCLE='DAILY'
//*--------------------------------------------------------------------*
//* INCPROC - CATALOGED PROC FOR THE INCENTIVE ADJUDICATION STEP       *
//*                                                                    *
//* PARAMETERISES THE HIGH-LEVEL QUALIFIER (&HLQ) AND RUN CYCLE        *
//* (&CYCLE) SO THE SAME LOGIC RUNS FOR DAILY AND MONTH-END CYCLES.    *
//* INVOKED AS:  // EXEC INCPROC,CYCLE='MONTHLY'                       *
//*--------------------------------------------------------------------*
//ADJUD    EXEC PGM=INCMAIN
//STEPLIB  DD DSN=&HLQ..LOADLIB,DISP=SHR
//CLAIMS   DD DSN=&HLQ..CLAIMS.&CYCLE(+0),DISP=SHR
//DEALERS  DD DSN=&HLQ..DEALER.MASTER,DISP=SHR
//PROGRAMS DD DSN=&HLQ..PROGRAM.MASTER,DISP=SHR
//PAYOUT   DD DSN=&HLQ..PAYOUT.&CYCLE(+1),
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(CYL,(5,2),RLSE),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920)
//INCPARM  DD DSN=&HLQ..PARMLIB(INCPARM),DISP=SHR
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//         PEND
