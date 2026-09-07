# Database Mapping

This document maps Oracle tables to Java entities, repositories, services and REST APIs.

| Oracle Table     | Java Entity   | Repository             | Service             | REST API             | UI          |
| ---------------- | ------------- | ---------------------- | ------------------- | -------------------- | ----------- |
| MEMBERS          | Member        | MemberRepository       | MemberService       | `/api/members`       | Members     |
| AUTHORS          | Author        | AuthorRepository       | AuthorService       | `/api/authors`       | Authors     |
| PUBLISHERS       | Publisher     | PublisherRepository    | PublisherService    | `/api/publishers`    | Publishers  |
| BOOKS            | Book          | BookRepository         | BookService         | `/api/books`         | Books       |
| LIBRARY_BRANCHES | LibraryBranch | BranchRepository       | BranchService       | `/api/branches`      | Branches    |
| BOOK_COPIES      | BookCopy      | BookCopyRepository     | BookCopyService     | `/api/book-copies`   | Book Copies |
| SEATING_MASTER   | Seating       | SeatingRepository      | SeatingService      | `/api/seats`         | Seating     |
| SEAT_CAPACITY    | SeatCapacity  | SeatCapacityRepository | SeatCapacityService | `/api/seat-capacity` | Capacity    |

Notes:
- The Oracle schema is authoritative. Entities use `@Table(name = "...")` with exact table names.
- Primary keys are mapped to `@Id` fields. Sequences (if required) will be referenced but not created by the application.
- `ddl-auto` is set to `validate` to prevent accidental schema changes.
