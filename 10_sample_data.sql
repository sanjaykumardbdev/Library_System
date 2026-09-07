--------------------------------------------------------------------------------
-- File Name   : 10_sample_data.sql
-- Purpose     : Load realistic sample data for testing system
-- Author      : Oracle 19c Architect
-- Notes       : Uses bulk inserts + collections + idempotent logic
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. AUTHORS SAMPLE DATA
--------------------------------------------------------------------------------
BEGIN
    FOR i IN 1..10 LOOP
        BEGIN
            INSERT INTO authors VALUES (
                seq_authors.NEXTVAL,
                'Author ' || i,
                'Country ' || i
            );
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN NULL;
        END;
    END LOOP;
END;
/

--------------------------------------------------------------------------------
-- 2. PUBLISHERS SAMPLE DATA
--------------------------------------------------------------------------------
BEGIN
    FOR i IN 1..5 LOOP
        BEGIN
            INSERT INTO publishers VALUES (
                seq_publishers.NEXTVAL,
                'Publisher ' || i,
                'City ' || i
            );
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN NULL;
        END;
    END LOOP;
END;
/

--------------------------------------------------------------------------------
-- 3. LIBRARY BRANCHES
--------------------------------------------------------------------------------
BEGIN
    FOR i IN 1..3 LOOP
        BEGIN
            INSERT INTO library_branches VALUES (
                seq_branches.NEXTVAL,
                'Branch ' || i,
                'Location ' || i,
                100 * i
            );
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN NULL;
        END;
    END LOOP;
END;
/

--------------------------------------------------------------------------------
-- 4. MEMBERS SAMPLE DATA (20 MEMBERS)
--------------------------------------------------------------------------------
BEGIN
    FOR i IN 1..20 LOOP
        BEGIN
            INSERT INTO members VALUES (
                seq_members.NEXTVAL,
                'Member ' || i,
                CASE WHEN MOD(i,2)=0 THEN 'STUDENT' ELSE 'PROFESSIONAL' END,
                'member' || i || '@mail.com',
                '99999' || i,
                SYSDATE,
                'ACTIVE'
            );
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN NULL;
        END;
    END LOOP;
END;
/

--------------------------------------------------------------------------------
-- 5. BOOKS SAMPLE DATA (50 BOOKS)
--------------------------------------------------------------------------------
BEGIN
    FOR i IN 1..50 LOOP
        BEGIN
            INSERT INTO books VALUES (
                seq_books.NEXTVAL,
                'Book Title ' || i,
                CASE 
                    WHEN MOD(i,5)=0 THEN 'TECH'
                    WHEN MOD(i,5)=1 THEN 'SCIENCE'
                    WHEN MOD(i,5)=2 THEN 'FICTION'
                    WHEN MOD(i,5)=3 THEN 'MATH'
                    ELSE 'HISTORY'
                END,
                (SELECT author_id
                 FROM (
                     SELECT author_id,
                            ROW_NUMBER() OVER (ORDER BY DBMS_RANDOM.VALUE) rn
                     FROM AUTHORS
                 )
                 WHERE rn = 1),
                (SELECT publisher_id
                 FROM (
                     SELECT publisher_id,
                            ROW_NUMBER() OVER (ORDER BY DBMS_RANDOM.VALUE) rn
                     FROM PUBLISHERS
                 )
                 WHERE rn = 1),
                'ISBN-' || i,
                2000 + MOD(i,25),
                5
            );
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN NULL;
        END;
    END LOOP;
END;
/

--------------------------------------------------------------------------------
-- 6. BOOK COPIES (INVENTORY GENERATION USING COLLECTION LOGIC)
--------------------------------------------------------------------------------
DECLARE
    TYPE t_num_tab IS TABLE OF NUMBER;
    v_books t_num_tab := t_num_tab();
BEGIN
    SELECT book_id BULK COLLECT INTO v_books FROM books;

    FOR i IN 1..v_books.COUNT LOOP
        FOR j IN 1..3 LOOP
            BEGIN
                INSERT INTO book_copies VALUES (
                    seq_book_copies.NEXTVAL,
                    (SELECT book_id FROM (SELECT book_id,ROW_NUMBER() OVER (ORDER BY DBMS_RANDOM.VALUE) rn FROM books ) WHERE rn = 1),
                    (SELECT BRANCH_ID FROM (SELECT BRANCH_ID,ROW_NUMBER() OVER (ORDER BY DBMS_RANDOM.VALUE) rn FROM LIBRARY_BRANCHES ) WHERE rn = 1),                    
                    'AVAILABLE'
                );
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN NULL;
            END;
        END LOOP;
    END LOOP;
END;
/

-- Based on number of copies available in book table, same number of copies should be availle in book_copies;
-- Check file : daa reconciliation.sql

--------------------------------------------------------------------------------
-- 7. SEATING DATA (SEATS PER BRANCH)
--------------------------------------------------------------------------------
BEGIN
    FOR b IN 1..3 LOOP
        FOR s IN 1..30 LOOP
            BEGIN
                INSERT INTO seating_master VALUES (
                    seq_seats.NEXTVAL,
                    (SELECT branch_id FROM (SELECT branch_id,ROW_NUMBER() OVER (ORDER BY DBMS_RANDOM.VALUE) rn FROM LIBRARY_BRANCHES ) WHERE rn = 1),
                    'S-' || b || '-' || s,
                    CASE WHEN s <= 10 THEN 'ZONE-A'
                         WHEN s <= 20 THEN 'ZONE-B'
                         ELSE 'ZONE-C'
                    END
                );
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN NULL;
            END;
        END LOOP;
    END LOOP;
END;
/


--------------------------------------------------------------------------------
-- 8. SEAT CAPACITY DATA
--------------------------------------------------------------------------------
BEGIN
    FOR i IN 1..3 LOOP
        BEGIN
            INSERT INTO seat_capacity VALUES (
                i,
                30,
                0
            );
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN NULL;
        END;
    END LOOP;
END;
/

--------------------------------------------------------------------------------
-- TRACK SCRIPT EXECUTION
--------------------------------------------------------------------------------
BEGIN
    log_script_execution(
        p_script_name => '10_sample_data.sql',
        p_status      => 'SUCCESS',
        p_remarks     => 'Sample dataset loaded successfully'
    );
END;
/