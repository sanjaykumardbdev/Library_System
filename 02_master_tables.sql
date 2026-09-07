--------------------------------------------------------------------------------
-- File Name   : 02_master_tables.sql
-- Purpose     : Core master tables for Library Management System
-- Author      : Oracle 19c Architect
-- Notes       : Idempotent + production-grade OLTP design
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. MEMBERS TABLE
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE TABLE members (
        member_id        NUMBER PRIMARY KEY,
        full_name        VARCHAR2(200) NOT NULL,
        member_type      VARCHAR2(30), -- STUDENT / PROFESSIONAL
        email            VARCHAR2(200) UNIQUE,
        phone            VARCHAR2(20),
        join_date        DATE DEFAULT SYSDATE,
        status           VARCHAR2(20) DEFAULT ''ACTIVE''
    )';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

COMMENT ON TABLE members IS 'Stores library members including students and professionals';

--------------------------------------------------------------------------------
-- 2. AUTHORS TABLE
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE TABLE authors (
        author_id     NUMBER PRIMARY KEY,
        author_name   VARCHAR2(200) NOT NULL,
        country       VARCHAR2(100)
    )';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

COMMENT ON TABLE authors IS 'Stores book authors';

--------------------------------------------------------------------------------
-- 3. PUBLISHERS TABLE
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE TABLE publishers (
        publisher_id   NUMBER PRIMARY KEY,
        name           VARCHAR2(200) NOT NULL,
        location       VARCHAR2(200)
    )';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

COMMENT ON TABLE publishers IS 'Stores book publishers';

--------------------------------------------------------------------------------
-- 4. BOOKS TABLE
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE TABLE books (
        book_id        NUMBER PRIMARY KEY,
        title          VARCHAR2(300) NOT NULL,
        category       VARCHAR2(100),
        author_id      NUMBER REFERENCES authors(author_id),
        publisher_id   NUMBER REFERENCES publishers(publisher_id),
        isbn           VARCHAR2(50),
        publish_year   NUMBER,
        total_copies   NUMBER DEFAULT 1
    )';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

COMMENT ON TABLE books IS 'Master book catalog';

--------------------------------------------------------------------------------
-- 5. LIBRARY BRANCHES
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE TABLE library_branches (
        branch_id     NUMBER PRIMARY KEY,
        branch_name   VARCHAR2(200),
        location      VARCHAR2(200),
        capacity      NUMBER
    )';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

COMMENT ON TABLE library_branches IS 'Library branch master data';

--------------------------------------------------------------------------------
-- 6. BOOK COPIES (REAL-TIME INVENTORY CONTROL)
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE TABLE book_copies (
        copy_id       NUMBER PRIMARY KEY,
        book_id       NUMBER REFERENCES books(book_id),
        branch_id     NUMBER REFERENCES library_branches(branch_id),
        status        VARCHAR2(20) DEFAULT ''AVAILABLE'' 
                      -- AVAILABLE / ISSUED / LOST
    )';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

COMMENT ON TABLE book_copies IS 'Tracks physical copies of books per branch';

--------------------------------------------------------------------------------
-- 7. SEATING MASTER
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE TABLE seating_master (
        seat_id       NUMBER PRIMARY KEY,
        branch_id     NUMBER REFERENCES library_branches(branch_id),
        seat_number   VARCHAR2(20),
        zone          VARCHAR2(50)
    )';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

COMMENT ON TABLE seating_master IS 'Defines physical seating layout in library';

--------------------------------------------------------------------------------
-- 8. SEAT CAPACITY CONTROL TABLE
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE TABLE seat_capacity (
        branch_id      NUMBER PRIMARY KEY,
        total_seats    NUMBER,
        reserved_seats NUMBER DEFAULT 0
    )';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

COMMENT ON TABLE seat_capacity IS 'Controls total seating capacity per branch';

--------------------------------------------------------------------------------
-- TRACK SCRIPT EXECUTION
--------------------------------------------------------------------------------
BEGIN
    log_script_execution(
        p_script_name => '02_master_tables.sql',
        p_status      => 'SUCCESS',
        p_remarks     => 'Master tables created successfully'
    );
END;
/