# Library Backend

Spring Boot REST API for library accounts, books, members, and circulation.

## Setup

Run the Oracle scripts in `Lib_dbo/00_run_all_library_system.sql`, which now installs `12_authentication_tables.sql`. Existing deployments can run that authentication script separately before starting the updated backend. Hibernate uses `ddl-auto: validate`; schema changes belong in SQL scripts.

Configure the database with `DB_URL`, `DB_USERNAME`, and `DB_PASSWORD`. The default JDBC URL targets local Oracle `ORCLPDB`.

Set `JWT_SECRET_BASE64` to a Base64-encoded random secret with at least 32 bytes of decoded key material. For example, generate one with `openssl rand -base64 32`. `JWT_EXPIRATION_MS` defaults to 15 minutes. `JWT_COOKIE_SECURE` defaults to `true`; set it to `false` only for local HTTP development. Do not use a committed or predictable signing key.

Public registration creates a member and a MEMBER account. It cannot grant administrator access. Provision admins using an operator-controlled account workflow after generating a BCrypt password hash:

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

- `POST /api/auth/register`, `POST /api/auth/login`, and `GET /api/auth/csrf` are available without an account. `POST /api/auth/logout` clears the cookie; `GET /api/auth/me` returns the signed-in profile and roles.
- Authenticated members can read the book catalog and call `GET /api/me/loans` for their own full loan history.
- ADMIN accounts can manage book records, query members, and use `/api/admin/loans` to list active loans, issue books, and return books.
- Member identity for `/api/me/loans` comes from the authenticated account, never a request parameter.
- Creating a book provisions the requested number of AVAILABLE `BOOK_COPIES`; reducing inventory is rejected if the copies to remove are issued or otherwise unavailable.

## Validation

From the repository root:

```powershell
mvn -f backend/pom.xml test
npm --prefix frontend test -- --watchAll=false
npm --prefix frontend run build
```

Database-backed checks require the Oracle schema and connection configured above.
