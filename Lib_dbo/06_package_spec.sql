--------------------------------------------------------------------------------
-- File Name   : 06_package_spec.sql
-- Purpose     : Public API specification for Library Management System
-- Author      : Oracle 19c Architect
-- Notes       : Defines business service contract (no implementation here)
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE library_mgmt_pkg AS

--------------------------------------------------------------------------------
-- =========================
-- COLLECTION TYPES
-- =========================
--------------------------------------------------------------------------------

-- List of book IDs for bulk issue/return
TYPE t_book_id_list IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

-- List of member book request (bulk operations)
TYPE t_member_book_map IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

-- Seat booking time slots
TYPE t_time_slot IS RECORD (
    start_time DATE,
    end_time   DATE
);

-- Array of time slots (seat scheduling)
TYPE t_time_slot_list IS TABLE OF t_time_slot INDEX BY PLS_INTEGER;

--------------------------------------------------------------------------------
-- =========================
-- FUNCTIONS
-- =========================

-- Check availability of a book copy
FUNCTION fn_check_book_availability (
    p_book_id IN NUMBER
) RETURN NUMBER;

-- Calculate fine based on overdue days
FUNCTION fn_calculate_fine (
    p_member_id IN NUMBER,
    p_loan_id   IN NUMBER
) RETURN NUMBER;

-- Check seat availability for a branch and time slot
FUNCTION fn_check_seat_availability (
    p_branch_id  IN NUMBER,
    p_start_time IN DATE,
    p_end_time   IN DATE
) RETURN NUMBER;

--------------------------------------------------------------------------------
-- =========================
-- PROCEDURES (BUSINESS OPERATIONS)
-- =========================

-- Issue multiple books to a member using collection
PROCEDURE pr_issue_books (
    p_member_id IN NUMBER,
    p_book_list IN t_book_id_list
);

-- Return multiple books
PROCEDURE pr_return_books (
    p_member_id IN NUMBER,
    p_loan_list IN t_book_id_list
);

-- Book a seat with time slot
PROCEDURE pr_book_seat (
    p_member_id  IN NUMBER,
    p_branch_id  IN NUMBER,
    p_start_time IN DATE,
    p_end_time   IN DATE
);

-- Inter-library loan request (external branch borrowing)
PROCEDURE pr_inter_library_loan (
    p_member_id       IN NUMBER,
    p_book_list       IN t_book_id_list,
    p_source_branch   IN NUMBER,
    p_target_branch   IN NUMBER
);

--------------------------------------------------------------------------------
-- =========================
-- UTILITY PROCEDURES
-- =========================

-- Log system debug messages
PROCEDURE pr_log_debug (
    p_message IN VARCHAR2
);

-- Bulk load sample data using collections
PROCEDURE pr_bulk_load_demo_data;

--------------------------------------------------------------------------------
-- END PACKAGE SPECIFICATION
--------------------------------------------------------------------------------

END library_mgmt_pkg;
/
