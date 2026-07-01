-----------------------------------------------------------------------
-- SCHEMA.sql - DB2 for z/OS DDL FOR THE INCENTIVE PLATFORM
--
-- The batch (INCMAIN) processes flat files, but the system of record is
-- DB2: the online Struts/Spring application reads and writes these tables,
-- and the nightly batch is fed from unloads of CLAIM/DEALER/PROGRAM. The
-- COBOL copybooks (CLAIMREC, DEALERREC, PROGREC, PAYOUTREC) mirror these
-- table layouts field-for-field; DCLGEN output is in db2/DCLCLAIM.cpy.
-----------------------------------------------------------------------

CREATE TABLE DEALER (
    DEALER_ID    CHAR(6)       NOT NULL,
    DEALER_NAME  VARCHAR(30)   NOT NULL,
    REGION       CHAR(4)       NOT NULL,
    ENROLLED     CHAR(1)       NOT NULL WITH DEFAULT 'N',
    STATUS       CHAR(1)       NOT NULL WITH DEFAULT 'A',
    PRIMARY KEY (DEALER_ID)
) IN INCENTDB.DEALERTS;

CREATE TABLE PROGRAM (
    PROGRAM_ID   CHAR(6)       NOT NULL,
    DESCR        VARCHAR(30)   NOT NULL,
    PRG_TYPE     CHAR(4)       NOT NULL,           -- FLAT | PCT
    FLAT_AMOUNT  DECIMAL(9,2)  NOT NULL WITH DEFAULT 0,
    PCT_RATE     DECIMAL(5,2)  NOT NULL WITH DEFAULT 0,
    START_DATE   DATE          NOT NULL,
    END_DATE     DATE          NOT NULL,
    PAYEE        CHAR(1)       NOT NULL,           -- D | C
    REGION       CHAR(4)       NOT NULL WITH DEFAULT 'ALL',
    STACKABLE    CHAR(1)       NOT NULL WITH DEFAULT 'N',
    REQ_PRIOR_OWN CHAR(1)      NOT NULL WITH DEFAULT 'N',
    MAX_INCENTIVE DECIMAL(9,2) NOT NULL WITH DEFAULT 0,
    PRIMARY KEY (PROGRAM_ID)
) IN INCENTDB.PROGRMTS;

CREATE TABLE CLAIM (
    CLAIM_ID     CHAR(10)      NOT NULL,
    VIN          CHAR(17)      NOT NULL,
    DEALER_ID    CHAR(6)       NOT NULL,
    PROGRAM_ID   CHAR(6)       NOT NULL,
    SALE_DATE    DATE          NOT NULL,
    SALE_PRICE   DECIMAL(9,2)  NOT NULL,
    CLAIM_TYPE   CHAR(8)       NOT NULL,
    PRIOR_OWN    CHAR(1)       NOT NULL WITH DEFAULT 'N',
    CUST_BANK    CHAR(1)       NOT NULL WITH DEFAULT 'N',
    PRIMARY KEY (CLAIM_ID)
) IN INCENTDB.CLAIMTS;

CREATE TABLE PAYOUT (
    CLAIM_ID     CHAR(10)      NOT NULL,
    VIN          CHAR(17)      NOT NULL,
    DEALER_ID    CHAR(6)       NOT NULL,
    PROGRAM_ID   CHAR(6)       NOT NULL,
    STATUS       CHAR(4)       NOT NULL,           -- PAID|HOLD|RVSD|REJ
    METHOD       CHAR(6),
    PAYEE_TYPE   CHAR(1),
    REASON       CHAR(4),
    AMOUNT       DECIMAL(9,2)  NOT NULL WITH DEFAULT 0,
    RUN_TS       TIMESTAMP     NOT NULL WITH DEFAULT CURRENT TIMESTAMP
) IN INCENTDB.PAYOUTTS;

-- Tunable parameters. NOTE: these rows duplicate copybook INCCONST and
-- the //INCPARM control card. Comprehension must reconcile all three.
CREATE TABLE PARM (
    PARM_KEY     CHAR(4)       NOT NULL,
    PARM_VALUE   DECIMAL(9,2)  NOT NULL,
    PRIMARY KEY (PARM_KEY)
) IN INCENTDB.PARMTS;

INSERT INTO PARM (PARM_KEY, PARM_VALUE) VALUES ('GCAP', 10000.00);
INSERT INTO PARM (PARM_KEY, PARM_VALUE) VALUES ('LBON',   500.00);
