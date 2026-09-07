ALTER SESSION SET CONTAINER = ORCLPDB;
-- =============================================
-- 00_create_schema_and_tablespace.sql
-- Create Dedicated Tablespace + Schema (User) for Population ETL Project
-- =============================================

-- =============================================
-- STEP 1: Create Dedicated Tablespace
-- =============================================
CREATE TABLESPACE library_etl_sys
DATAFILE 'D:/Oracle_19c/oradata/ORCL/library_etl_sys_01.dbf'
SIZE 500M 
AUTOEXTEND ON 
NEXT 100M 
MAXSIZE UNLIMITED
EXTENT MANAGEMENT LOCAL 
SEGMENT SPACE MANAGEMENT AUTO;

-- Optional: Create additional datafile if needed later
-- ALTER TABLESPACE library_etl_sys ADD DATAFILE '/u01/app/oracle/oradata/ORCL/library_etl_sys_02.dbf' SIZE 300M AUTOEXTEND ON;

-- Create Index Tablespace (Recommended best practice)
CREATE TABLESPACE library_etl_idx_ts
DATAFILE 'D:/Oracle_19c/oradata/ORCL/library_etl_idx_ts_01.dbf' 
SIZE 300M 
AUTOEXTEND ON 
NEXT 50M 
MAXSIZE UNLIMITED
EXTENT MANAGEMENT LOCAL 
SEGMENT SPACE MANAGEMENT AUTO;

-- =============================================
-- STEP 2: Create New Schema (User)
-- =============================================
CREATE USER library_etl IDENTIFIED BY "library_etl"
DEFAULT TABLESPACE library_etl_sys
TEMPORARY TABLESPACE temp
QUOTA UNLIMITED ON library_etl_sys
QUOTA UNLIMITED ON library_etl_idx_ts;

-- =============================================
-- STEP 3: Grant Necessary Privileges
-- =============================================
GRANT CONNECT, RESOURCE TO library_etl;
GRANT CREATE SESSION TO library_etl;
GRANT CREATE TABLE, CREATE VIEW, CREATE SEQUENCE, CREATE SYNONYM TO library_etl;

GRANT CREATE PROCEDURE TO library_etl;
--GRANT CREATE FUNCTION TO library_etl;
--GRANT CREATE PACKAGE TO library_etl;


GRANT CREATE MATERIALIZED VIEW TO library_etl;
GRANT CREATE TRIGGER TO library_etl;

-- Grants for DBMS_SCHEDULER and advanced features
--GRANT EXECUTE ON DBMS_SCHEDULER TO library_etl;
--GRANT EXECUTE ON DBMS_LOCK TO library_etl;
--GRANT SELECT ON DBA_SCHEDULER_JOBS TO library_etl;
--GRANT SELECT ON DBA_SCHEDULER_JOB_RUN_DETAILS TO library_etl;

-- For SQL*Loader and external table access (if needed)
GRANT CREATE ANY DIRECTORY TO library_etl;
GRANT UNLIMITED TABLESPACE TO library_etl;   -- Optional, but useful during development

-- =============================================
-- STEP 4: Create Directory Objects (for SQL*Loader / External Tables)
-- =============================================
CREATE OR REPLACE DIRECTORY library_etl_DATA_DIR AS 'D:/Oracle_19c/oradata/ORCL/data_files';
CREATE OR REPLACE DIRECTORY library_etl_LOG_DIR  AS 'D:/Oracle_19c/oradata/ORCL/log_files';

GRANT READ, WRITE ON DIRECTORY library_etl_DATA_DIR TO library_etl;
GRANT READ, WRITE ON DIRECTORY library_etl_LOG_DIR  TO library_etl;

-- =============================================
-- STEP 5: Connect as new schema and set context
-- =============================================
-- Run the rest of the scripts while connected as library_etl user

PROMPT
PROMPT =============================================
PROMPT Schema 'library_etl' created successfully!
PROMPT Default Tablespace : library_etl_sys
PROMPT Index Tablespace   : library_etl_idx_ts
PROMPT
PROMPT Next Steps:
PROMPT 1. Connect using: sqlplus library_etl/"SecurePass123#"@your_service_name
PROMPT 2. Run the following files in order:
PROMPT    - 01_data_setup.sql
PROMPT    - 01_generate_sample_data.sql
PROMPT    - 03_staging_layer.sql
PROMPT    - etc.
PROMPT =============================================
