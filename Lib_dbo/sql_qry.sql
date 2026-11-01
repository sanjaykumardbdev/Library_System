SELECT sequence_name
FROM all_sequences
WHERE sequence_owner = 'LIBRARY_ETL';


select * from authors;

delete from authors where author_id <= 100;


SELECT GREATEST(TRUNC(SYSDATE - due_date), 0)
    INTO v_days_overdue
    FROM loan_transactions
    WHERE loan_id = p_loan_id;