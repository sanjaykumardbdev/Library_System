--------------------------------------------------------------------------------
-- File Name   : 04_indexes_constraints.sql
-- Purpose     : Indexes and constraints for performance optimization
-- Author      : Oracle 19c Architect
-- Notes       : OLTP + analytics optimized indexing strategy
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. MEMBERS INDEXES
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX idx_members_type ON members(member_type)';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX idx_members_status ON members(status)';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

--------------------------------------------------------------------------------
-- 2. BOOKS INDEXES
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX idx_books_category ON books(category)';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX idx_books_author ON books(author_id)';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

--------------------------------------------------------------------------------
-- 3. BOOK COPIES INDEXES (REAL-TIME AVAILABILITY)
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX idx_copies_book_status ON book_copies(book_id, status)';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX idx_copies_branch ON book_copies(branch_id)';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

--------------------------------------------------------------------------------
-- 4. LOAN TRANSACTIONS INDEXES (PARTITIONED TABLE)
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX idx_loan_member ON loan_transactions(member_id)';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX idx_loan_status ON loan_transactions(status)';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

-- Composite index for analytics + overdue tracking
BEGIN
    EXECUTE IMMEDIATE '
    CREATE INDEX idx_loan_member_date 
    ON loan_transactions(member_id, loan_date)';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

--------------------------------------------------------------------------------
-- 5. SEAT BOOKINGS INDEXES (HIGH CONCURRENCY AREA)
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX idx_seat_booking_member ON seat_bookings(member_id)';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX idx_seat_booking_date ON seat_bookings(booking_date)';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

-- Critical index for seat availability check (performance critical)
BEGIN
    EXECUTE IMMEDIATE '
    CREATE INDEX idx_seat_branch_time 
    ON seat_bookings(branch_id, start_time, end_time, status)';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

--------------------------------------------------------------------------------
-- 6. FOREIGN KEY CONSTRAINTS (SAFE ADDITION)
--------------------------------------------------------------------------------

-- BOOKS → AUTHORS
BEGIN
    EXECUTE IMMEDIATE '
    ALTER TABLE books 
    ADD CONSTRAINT fk_books_authors 
    FOREIGN KEY (author_id) REFERENCES authors(author_id)';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -2275 AND SQLCODE != -02275 THEN
        NULL; -- already exists or dependency issue
    END IF;
END;
/

-- BOOKS → PUBLISHERS
BEGIN
    EXECUTE IMMEDIATE '
    ALTER TABLE books 
    ADD CONSTRAINT fk_books_publishers 
    FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id)';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -2275 AND SQLCODE != -02275 THEN
        NULL;
    END IF;
END;
/

--------------------------------------------------------------------------------
-- TRACK SCRIPT EXECUTION
--------------------------------------------------------------------------------
BEGIN
    log_script_execution(
        p_script_name => '04_indexes_constraints.sql',
        p_status      => 'SUCCESS',
        p_remarks     => 'Indexes and constraints created successfully'
    );
END;
/
