# Library Backend

Spring Boot REST API for library accounts, books, members, and circulation.

## Setup

Run the Oracle scripts in `Lib_dbo/00_run_all_library_system.sql`, which installs the authentication and circulation-finance tables. Existing deployments should run `12_authentication_tables.sql` and `13_circulation_finance_tables.sql` before starting the updated backend. Hibernate uses `ddl-auto: validate`; schema changes belong in SQL scripts.

Configure the database with `DB_URL`, `DB_USERNAME`, and `DB_PASSWORD`. The default JDBC URL targets local Oracle `ORCLPDB`.

Set `JWT_SECRET_BASE64` to a Base64-encoded random secret with at least 32 bytes of decoded key material. For example, generate one with `openssl rand -base64 32`. `JWT_EXPIRATION_MS` defaults to 15 minutes. `JWT_COOKIE_SECURE` defaults to `true`; set it to `false` only for local HTTP development. Do not use a committed or predictable signing key.

Password reset links are delivered by email and expire after 60 minutes. Configure `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_FROM`, and optionally `FRONTEND_URL` before enabling password reset. Reset tokens are stored as SHA-256 hashes, single-use, and increment the password version to invalidate existing access tokens.

Public registration creates a member and a MEMBER account. The Admin selection shown during registration is informational only; it cannot grant administrator access. An existing administrator can grant the ADMIN role from User access after the account is created, or admins can be provisioned using an operator-controlled workflow after generating a BCrypt password hash:

```sql
VARIABLE admin_user_id NUMBER

INSERT INTO app_users (username, email, password_hash, member_id, account_status)
VALUES ('Library Administrator', 'admin@example.org', '<BCrypt hash>', NULL, 'ACTIVE')
RETURNING user_id INTO :admin_user_id;

INSERT INTO app_user_roles (user_id, role) VALUES (:admin_user_id, 'ADMIN');
COMMIT;
```

Authentication returns a Secure, HttpOnly, SameSite=Lax `LIBRARY_ACCESS_TOKEN` cookie. The browser must first call `GET /api/auth/csrf`; state-changing requests send the returned value in `X-XSRF-TOKEN`. The frontend handles both cookies. Authentication tokens are not returned in JSON.

## API access

- `POST /api/auth/register`, `POST /api/auth/login`, `POST /api/auth/forgot-password`, `POST /api/auth/reset-password`, and `GET /api/auth/csrf` are available without an account. Login verifies the selected ADMIN, STUDENT, or PROFESSIONAL account type against stored roles and member data. `POST /api/auth/logout` clears the cookie; `GET /api/auth/me` returns the signed-in profile and roles.
- Authenticated members can see available copy counts, borrow and return their books, and view their own loan and fine history through `/api/me/loans`.
- ADMIN accounts can issue and return books, mark a loan lost with an additional charge, record full or partial fine payments, and view all loan balances.
- ADMIN accounts can update app-user roles and status through `/api/admin/users`, and review successful sign-ins through `/api/admin/login-activity`.
- ADMIN accounts can filter `/api/members` with `status=ACTIVE` and/or `hasAppUser=true` to review active members and members with app accounts. Omit those filters to see all members.
- Fine deposits are recorded in the `library_bnk_account` and `fine_deposits` ledger. The deposit action records the collected amount in the application database; it does not connect to a bank or initiate a transfer.
- Member identity for `/api/me/loans` comes from the authenticated account, never a request parameter. Late fees use the existing rule of 5 units per overdue day.
- Creating a book provisions the requested number of AVAILABLE `BOOK_COPIES`; reducing inventory is rejected if the copies to remove are issued or otherwise unavailable.
- `GET /api/books/top-borrowed` returns the most borrowed books for the shared dashboard panel. The circulation SQL script provisions missing copy rows for legacy books with catalog copies but no inventory records.
- `GET /api/books` accepts `page`, `size`, and `search`; it returns a Spring page response with at most `size` books per page and copy availability counts. The default page size is five.

## Validation

From the repository root:

```powershell
mvn -f backend/pom.xml test
npm --prefix frontend test -- --watchAll=false
npm --prefix frontend run build
```

Database-backed checks require the Oracle schema and connection configured above.
