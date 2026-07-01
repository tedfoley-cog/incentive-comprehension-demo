      *================================================================*
      * ERRCODES - INCENTIVE ELIGIBILITY REASON CODES                 *
      *                                                                *
      * SHARED LITERAL CONSTANTS FOR ELIGIBILITY / REJECTION REASONS. *
      * USED BY INCVAL, INCELIG, INCEXC AND WRITTEN TO PAY-REASON.    *
      * THESE MUST STAY IN SYNC WITH SP_ELIGIBILITY (DB2) RETURN VALS.*
      *================================================================*
       01  INCENTIVE-REASON-CODES.
           05  RC-OK                  PIC X(04) VALUE 'OK  '.
           05  RC-DEALER-NOT-FOUND    PIC X(04) VALUE 'DLRN'.
           05  RC-DEALER-NOT-ENROLL   PIC X(04) VALUE 'DLRE'.
           05  RC-DEALER-INACTIVE     PIC X(04) VALUE 'DLRI'.
           05  RC-PROGRAM-NOT-FOUND   PIC X(04) VALUE 'PRGN'.
           05  RC-PROGRAM-WINDOW      PIC X(04) VALUE 'PRGW'.
           05  RC-REGION-INELIGIBLE   PIC X(04) VALUE 'RGNX'.
           05  RC-LOYALTY-NOT-QUAL    PIC X(04) VALUE 'LOYX'.
           05  RC-DUPLICATE-CLAIM     PIC X(04) VALUE 'DUP '.
           05  RC-EDIT-REJECT         PIC X(04) VALUE 'EDIT'.
