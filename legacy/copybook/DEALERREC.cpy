      *================================================================*
      * DEALERREC - DEALER MASTER RECORD (80 BYTES)                    *
      *                                                                *
      * ONE RECORD PER ENROLLED DEALER. READ BY INCMAIN INTO AN        *
      * IN-CORE TABLE; PASSED TO INCVAL FOR DEALER-LEVEL ELIGIBILITY.  *
      *================================================================*
       01  DEALER-REC.
           05  DLR-DEALER-ID          PIC X(06).
           05  DLR-NAME               PIC X(30).
           05  DLR-REGION             PIC X(04).
           05  DLR-ENROLLED           PIC X(01).
               88  DLR-IS-ENROLLED        VALUE 'Y'.
           05  DLR-STATUS             PIC X(01).
               88  DLR-IS-ACTIVE          VALUE 'A'.
               88  DLR-IS-INACTIVE        VALUE 'I'.
           05  FILLER                 PIC X(38).
