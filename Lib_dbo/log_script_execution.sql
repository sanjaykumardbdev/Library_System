--------------------------------------------------------------------------------
-- Procedure: LOG_SCRIPT_EXECUTION
-- Purpose   : Standard logging utility for all deployment scripts
--------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE log_script_execution (
    p_script_name IN VARCHAR2,
    p_status      IN VARCHAR2,
    p_remarks     IN VARCHAR2 DEFAULT NULL
)
AS
BEGIN
    MERGE INTO script_execution_tracker t
    USING (SELECT p_script_name AS script_name FROM dual) s
    ON (t.script_name = s.script_name)
    WHEN MATCHED THEN
        UPDATE SET 
            execution_date = SYSDATE,
            status = p_status,
            remarks = p_remarks
    WHEN NOT MATCHED THEN
        INSERT (script_name, execution_date, status, remarks)
        VALUES (p_script_name, SYSDATE, p_status, p_remarks);

    DBMS_OUTPUT.PUT_LINE('LOGGED: ' || p_script_name);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR in logging script: ' || SQLERRM);
END;
/