--------------------------------------------------------------------------------
-- File Name   : 05_sequences.sql
-- Purpose     : Primary key generation using Oracle Sequences
-- Author      : Oracle 19c Architect
-- Notes       : Supports bulk operations + collections + concurrency
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. MEMBERS SEQUENCE
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE SEQUENCE seq_members
    START WITH 1000
    INCREMENT BY 1
    NOCACHE
    NOCYCLE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

--------------------------------------------------------------------------------
-- 2. AUTHORS SEQUENCE
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE SEQUENCE seq_authors
    START WITH 100
    INCREMENT BY 1
    NOCACHE
    NOCYCLE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

--------------------------------------------------------------------------------
-- 3. PUBLISHERS SEQUENCE
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE SEQUENCE seq_publishers
    START WITH 100
    INCREMENT BY 1
    NOCACHE
    NOCYCLE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

--------------------------------------------------------------------------------
-- 4. BOOKS SEQUENCE
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE SEQUENCE seq_books
    START WITH 10000
    INCREMENT BY 1
    NOCACHE
    NOCYCLE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

--------------------------------------------------------------------------------
-- 5. BOOK COPIES SEQUENCE
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE SEQUENCE seq_book_copies
    START WITH 50000
    INCREMENT BY 1
    NOCACHE
    NOCYCLE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

--------------------------------------------------------------------------------
-- 6. LIBRARY BRANCHES SEQUENCE
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE SEQUENCE seq_branches
    START WITH 10
    INCREMENT BY 1
    NOCACHE
    NOCYCLE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

--------------------------------------------------------------------------------
-- 7. LOAN TRANSACTIONS SEQUENCE
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE SEQUENCE seq_loans
    START WITH 100000
    INCREMENT BY 1
    NOCACHE
    NOCYCLE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

--------------------------------------------------------------------------------
-- 8. SEAT BOOKINGS SEQUENCE
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE SEQUENCE seq_seat_bookings
    START WITH 200000
    INCREMENT BY 1
    NOCACHE
    NOCYCLE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

--------------------------------------------------------------------------------
-- 9. SEATING MASTER SEQUENCE
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE SEQUENCE seq_seats
    START WITH 1000
    INCREMENT BY 1
    NOCACHE
    NOCYCLE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

--------------------------------------------------------------------------------
-- TRACK SCRIPT EXECUTION
--------------------------------------------------------------------------------
BEGIN
    log_script_execution(
        p_script_name => '05_sequences.sql',
        p_status      => 'SUCCESS',
        p_remarks     => 'All sequences created successfully'
    );
END;
/