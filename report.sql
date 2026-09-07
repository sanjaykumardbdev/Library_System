-- report.sql
-- Purpose: Generate a schema report for the current schema/user.
-- Usage: Run as the schema owner in SQL*Plus or SQL Developer.

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 200

PROMPT ================================================================
PROMPT LIBRARY_SYSTEM SCHEMA REPORT
PROMPT Generated on: "" || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') || ""
PROMPT ================================================================

-- SECTION 1: List of objects in the schema
PROMPT
PROMPT --- Objects (tables, views, mviews, packages, procs, seqs, triggers)
SELECT object_type, object_name, created
FROM user_objects
WHERE object_type IN ('TABLE','VIEW','MATERIALIZED VIEW','PACKAGE','PROCEDURE','FUNCTION','SEQUENCE','TRIGGER')
ORDER BY object_type, object_name;

-- SECTION 2: Row counts for each table (idempotent-safe)
PROMPT
PROMPT --- Table row counts
DECLARE
  CURSOR c_tables IS SELECT table_name FROM user_tables ORDER BY table_name;
  v_sql  VARCHAR2(4000);
  v_cnt  NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('TABLE_NAME | ROW_COUNT');
  FOR r IN c_tables LOOP
    v_sql := 'BEGIN EXECUTE IMMEDIATE ''SELECT COUNT(*) FROM "' || r.table_name || '"'' INTO :1; END;';
    BEGIN
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM "' || r.table_name || '"' INTO v_cnt;
    EXCEPTION WHEN OTHERS THEN
      v_cnt := -1; -- indicates error (e.g., insufficient privileges)
    END;
    DBMS_OUTPUT.PUT_LINE(RPAD(r.table_name,40) || ' | ' || TO_CHAR(v_cnt));
  END LOOP;
END;
/

-- SECTION 3: Dependencies (objects referencing or referenced by schema objects)
PROMPT
PROMPT --- Object dependencies (from USER_DEPENDENCIES)
COLUMN name FORMAT A30
COLUMN type FORMAT A15
COLUMN referenced_owner FORMAT A15
COLUMN referenced_name FORMAT A30
COLUMN referenced_type FORMAT A15
SELECT name, type, referenced_owner, referenced_name, referenced_type
FROM user_dependencies
ORDER BY name, referenced_type, referenced_name;

-- SECTION 4: Table columns summary
PROMPT
PROMPT --- Table columns (name, data type, length, nullable)
SELECT table_name, column_name, data_type, data_length, nullable
FROM user_tab_columns
ORDER BY table_name, column_id;

-- SECTION 5: Object counts summary
PROMPT
PROMPT --- Summary: object counts by type
SELECT object_type, COUNT(*) AS object_count
FROM user_objects
WHERE object_type IN ('TABLE','VIEW','MATERIALIZED VIEW','PACKAGE','PROCEDURE','FUNCTION','SEQUENCE','TRIGGER')
GROUP BY object_type
ORDER BY object_type;

-- SECTION 6: Sequences and last_number (where available)
PROMPT
PROMPT --- Sequences
SELECT sequence_name, min_value, max_value, increment_by, cache_size, cycle_flag
FROM user_sequences
ORDER BY sequence_name;

-- SECTION 7: Top tables by approximate size (uses stats if available; fallback to COUNT)
PROMPT
PROMPT --- Top tables by row count (approximate ordering)
DECLARE
  TYPE t_rec IS RECORD (table_name VARCHAR2(200), row_cnt NUMBER);
  TYPE t_tab IS TABLE OF t_rec INDEX BY PLS_INTEGER;
  v_tab t_tab;
  idx PLS_INTEGER := 0;
  v_cnt NUMBER;
BEGIN
  FOR r IN (SELECT table_name FROM user_tables) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM "' || r.table_name || '"' INTO v_cnt;
    EXCEPTION WHEN OTHERS THEN
      v_cnt := -1;
    END;
    idx := idx + 1;
    v_tab(idx).table_name := r.table_name;
    v_tab(idx).row_cnt := v_cnt;
  END LOOP;

  -- Simple selection of top N (naive selection sort for small schemas)
  FOR i IN 1 .. LEAST(20, idx) LOOP
    -- find max among i..idx
    DECLARE
      max_i PLS_INTEGER := i;
    BEGIN
      FOR j IN i+1 .. idx LOOP
        IF v_tab(j).row_cnt > v_tab(max_i).row_cnt THEN
          max_i := j;
        END IF;
      END LOOP;
      -- swap
      IF max_i != i THEN
        DECLARE tmp t_rec := v_tab(i); BEGIN v_tab(i) := v_tab(max_i); v_tab(max_i) := tmp; END;
      END IF;
      DBMS_OUTPUT.PUT_LINE(RPAD(v_tab(i).table_name,40) || ' | ' || TO_CHAR(v_tab(i).row_cnt));
    END;
  END LOOP;
END;
/

PROMPT ================================================================
PROMPT End of report
PROMPT ================================================================
