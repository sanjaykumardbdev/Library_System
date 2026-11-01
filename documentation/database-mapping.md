# Database Mapping

This document maps Oracle tables to Java entities, repositories, services and REST APIs.

| Oracle Table     | Java Entity   | Repository             | Service             | REST API             | UI          |
| ---------------- | ------------- | ---------------------- | ------------------- | -------------------- | ----------- |
| MEMBERS          | Member profile projection | MemberRepository | MemberService / AuthService | `/api/members`, `/api/auth/register` | Members / Register |
| APP_USERS        | AppUser       | UserRepository         | AuthService         | `/api/auth/*`        | Sign in / Register |
| APP_USER_ROLES   | Role collection | UserRepository       | AuthService         | `/api/auth/me`       | Role-aware navigation |
| AUTHORS          | Author        | AuthorRepository       | AuthorService       | `/api/authors`       | Authors     |
| PUBLISHERS       | Publisher     | PublisherRepository    | PublisherService    | `/api/publishers`    | Publishers  |
| BOOKS            | Book          | BookRepository         | BookService         | `/api/books`         | Books       |
| LIBRARY_BRANCHES | LibraryBranch | BranchRepository       | BranchService       | `/api/branches`      | Branches    |
| BOOK_COPIES      | BookCopy      | BookCopyRepository     | BookCopyService     | `/api/book-copies`   | Book Copies |
| LOAN_TRANSACTIONS | JDBC projection | LoanRepository       | LoanService         | `/api/me/loans`, `/api/admin/loans` | My loans / Circulation |
| SEATING_MASTER   | Seating       | SeatingRepository      | SeatingService      | `/api/seats`         | Seating     |
| SEAT_CAPACITY    | SeatCapacity  | SeatCapacityRepository | SeatCapacityService | `/api/seat-capacity` | Capacity    |

Notes:
- The Oracle schema is authoritative. Entities use `@Table(name = "...")` with exact table names.
- Primary keys are mapped to `@Id` fields. Sequences (if required) will be referenced but not created by the application.
- `ddl-auto` is set to `validate` to prevent accidental schema changes.
- `LOAN_TRANSACTIONS` has the composite key `(LOAN_ID, LOAN_DATE)`; circulation uses JDBC and does not model this table with a lossy single-column JPA key.
- `APP_USERS` stores password hashes and an optional member link; role values are restricted to `MEMBER` and `ADMIN` in `APP_USER_ROLES`. Signup always creates `MEMBER`; admins are provisioned by an operator.
- Loan issue/return runs transactionally against both `LOAN_TRANSACTIONS` and `BOOK_COPIES`. The existing PL/SQL package procedures are not called by these endpoints.
- Catalog creation uses `SEQ_BOOKS` and provisions `SEQ_BOOK_COPIES` records. Inventory reductions remove only AVAILABLE copies and fail if the requested reduction would remove an issued or unavailable copy.
