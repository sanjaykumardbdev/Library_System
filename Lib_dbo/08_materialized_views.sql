--------------------------------------------------------------------------------
-- File Name   : 08_materialized_views.sql
-- Purpose     : Reporting layer using Materialized Views
-- Author      : Oracle 19c Architect
-- Notes       : Supports downstream analytics and BI systems
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. MONTHLY BORROWING SUMMARY MV
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE MATERIALIZED VIEW mv_monthly_borrow_summary
    BUILD IMMEDIATE
    REFRESH COMPLETE
    AS
    SELECT 
        TRUNC(loan_date, ''MM'') AS month_start,
        member_id,
        COUNT(*) AS total_books_borrowed
    FROM loan_transactions
    GROUP BY TRUNC(loan_date, ''MM''), member_id
    ';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -12003 AND SQLCODE != -955 THEN
            RAISE;
        END IF;
END;
/

COMMENT ON MATERIALIZED VIEW mv_monthly_borrow_summary 
IS 'Monthly borrowing summary per member for analytics';

--------------------------------------------------------------------------------
-- 2. SEAT UTILIZATION SUMMARY MV
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE MATERIALIZED VIEW mv_seat_utilization_summary
    BUILD IMMEDIATE
    REFRESH COMPLETE
    AS
    SELECT 
        branch_id,
        TRUNC(booking_date, ''MM'') AS month_start,
        COUNT(*) AS total_bookings,
        SUM(CASE WHEN status = ''BOOKED'' THEN 1 ELSE 0 END) AS active_bookings
    FROM seat_bookings
    GROUP BY branch_id, TRUNC(booking_date, ''MM'')
    ';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -12003 AND SQLCODE != -955 THEN
            RAISE;
        END IF;
END;
/

COMMENT ON MATERIALIZED VIEW mv_seat_utilization_summary 
IS 'Monthly seat usage analytics per branch';

--------------------------------------------------------------------------------
-- 3. HIGH-LEVEL MEMBER ACTIVITY MV (ADVANCED ANALYTICS)
--------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE '
    CREATE MATERIALIZED VIEW mv_member_activity
    BUILD IMMEDIATE
    REFRESH COMPLETE
    AS
    SELECT 
        m.member_id,
        m.full_name,
        COUNT(l.loan_id) AS total_loans,
        MAX(l.loan_date) AS last_loan_date
    FROM members m
    LEFT JOIN loan_transactions l
        ON m.member_id = l.member_id
    GROUP BY m.member_id, m.full_name
    ';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -12003 AND SQLCODE != -955 THEN
            RAISE;
        END IF;
END;
/

COMMENT ON MATERIALIZED VIEW mv_member_activity 
IS 'Member activity analytics for reporting dashboards';

--------------------------------------------------------------------------------
-- REFRESH SUPPORT PROCEDURE (OPTIONAL FOR OPS TEAMS)
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE refresh_library_mviews AS
BEGIN
    DBMS_MVIEW.REFRESH('MV_MONTHLY_BORROW_SUMMARY', 'C');
    DBMS_MVIEW.REFRESH('MV_SEAT_UTILIZATION_SUMMARY', 'C');
    DBMS_MVIEW.REFRESH('MV_MEMBER_ACTIVITY', 'C');

    DBMS_OUTPUT.PUT_LINE('Materialized Views Refreshed Successfully');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error refreshing MVs: ' || SQLERRM);
END;
