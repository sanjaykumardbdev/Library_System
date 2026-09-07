--------------------------------------------------------------------------------
-- File Name   : 09_views_analytics.sql
-- Purpose     : Analytical views using Oracle window functions
-- Author      : Oracle 19c Architect
-- Notes       : Supports BI dashboards and reporting layer
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. MEMBER BORROWING RANKING
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE OR REPLACE VIEW vw_member_borrow_rank AS
    SELECT
        m.member_id,
        m.full_name,
        COUNT(l.loan_id) AS total_loans,

        RANK() OVER (ORDER BY COUNT(l.loan_id) DESC) AS borrow_rank,
        DENSE_RANK() OVER (ORDER BY COUNT(l.loan_id) DESC) AS dense_borrow_rank

    FROM members m
    LEFT JOIN loan_transactions l
        ON m.member_id = l.member_id
    GROUP BY m.member_id, m.full_name
    ';
END;
/

-- COMMENT ON VIEW vw_member_borrow_rank 
-- IS 'Ranks members based on borrowing frequency using window functions';

--------------------------------------------------------------------------------
-- 2. LOAN TREND ANALYSIS (LAG / LEAD)
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE OR REPLACE VIEW vw_loan_trend AS
    SELECT
        loan_id,
        member_id,
        loan_date,
        due_date,

        LAG(loan_date) OVER (PARTITION BY member_id ORDER BY loan_date) AS prev_loan_date,
        LEAD(loan_date) OVER (PARTITION BY member_id ORDER BY loan_date) AS next_loan_date,

        (loan_date - LAG(loan_date) OVER (PARTITION BY member_id ORDER BY loan_date)) 
            AS days_between_loans

    FROM loan_transactions
    ';
END;
/

-- COMMENT ON VIEW vw_loan_trend 
-- IS 'Analyzes borrowing patterns using LAG and LEAD functions';

--------------------------------------------------------------------------------
-- 3. SEAT UTILIZATION TREND ANALYSIS
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE OR REPLACE VIEW vw_seat_utilization_trend AS
    SELECT
        branch_id,
        booking_date,

        COUNT(*) OVER (PARTITION BY branch_id ORDER BY booking_date) 
            AS running_bookings,

        SUM(COUNT(*)) OVER (PARTITION BY branch_id) 
            AS total_branch_bookings

    FROM seat_bookings
    GROUP BY branch_id, booking_date
    ';
END;
/

-- COMMENT ON VIEW vw_seat_utilization_trend 
-- IS 'Tracks seat booking trends using window aggregates';

--------------------------------------------------------------------------------
-- 4. DAILY LOAN VOLUME TREND
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE OR REPLACE VIEW vw_daily_loan_trend AS
    SELECT
        TRUNC(loan_date) AS loan_day,

        COUNT(*) AS daily_loans,

        SUM(COUNT(*)) OVER (ORDER BY TRUNC(loan_date)) 
            AS cumulative_loans

    FROM loan_transactions
    GROUP BY TRUNC(loan_date)
    ';
END;
/

-- COMMENT ON VIEW vw_daily_loan_trend 
-- IS 'Shows daily and cumulative borrowing trends';

--------------------------------------------------------------------------------
-- TRACK SCRIPT EXECUTION
--------------------------------------------------------------------------------
BEGIN
    log_script_execution(
        p_script_name => '09_views_analytics.sql',
        p_status      => 'SUCCESS',
        p_remarks     => 'Analytical views created successfully'
    );
END;
/
