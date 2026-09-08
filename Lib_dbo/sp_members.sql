--------------------------------------------------------------------------------
-- File Name   : sp_members.sql
-- Purpose     : Return members via SYS_REFCURSOR with optional filters
-- Author      : Generated
-- Notes       : Uses a ref cursor output parameter
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_get_members(
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
          AND (p_name IS NULL OR LOWER(full_name) LIKE '%'||LOWER(p_name)||'%')
          AND (p_member_type IS NULL OR member_type = p_member_type);
END sp_get_members;
/

COMMENT ON PROCEDURE sp_get_members IS 'Returns members as a SYS_REFCURSOR with optional filters (member_id, name, member_type)';
