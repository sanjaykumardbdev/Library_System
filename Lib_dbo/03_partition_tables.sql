--------------------------------------------------------------------------------
-- File Name   : 03_partition_tables.sql
-- Purpose     : Partitioned OLTP tables for Loans and Seat Bookings
-- Author      : Oracle 19c Architect
-- Notes       : RANGE partitioning for time-based scalability
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. LOAN TRANSACTIONS (PARTITIONED TABLE)
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE TABLE loan_transactions (
        loan_id        NUMBER,
        member_id      NUMBER,
        copy_id        NUMBER,
        loan_date      DATE,
        due_date       DATE,
        return_date    DATE,
        status         VARCHAR2(20),  -- ISSUED / RETURNED / OVERDUE
        CONSTRAINT pk_loan PRIMARY KEY (loan_id, loan_date)
    )
    PARTITION BY RANGE (loan_date)
    (
        PARTITION p_loan_2024 VALUES LESS THAN (DATE ''2025-01-01''),
        PARTITION p_loan_2025 VALUES LESS THAN (DATE ''2026-01-01''),
        PARTITION p_loan_future VALUES LESS THAN (MAXVALUE)
    )';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN
            RAISE;
        END IF;
END;
/

COMMENT ON TABLE loan_transactions IS 'Partitioned table for book borrowing transactions';

--------------------------------------------------------------------------------
-- 2. SEAT BOOKINGS (PARTITIONED TABLE)
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE TABLE seat_bookings (
        booking_id     NUMBER,
        member_id      NUMBER references members(member_id),
        seat_id        NUMBER references seating_master(seat_id),
        branch_id      NUMBER references library_branches(branch_id) ,
        booking_date   DATE,
        start_time     DATE,
        end_time       DATE,
        status         VARCHAR2(20), -- BOOKED / CANCELLED / COMPLETED
        CONSTRAINT pk_seat_booking PRIMARY KEY (booking_id, booking_date)
    )
    PARTITION BY RANGE (booking_date)
    (
        PARTITION p_seat_2024 VALUES LESS THAN (DATE ''2025-01-01''),
        PARTITION p_seat_2025 VALUES LESS THAN (DATE ''2026-01-01''),
        PARTITION p_seat_future VALUES LESS THAN (MAXVALUE)
    )';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN
            RAISE;
        END IF;
END;
/

COMMENT ON TABLE seat_bookings IS 'Partitioned table for seat reservation system';

--------------------------------------------------------------------------------
-- TRACK SCRIPT EXECUTION
--------------------------------------------------------------------------------
BEGIN
    log_script_execution(
        p_script_name => '03_partition_tables.sql',
        p_status      => 'SUCCESS',
        p_remarks     => 'Partitioned tables created successfully'
    );
END;
/
