--------------------------------------------------------------------------------
-- File Name   : 01_tracker_table.sql
-- Purpose     : Maintain execution history of deployment scripts
-- Author      : Oracle 19c Architect
-- Notes       : This table ensures IDEMPOTENT deployment
--------------------------------------------------------------------------------

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM all_tables
    WHERE table_name = 'SCRIPT_EXECUTION_TRACKER';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE '
        CREATE TABLE script_execution_tracker (
            script_name        VARCHAR2(200) PRIMARY KEY,
            execution_date     DATE DEFAULT SYSDATE,
            status             VARCHAR2(30),
            remarks            VARCHAR2(4000)
        )';
        
        DBMS_OUTPUT.PUT_LINE('SCRIPT_EXECUTION_TRACKER created successfully');
    ELSE
        DBMS_OUTPUT.PUT_LINE('SCRIPT_EXECUTION_TRACKER already exists');
    END IF;
END;
/ 