-----------------------------------------------------------------------
-- SP_RATE_LOOKUP - DB2 SQL PL INCENTIVE AMOUNT CALCULATION (ONLINE)
--
-- Online counterpart of COBOL program INCCALC.cbl. Computes the gross
-- incentive for a claim using the PROGRAM row, then applies the global
-- payout cap read from the PARM table.
--
-- *** DELIBERATE DUPLICATION ***
-- The FLAT/PCT formula here re-implements INCCALC 1000-COMPUTE-BASE and
-- the cap logic re-implements 3000-APPLY-CAPS. The global cap is read
-- from PARM('GCAP') here, but from copybook INCCONST (WC-GLOBAL-PAYOUT-
-- CAP) in the batch - two sources of truth for the same number.
-----------------------------------------------------------------------

CREATE PROCEDURE SP_RATE_LOOKUP
    ( IN  IN_CLAIM_ID   CHAR(10)
    , OUT OUT_AMOUNT    DECIMAL(9,2)
    , OUT OUT_CAPPED    CHAR(1) )
    LANGUAGE SQL
    READS SQL DATA
P1: BEGIN
    DECLARE V_TYPE       CHAR(4);
    DECLARE V_FLAT       DECIMAL(9,2);
    DECLARE V_PCT        DECIMAL(5,2);
    DECLARE V_PRICE      DECIMAL(9,2);
    DECLARE V_MAX        DECIMAL(9,2);
    DECLARE V_GCAP       DECIMAL(9,2);

    SET OUT_CAPPED = 'N';

    SELECT P.PRG_TYPE, P.FLAT_AMOUNT, P.PCT_RATE,
           C.SALE_PRICE, P.MAX_INCENTIVE
      INTO V_TYPE, V_FLAT, V_PCT, V_PRICE, V_MAX
      FROM CLAIM C
      JOIN PROGRAM P ON P.PROGRAM_ID = C.PROGRAM_ID
     WHERE C.CLAIM_ID = IN_CLAIM_ID;

    IF V_TYPE = 'PCT ' THEN
        SET OUT_AMOUNT = (V_PRICE * V_PCT) / 100;
    ELSE
        SET OUT_AMOUNT = V_FLAT;
    END IF;

    -- program-level cap
    IF OUT_AMOUNT > V_MAX THEN
        SET OUT_AMOUNT = V_MAX;
        SET OUT_CAPPED = 'Y';
    END IF;

    -- global cap from PARM (duplicate of WC-GLOBAL-PAYOUT-CAP)
    SET V_GCAP = (SELECT PARM_VALUE FROM PARM WHERE PARM_KEY = 'GCAP');
    IF OUT_AMOUNT > V_GCAP THEN
        SET OUT_AMOUNT = V_GCAP;
        SET OUT_CAPPED = 'Y';
    END IF;
END P1
