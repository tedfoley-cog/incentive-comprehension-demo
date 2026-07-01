-----------------------------------------------------------------------
-- SP_ELIGIBILITY - DB2 SQL PL ELIGIBILITY CHECK (ONLINE PATH)
--
-- Called by the online claim-entry application (Struts/Spring) to give
-- dealers immediate feedback before a claim is ever written. It returns
-- the SAME reason codes as the batch eligibility engine.
--
-- *** DELIBERATE DUPLICATION ***
-- The date-window and region rules below are a second, independent copy
-- of the logic in COBOL programs INCELIG.cbl (1000-CHECK-WINDOW,
-- 2000-CHECK-REGION) and the reason codes in copybook ERRCODES.cpy.
-- Over the years the two have drifted: this procedure treats the window
-- as INCLUSIVE of END_DATE (<=) exactly like COBOL, but the loyalty
-- rule (3000-CHECK-LOYALTY in COBOL) is MISSING here. Reconciling online
-- vs batch eligibility is one of the comprehension findings the demo
-- surfaces.
-----------------------------------------------------------------------

CREATE PROCEDURE SP_ELIGIBILITY
    ( IN  IN_CLAIM_ID   CHAR(10)
    , OUT OUT_REASON    CHAR(4)
    , OUT OUT_ELIGIBLE  CHAR(1) )
    LANGUAGE SQL
    READS SQL DATA
P1: BEGIN
    DECLARE V_SALE_DATE   DATE;
    DECLARE V_DEALER_ID   CHAR(6);
    DECLARE V_PROGRAM_ID  CHAR(6);
    DECLARE V_DLR_REGION  CHAR(4);
    DECLARE V_DLR_ENROLL  CHAR(1);
    DECLARE V_DLR_STATUS  CHAR(1);
    DECLARE V_PRG_START   DATE;
    DECLARE V_PRG_END     DATE;
    DECLARE V_PRG_REGION  CHAR(4);

    SET OUT_REASON   = 'OK  ';
    SET OUT_ELIGIBLE = 'Y';

    -- join the claim to its dealer and program
    SELECT C.SALE_DATE, C.DEALER_ID, C.PROGRAM_ID,
           D.REGION, D.ENROLLED, D.STATUS,
           P.START_DATE, P.END_DATE, P.REGION
      INTO V_SALE_DATE, V_DEALER_ID, V_PROGRAM_ID,
           V_DLR_REGION, V_DLR_ENROLL, V_DLR_STATUS,
           V_PRG_START, V_PRG_END, V_PRG_REGION
      FROM CLAIM C
      JOIN DEALER  D ON D.DEALER_ID  = C.DEALER_ID
      JOIN PROGRAM P ON P.PROGRAM_ID = C.PROGRAM_ID
     WHERE C.CLAIM_ID = IN_CLAIM_ID;

    -- dealer-level checks (mirror INCVAL)
    IF V_DLR_ENROLL <> 'Y' THEN
        SET OUT_REASON = 'DLRE'; SET OUT_ELIGIBLE = 'N';
        RETURN;
    END IF;
    IF V_DLR_STATUS = 'I' THEN
        SET OUT_REASON = 'DLRI'; SET OUT_ELIGIBLE = 'N';
        RETURN;
    END IF;

    -- program window (mirror INCELIG 1000-CHECK-WINDOW, inclusive)
    IF V_SALE_DATE < V_PRG_START OR V_SALE_DATE > V_PRG_END THEN
        SET OUT_REASON = 'PRGW'; SET OUT_ELIGIBLE = 'N';
        RETURN;
    END IF;

    -- program region (mirror INCELIG 2000-CHECK-REGION)
    IF V_PRG_REGION <> 'ALL ' AND V_PRG_REGION <> V_DLR_REGION THEN
        SET OUT_REASON = 'RGNX'; SET OUT_ELIGIBLE = 'N';
        RETURN;
    END IF;

    -- NOTE: loyalty / prior-ownership check (INCELIG 3000-CHECK-LOYALTY)
    -- is intentionally absent here - online and batch have drifted.
END P1
