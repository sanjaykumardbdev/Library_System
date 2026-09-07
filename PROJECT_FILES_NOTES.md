# Library System — Project Files Notes

Short descriptions and usage notes for each file in this project.

- `00_create_schema_and_tablespace_for_library.sql`: Creates dedicated tablespaces and the `library_etl` schema/user, directory objects and grants. Run once when provisioning the DB server; contains prompts for next steps.

- `00_run_all_library_system.sql`: Master driver script that runs all deployment scripts in order. Use this to deploy the entire system end-to-end.

- `01_tracker_table.sql`: Creates `script_execution_tracker` to record script runs (idempotency). Required for logging and safe re-runs.

- `02_master_tables.sql`: Core master tables (`members`, `authors`, `publishers`, `books`, `library_branches`, `book_copies`, `seating_master`, `seat_capacity`) with comments. Run before dependent objects.

- `03_partition_tables.sql`: Partitioned OLTP tables `loan_transactions` and `seat_bookings` (range partitioning by date). Important for scalability and for indexes/constraints that follow.

- `04_indexes_constraints.sql`: Creates indexes and adds foreign key constraints for performance and referential integrity. Run after master and partition tables exist.

- `05_sequences.sql`: Sequences used to generate primary keys (members, authors, books, loans, seats, etc.). Should be created before data loads or code that references `NEXTVAL`.

- `06_package_spec.sql`: Package specification `library_mgmt_pkg` (types, function and procedure signatures). Public API; compile before the package body.

- `07_package_body.sql`: Implementation of `library_mgmt_pkg` (issue/return books, seat booking, inter-library loans, utilities). Depends on tables, sequences, and package spec.

- `08_materialized_views.sql`: Materialized views for reporting (`mv_monthly_borrow_summary`, `mv_seat_utilization_summary`, `mv_member_activity`) and a refresh procedure. Used by analytics/BI.

- `09_views_analytics.sql`: Analytical views using window functions (member ranking, loan trends, seat utilization trends). Read-only views for dashboards.

- `10_sample_data.sql`: Idempotent sample data loader (authors, publishers, branches, members, books, book_copies, seating). Useful for testing and demos.

- `11_demo_execution.sql`: Demo script that executes package operations end-to-end (issue/return, seat booking, inter-library loan), refreshes MVs and prints analytics output.

- `data reconciliation.sql`: PL/SQL block to reconcile `book_copies` with `books.total_copies` (adds or removes copies). Useful for post-load repairs.

- `Library.sql`: An alternative (MySQL-style) schema example for a school library — not used by the Oracle scripts. Keep for reference or porting.

- `log_script_execution.sql`: `log_script_execution` procedure used by scripts to record status into `script_execution_tracker`. Must exist for tracking.

- `trg_book_copies_audit.sql`: Creates `book_copy_audit` table and `trg_book_copies_audit` trigger to audit INSERT/UPDATE/DELETE on `book_copies`.


Run / Deployment notes
- Typical deployment order: `00_create_schema_and_tablespace_for_library.sql` → `01_tracker_table.sql` → `02_master_tables.sql` → `03_partition_tables.sql` → `04_indexes_constraints.sql` → `05_sequences.sql` → `06_package_spec.sql` → `07_package_body.sql` → `08_materialized_views.sql` → `09_views_analytics.sql` → `10_sample_data.sql` → `11_demo_execution.sql`.
- Use `00_run_all_library_system.sql` to execute the whole sequence in one go.
- `Library.sql` is a separate MySQL-oriented example and should not be mixed with the Oracle deployment unless porting.

Maintenance tips
- Keep `script_execution_tracker` and `log_script_execution` in place to allow idempotent re-runs.
- Run `data reconciliation.sql` after bulk imports if `books.total_copies` and `book_copies` drift.
- Rebuild or refresh materialized views via `refresh_library_mviews` after large data loads.

Contact / Authors
- Original author comments are embedded in each file header. Review those headers for authorship and intended environment assumptions (Oracle 19c paths are present in some files).
