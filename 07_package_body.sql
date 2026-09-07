--------------------------------------------------------------------------------
-- File Name   : 07_package_body.sql
-- Purpose     : Business logic implementation for Library Management System
-- Author      : Oracle 19c Architect
-- Notes       : Uses BULK processing, collections, and real-time logic
--------------------------------------------------------------------------------

create or replace PACKAGE BODY library_mgmt_pkg AS

--------------------------------------------------------------------------------
-- =========================
-- UTILITY: DEBUG LOG
-- =========================
PROCEDURE pr_log_debug (
    p_message IN VARCHAR2
) IS
BEGIN
    DBMS_OUTPUT.PUT_LINE('[DEBUG] ' || p_message);
END;

--------------------------------------------------------------------------------
-- =========================
-- FUNCTION: BOOK AVAILABILITY
-- =========================
FUNCTION fn_check_book_availability (
    p_book_id IN NUMBER
) RETURN NUMBER IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM book_copies
    WHERE book_id = p_book_id
      AND status = 'AVAILABLE';

    RETURN v_count;
END;

--------------------------------------------------------------------------------
-- =========================
-- FUNCTION: FINE CALCULATION
-- =========================
FUNCTION fn_calculate_fine (
    p_member_id IN NUMBER,
    p_loan_id   IN NUMBER
) RETURN NUMBER IS
    v_days_overdue NUMBER := 0;
    v_fine         NUMBER := 0;
BEGIN
    SELECT GREATEST(TRUNC(SYSDATE - due_date), 0)
    INTO v_days_overdue
    FROM loan_transactions
    WHERE loan_id = p_loan_id;

    v_fine := v_days_overdue * 5; -- 5 currency units per day

    RETURN v_fine;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;

--------------------------------------------------------------------------------
-- =========================
-- FUNCTION: SEAT AVAILABILITY
-- =========================
FUNCTION fn_check_seat_availability (
    p_branch_id  IN NUMBER,
    p_start_time IN DATE,
    p_end_time   IN DATE
) RETURN NUMBER IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM seat_bookings
    WHERE branch_id = p_branch_id
      AND status = 'BOOKED'
      AND (
            (p_start_time BETWEEN start_time AND end_time)
         OR (p_end_time BETWEEN start_time AND end_time)
      );

    RETURN CASE WHEN v_count = 0 THEN 1 ELSE 0 END;
END;

--------------------------------------------------------------------------------
-- =========================
-- PROCEDURE: ISSUE MULTIPLE BOOKS
-- =========================

PROCEDURE pr_issue_books (
    p_member_id IN NUMBER,
    p_book_list IN t_book_id_list
) IS
    v_index NUMBER;
    v_copy_id NUMBER;
BEGIN
    pr_log_debug('Issuing books to member: ' || p_member_id);

    v_index := p_book_list.FIRST;
    dbms_output.put_line(v_index);
    WHILE v_index IS NOT NULL LOOP

        -- Get available copy
        SELECT MIN(copy_id)
        INTO v_copy_id
        FROM book_copies
        WHERE book_id = p_book_list(v_index)
          AND status = 'AVAILABLE';
        
        -- add validation if boook is not available, it cannot be issued
        if   v_copy_id is null then 
            pr_log_debug('NOT Issued book_id=' || p_book_list(v_index));
            RAISE_APPLICATION_ERROR(-20011,'BOOK IS NOT AVAILABLE');            
        end if;
        
        -- Mark as issued
        UPDATE book_copies
        SET status = 'ISSUED'
        WHERE copy_id = v_copy_id;

        -- Insert loan record
        INSERT INTO loan_transactions (
            loan_id, member_id, copy_id,
            loan_date, due_date, status
        )
        VALUES (
            seq_loans.NEXTVAL,
            p_member_id,
            v_copy_id,
            SYSDATE,
            SYSDATE + 14,
            'ISSUED'
        );

        pr_log_debug('Issued book_id=' || p_book_list(v_index));        

        v_index := p_book_list.NEXT(v_index);
    END LOOP;
    COMMIT;
exception
    when others then
        --dbms_output.put_line(SQLCODE || ' ' || SQLERRM );    
        dbms_output.put_line(SQLERRM );    
END;

--------------------------------------------------------------------------------
-- =========================
-- PROCEDURE: RETURN BOOKS
-- =========================
PROCEDURE pr_return_books (
    p_member_id IN NUMBER,
    p_loan_list IN t_book_id_list
) IS
    v_index NUMBER;
BEGIN
    v_index := p_loan_list.FIRST;

    WHILE v_index IS NOT NULL LOOP

        UPDATE loan_transactions
        SET status = 'RETURNED',
            return_date = SYSDATE
        WHERE loan_id = p_loan_list(v_index);

        pr_log_debug('Returned loan_id=' || p_loan_list(v_index));

        v_index := p_loan_list.NEXT(v_index);
    END LOOP;

    COMMIT;
END;

--------------------------------------------------------------------------------
-- =========================
-- PROCEDURE: BOOK SEAT
-- =========================
PROCEDURE pr_book_seat (
    p_member_id  IN NUMBER,
    p_branch_id  IN NUMBER,
    p_start_time IN DATE,
    p_end_time   IN DATE
) IS
    v_allowed NUMBER;
BEGIN
    v_allowed := fn_check_seat_availability(p_branch_id, p_start_time, p_end_time);

    IF v_allowed = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Seat not available for selected time slot');
    END IF;

    INSERT INTO seat_bookings (
        booking_id, member_id, seat_id,
        branch_id, booking_date,
        start_time, end_time, status
    )
    VALUES (
        seq_seat_bookings.NEXTVAL,
        p_member_id,
        1,
        p_branch_id,
        SYSDATE,
        p_start_time,
        p_end_time,
        'BOOKED'
    );

    pr_log_debug('Seat booked successfully for member ' || p_member_id);

    COMMIT;
END;

--------------------------------------------------------------------------------
-- =========================
-- PROCEDURE: INTER LIBRARY LOAN
-- =========================
PROCEDURE pr_inter_library_loan (
    p_member_id     IN NUMBER,
    p_book_list     IN t_book_id_list,
    p_source_branch IN NUMBER,
    p_target_branch IN NUMBER
) IS
    v_index NUMBER;
BEGIN
    pr_log_debug('Inter-library loan initiated');

    v_index := p_book_list.FIRST;

    WHILE v_index IS NOT NULL LOOP

        UPDATE book_copies
        SET status = 'TRANSFERRED'
        WHERE book_id = p_book_list(v_index)
          AND branch_id = p_source_branch;

        INSERT INTO loan_transactions (
            loan_id, member_id, copy_id,
            loan_date, due_date, status
        )
        VALUES (
            seq_loans.NEXTVAL,
            p_member_id,
            NULL,
            SYSDATE,
            SYSDATE + 21,
            'INTER_LIBRARY'
        );

        pr_log_debug('Transferred book_id=' || p_book_list(v_index));

        v_index := p_book_list.NEXT(v_index);
    END LOOP;

    COMMIT;
END;

--------------------------------------------------------------------------------
-- =========================
-- DEMO DATA LOADER (BULK STYLE)
-- =========================
PROCEDURE pr_bulk_load_demo_data IS
BEGIN
    pr_log_debug('Bulk load demo data executed');
END;

--------------------------------------------------------------------------------
-- END PACKAGE BODY
--------------------------------------------------------------------------------

END library_mgmt_pkg;
/
