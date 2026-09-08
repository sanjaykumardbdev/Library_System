--------------------------------------------------------------------------------
-- File Name   : sp_get_member.sql
-- Purpose     : Return one or many members via SYS_REFCURSOR with optional filters
-- Notes       : This mirrors the UI input flow for memberId, name and member_type
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_get_member(
    p_member_id    IN  NUMBER DEFAULT NULL,
    p_name         IN  VARCHAR2 DEFAULT NULL,
    p_member_type  IN  VARCHAR2 DEFAULT NULL,
    o_cursor       OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN o_cursor FOR
        SELECT member_id,
               full_name,
               member_type,
               email,
               phone,
               join_date,
               status
        FROM members
        WHERE (p_member_id IS NULL OR member_id = p_member_id)
          AND (p_name IS NULL OR LOWER(full_name) LIKE '%' || LOWER(p_name) || '%')
          AND (p_member_type IS NULL OR member_type = p_member_type);
END sp_get_member;
/

COMMENT ON PROCEDURE sp_get_member IS 'Returns member records as a SYS_REFCURSOR using optional member_id, name and member_type filters';
