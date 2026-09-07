--------------------------------------------------------------------------------
-- Table: BOOK_COPY_AUDIT
-- Purpose: Stores automatic audit logs from triggers
--------------------------------------------------------------------------------

BEGIN
    EXECUTE IMMEDIATE '
    CREATE TABLE book_copy_audit (
        audit_id        NUMBER GENERATED ALWAYS AS IDENTITY,
        book_id         NUMBER,
        copy_id         NUMBER,
        action_type     VARCHAR2(10),   -- INSERT / UPDATE / DELETE

        old_status      VARCHAR2(20),
        new_status      VARCHAR2(20),

        old_branch_id   NUMBER,
        new_branch_id   NUMBER,

        changed_by      VARCHAR2(100),
        change_date     DATE DEFAULT SYSDATE,

        remarks         VARCHAR2(4000)
    )';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN RAISE;
        END IF;
END;
/



--------------------------------------------------------------------------------
-- Trigger: TRG_BOOK_COPIES_AUDIT
-- Purpose : Automatically logs INSERT / UPDATE / DELETE operations
--------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER trg_book_copies_audit
AFTER INSERT OR UPDATE OR DELETE ON book_copies
FOR EACH ROW
BEGIN

    -------------------------------------------------------------------------
    -- INSERT ACTION
    -------------------------------------------------------------------------
    IF INSERTING THEN

        INSERT INTO book_copy_audit (
            book_id,
            copy_id,
            action_type,
            old_status,
            new_status,
            old_branch_id,
            new_branch_id,
            changed_by,
            remarks
        )
        VALUES (
            :NEW.book_id,
            :NEW.copy_id,
            'INSERT',
            NULL,
            :NEW.status,
            NULL,
            :NEW.branch_id,
            NVL(USER, 'UNKNOWN_USER'),
            'Automatic audit on INSERT'
        );

    -------------------------------------------------------------------------
    -- UPDATE ACTION
    -------------------------------------------------------------------------
    ELSIF UPDATING THEN

        INSERT INTO book_copy_audit (
            book_id,
            copy_id,
            action_type,
            old_status,
            new_status,
            old_branch_id,
            new_branch_id,
            changed_by,
            remarks
        )
        VALUES (
            :OLD.book_id,
            :OLD.copy_id,
            'UPDATE',
            :OLD.status,
            :NEW.status,
            :OLD.branch_id,
            :NEW.branch_id,
            NVL(USER, 'UNKNOWN_USER'),
            'Automatic audit on UPDATE'
        );

    -------------------------------------------------------------------------
    -- DELETE ACTION
    -------------------------------------------------------------------------
    ELSIF DELETING THEN

        INSERT INTO book_copy_audit (
            book_id,
            copy_id,
            action_type,
            old_status,
            new_status,
            old_branch_id,
            new_branch_id,
            changed_by,
            remarks
        )
        VALUES (
            :OLD.book_id,
            :OLD.copy_id,
            'DELETE',
            :OLD.status,
            NULL,
            :OLD.branch_id,
            NULL,
            NVL(USER, 'UNKNOWN_USER'),
            'Automatic audit on DELETE'
        );

    END IF;

END;
/