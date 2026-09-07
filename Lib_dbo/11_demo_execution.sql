--------------------------------------------------------------------------------
-- File Name   : 11_demo_execution.sql
-- Purpose     : End-to-end system demo and validation
-- Author      : Oracle 19c Architect
-- Notes       : Simulates real business operations
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON;

DECLARE
    v_books library_mgmt_pkg.t_book_id_list;
BEGIN
    DBMS_OUTPUT.PUT_LINE('==============================');
    DBMS_OUTPUT.PUT_LINE('LIBRARY SYSTEM DEMO START');
    DBMS_OUTPUT.PUT_LINE('==============================');

    --------------------------------------------------------------------------------
    -- 1. ISSUE MULTIPLE BOOKS
    --------------------------------------------------------------------------------
    v_books(1) := 1;
    v_books(2) := 2;
    v_books(3) := 3;

    DBMS_OUTPUT.PUT_LINE('Issuing multiple books to Member 1...');
    library_mgmt_pkg.pr_issue_books(1, v_books);

    --------------------------------------------------------------------------------
    -- 2. RETURN BOOKS
    --------------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('Returning books for Member 1...');
    library_mgmt_pkg.pr_return_books(1, v_books);

    --------------------------------------------------------------------------------
    -- 3. BOOK SEAT
    --------------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('Booking seat for Member 2...');

    library_mgmt_pkg.pr_book_seat(
        p_member_id  => 2,
        p_branch_id  => 1,
        p_start_time => SYSDATE,
        p_end_time   => SYSDATE + (1/24)
    );

    --------------------------------------------------------------------------------
    -- 4. INTER LIBRARY LOAN
    --------------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('Processing inter-library loan...');

    library_mgmt_pkg.pr_inter_library_loan(
        p_member_id     => 3,
        p_book_list     => v_books,
        p_source_branch => 1,
        p_target_branch => 2
    );

    --------------------------------------------------------------------------------
    -- 5. ANALYTICAL VIEW TESTS
    --------------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('==============================');
    DBMS_OUTPUT.PUT_LINE('ANALYTICS OUTPUT');
    DBMS_OUTPUT.PUT_LINE('==============================');

    FOR rec IN (
        SELECT * FROM vw_member_borrow_rank WHERE ROWNUM <= 5
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Member: ' || rec.member_id ||
            ' Name: ' || rec.full_name ||
            ' Loans: ' || rec.total_loans ||
            ' Rank: ' || rec.borrow_rank
        );
    END LOOP;

    --------------------------------------------------------------------------------
    -- 6. DAILY LOAN TREND
    --------------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('==============================');
    DBMS_OUTPUT.PUT_LINE('DAILY LOAN TREND');
    DBMS_OUTPUT.PUT_LINE('==============================');

    FOR rec IN (
        SELECT * FROM vw_daily_loan_trend
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Day: ' || rec.loan_day ||
            ' Daily: ' || rec.daily_loans ||
            ' Cumulative: ' || rec.cumulative_loans
        );
    END LOOP;

    --------------------------------------------------------------------------------
    -- 7. MATERIALIZED VIEW CHECK
    --------------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('Refreshing Materialized Views...');

    refresh_library_mviews;

    DBMS_OUTPUT.PUT_LINE('MV Refresh Completed Successfully');

    --------------------------------------------------------------------------------
    -- END DEMO
    --------------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('==============================');
    DBMS_OUTPUT.PUT_LINE('LIBRARY SYSTEM DEMO COMPLETE');
    DBMS_OUTPUT.PUT_LINE('==============================');

END;
/
