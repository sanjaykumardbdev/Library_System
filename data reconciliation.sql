/*
write another anonymous block to correct the number of copies in book_copies table where records are alredy inserted as per total number of copies mentioned in books


Got it — this is a classic data reconciliation / repair script you’d actually see in production when inventory drift happens.

We’ll build an anonymous PL/SQL block that:

Compares books.total_copies vs actual rows in book_copies
Inserts missing copies
Deletes excess copies (safe cleanup mode)
*/

--------------------------------------------------------------------------------
-- Purpose : Reconcile book_copies with books.total_copies
-- Scenario: Fix missing or excess inventory records safely
-- Author  : Oracle 19c Architect
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON;

DECLARE
    CURSOR c_books IS
        SELECT book_id, total_copies
        FROM books;

    v_actual_count NUMBER;
    v_diff         NUMBER;

BEGIN
    DBMS_OUTPUT.PUT_LINE('STARTING BOOK COPY RECONCILIATION...');

    FOR r IN c_books LOOP

        ---------------------------------------------------------------------
        -- Step 1: Get actual copies in system
        ---------------------------------------------------------------------
        SELECT COUNT(*)
        INTO v_actual_count
        FROM book_copies
        WHERE book_id = r.book_id;

        v_diff := r.total_copies - v_actual_count;

        DBMS_OUTPUT.PUT_LINE(
            'BOOK_ID=' || r.book_id ||
            ' EXPECTED=' || r.total_copies ||
            ' ACTUAL=' || v_actual_count ||
            ' DIFF=' || v_diff
        );

        ---------------------------------------------------------------------
        -- Step 2: If copies are LESS → INSERT missing copies
        ---------------------------------------------------------------------
        IF v_diff > 0 THEN

            FOR i IN 1 .. v_diff LOOP
                INSERT INTO book_copies (
                    copy_id,
                    book_id,
                    branch_id,
                    status
                )
                VALUES (
                    seq_book_copies.NEXTVAL,
                    r.book_id,
                    (SELECT BRANCH_ID FROM (SELECT BRANCH_ID,ROW_NUMBER() OVER (ORDER BY DBMS_RANDOM.VALUE) rn FROM LIBRARY_BRANCHES ) WHERE rn = 1),                    
                    'AVAILABLE'
                );
            END LOOP;

            DBMS_OUTPUT.PUT_LINE('ADDED ' || v_diff || ' COPIES');

        ---------------------------------------------------------------------
        -- Step 3: If copies are MORE → DELETE excess copies
        ---------------------------------------------------------------------
        ELSIF v_diff < 0 THEN

            FOR rec IN (
                SELECT copy_id
                FROM book_copies
                WHERE book_id = r.book_id
                  AND ROWNUM <= ABS(v_diff)
            ) LOOP

                DELETE FROM book_copies
                WHERE copy_id = rec.copy_id;

            END LOOP;

            DBMS_OUTPUT.PUT_LINE('REMOVED ' || ABS(v_diff) || ' COPIES');

        ELSE
            DBMS_OUTPUT.PUT_LINE('NO ACTION REQUIRED');
        END IF;

    END LOOP;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('RECONCILIATION COMPLETED SUCCESSFULLY');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR DURING RECONCILIATION: ' || SQLERRM);
END;
/



-- output:

STARTING BOOK COPY RECONCILIATION...
BOOK_ID=10003 EXPECTED=5 ACTUAL=1 DIFF=4
ADDED 4 COPIES
BOOK_ID=10004 EXPECTED=5 ACTUAL=1 DIFF=4
ADDED 4 COPIES
BOOK_ID=10005 EXPECTED=5 ACTUAL=4 DIFF=1
ADDED 1 COPIES
BOOK_ID=10006 EXPECTED=5 ACTUAL=1 DIFF=4
ADDED 4 COPIES
BOOK_ID=10007 EXPECTED=5 ACTUAL=1 DIFF=4
ADDED 4 COPIES
BOOK_ID=10008 EXPECTED=5 ACTUAL=4 DIFF=1
ADDED 1 COPIES
BOOK_ID=10009 EXPECTED=5 ACTUAL=2 DIFF=3
ADDED 3 COPIES
BOOK_ID=10010 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10011 EXPECTED=5 ACTUAL=0 DIFF=5
ADDED 5 COPIES
BOOK_ID=10012 EXPECTED=5 ACTUAL=5 DIFF=0
NO ACTION REQUIRED
BOOK_ID=10013 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10014 EXPECTED=5 ACTUAL=4 DIFF=1
ADDED 1 COPIES
BOOK_ID=10015 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10016 EXPECTED=5 ACTUAL=1 DIFF=4
ADDED 4 COPIES
BOOK_ID=10017 EXPECTED=5 ACTUAL=7 DIFF=-2
REMOVED 2 COPIES
BOOK_ID=10018 EXPECTED=5 ACTUAL=6 DIFF=-1
REMOVED 1 COPIES
BOOK_ID=10019 EXPECTED=5 ACTUAL=4 DIFF=1
ADDED 1 COPIES
BOOK_ID=10020 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10021 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10022 EXPECTED=5 ACTUAL=2 DIFF=3
ADDED 3 COPIES
BOOK_ID=10023 EXPECTED=5 ACTUAL=4 DIFF=1
ADDED 1 COPIES
BOOK_ID=10024 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10025 EXPECTED=5 ACTUAL=4 DIFF=1
ADDED 1 COPIES
BOOK_ID=10026 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10027 EXPECTED=5 ACTUAL=4 DIFF=1
ADDED 1 COPIES
BOOK_ID=10028 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10029 EXPECTED=5 ACTUAL=2 DIFF=3
ADDED 3 COPIES
BOOK_ID=10030 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10031 EXPECTED=5 ACTUAL=5 DIFF=0
NO ACTION REQUIRED
BOOK_ID=10032 EXPECTED=5 ACTUAL=5 DIFF=0
NO ACTION REQUIRED
BOOK_ID=10033 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10034 EXPECTED=5 ACTUAL=1 DIFF=4
ADDED 4 COPIES
BOOK_ID=10035 EXPECTED=5 ACTUAL=1 DIFF=4
ADDED 4 COPIES
BOOK_ID=10036 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10037 EXPECTED=5 ACTUAL=5 DIFF=0
NO ACTION REQUIRED
BOOK_ID=10038 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10039 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10040 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10041 EXPECTED=5 ACTUAL=2 DIFF=3
ADDED 3 COPIES
BOOK_ID=10042 EXPECTED=5 ACTUAL=4 DIFF=1
ADDED 1 COPIES
BOOK_ID=10043 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10044 EXPECTED=5 ACTUAL=4 DIFF=1
ADDED 1 COPIES
BOOK_ID=10045 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10046 EXPECTED=5 ACTUAL=4 DIFF=1
ADDED 1 COPIES
BOOK_ID=10047 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10048 EXPECTED=5 ACTUAL=2 DIFF=3
ADDED 3 COPIES
BOOK_ID=10049 EXPECTED=5 ACTUAL=2 DIFF=3
ADDED 3 COPIES
BOOK_ID=10050 EXPECTED=5 ACTUAL=3 DIFF=2
ADDED 2 COPIES
BOOK_ID=10051 EXPECTED=5 ACTUAL=2 DIFF=3
ADDED 3 COPIES
BOOK_ID=10052 EXPECTED=5 ACTUAL=2 DIFF=3
ADDED 3 COPIES
RECONCILIATION COMPLETED SUCCESSFULLY


PL/SQL procedure successfully completed.



