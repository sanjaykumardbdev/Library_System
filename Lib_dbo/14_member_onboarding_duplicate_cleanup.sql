--------------------------------------------------------------------------------
-- File Name   : 14_member_onboarding_duplicate_cleanup.sql
-- Purpose     : Reconcile duplicate active loans and provision member web users
-- Requirements: Run after 12_authentication_tables.sql and 13_circulation_finance_tables.sql
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON;
SET DEFINE OFF;

--------------------------------------------------------------------------------
-- Keep the newest active issue for each member/book pair. Older active rows are
-- closed rather than deleted so loan and payment history remains auditable.
--------------------------------------------------------------------------------
DECLARE
    v_closed_count NUMBER := 0;
BEGIN
    FOR duplicate_loan IN (
        SELECT loan_rowid, loan_id, member_id, copy_id, due_date
        FROM (
            SELECT lt.ROWID AS loan_rowid,
                   lt.loan_id,
                   lt.member_id,
                   lt.copy_id,
                   lt.due_date,
                   ROW_NUMBER() OVER (
                       PARTITION BY lt.member_id, bc.book_id
                       ORDER BY lt.loan_date DESC, lt.loan_id DESC
                   ) AS loan_rank
            FROM loan_transactions lt
            JOIN book_copies bc ON bc.copy_id = lt.copy_id
            WHERE lt.status IN ('ISSUED', 'OVERDUE')
              AND lt.return_date IS NULL
        )
        WHERE loan_rank > 1
    ) LOOP
        UPDATE loan_transactions
        SET status = 'RETURNED',
            return_date = SYSDATE
        WHERE ROWID = duplicate_loan.loan_rowid;
        v_closed_count := v_closed_count + SQL%ROWCOUNT;

        UPDATE book_copies
        SET status = 'AVAILABLE'
        WHERE copy_id = duplicate_loan.copy_id
          AND status = 'ISSUED'
          AND NOT EXISTS (
              SELECT 1
              FROM loan_transactions active_loan
              WHERE active_loan.copy_id = book_copies.copy_id
                AND active_loan.return_date IS NULL
                AND active_loan.status IN ('ISSUED', 'OVERDUE')
          );

        INSERT INTO loan_charges (loan_id, member_id, charge_type, amount, created_at)
        SELECT duplicate_loan.loan_id,
               duplicate_loan.member_id,
               'LATE_FEE',
               TRUNC(SYSDATE - duplicate_loan.due_date) * 5,
               SYSDATE
        FROM dual
        WHERE duplicate_loan.due_date < TRUNC(SYSDATE)
          AND NOT EXISTS (
              SELECT 1
              FROM loan_charges charge
              WHERE charge.loan_id = duplicate_loan.loan_id
                AND charge.charge_type = 'LATE_FEE'
          );

    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Closed older duplicate active loans: ' || v_closed_count);
END;
/

--------------------------------------------------------------------------------
-- Create member accounts for active Student/Professional records with unique
-- email addresses. The sentinel is deliberately not a usable password hash:
-- login is blocked while MUST_CHANGE_PASSWORD=1. Members must use Forgot
-- password to receive a single-use email setup link and choose their own secret.
--------------------------------------------------------------------------------
INSERT INTO app_users (
    username,
    email,
    password_hash,
    member_id,
    account_status,
    password_version,
    must_change_password
)
SELECT eligible.full_name,
       eligible.email,
       '!RESET_REQUIRED!',
       eligible.member_id,
       'ACTIVE',
       0,
       1
FROM (
    SELECT m.member_id,
           m.full_name,
           LOWER(TRIM(m.email)) AS email,
           ROW_NUMBER() OVER (
               PARTITION BY LOWER(TRIM(m.email))
               ORDER BY m.member_id
           ) AS email_rank
    FROM members m
    WHERE m.status = 'ACTIVE'
      AND UPPER(m.member_type) IN ('STUDENT', 'PROFESSIONAL')
      AND m.email IS NOT NULL
      AND TRIM(m.email) IS NOT NULL
) eligible
WHERE eligible.email_rank = 1
  AND NOT EXISTS (
      SELECT 1 FROM app_users existing
      WHERE existing.member_id = eligible.member_id
         OR LOWER(TRIM(existing.email)) = eligible.email
  );

INSERT INTO app_user_roles (user_id, role)
SELECT user_record.user_id, 'MEMBER'
FROM app_users user_record
JOIN members member_record ON member_record.member_id = user_record.member_id
WHERE user_record.must_change_password = 1
  AND user_record.password_hash = '!RESET_REQUIRED!'
  AND NOT EXISTS (
      SELECT 1
      FROM app_user_roles existing_role
      WHERE existing_role.user_id = user_record.user_id
        AND existing_role.role = 'MEMBER'
  );

COMMIT;

PROMPT Member app accounts are ready. Each new member must use Forgot password to set a password before signing in.
PROMPT Resolve duplicate member emails manually; only one member per email can receive an app account.
