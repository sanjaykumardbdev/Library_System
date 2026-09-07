**Project Files Notes — Java + UI**

Overview: concise notes for the Java backend and React UI, with key file locations, short comments, an end-to-end flow from DB to UI, and required services to run before opening the web app.

**Backend Files**
- **`backend/src/main/resources/application.yml`**: DataSource configuration (JDBC URL, username, password, Hikari settings). Example: `jdbc:oracle:thin:@//localhost:1521/ORCLPDB`.
- **`backend/pom.xml`**: Maven build and plugin configuration; defines Spring Boot dependencies and packaging.
- **`backend/src/main/java/com/library/LibraryApplication.java`**: Spring Boot `@SpringBootApplication` entry point (may be named `Application` or similar).
- **`backend/src/main/java/com/library/entity/Book.java`**: JPA entity mapping for `books` table. Must include ID generation matching DB (sequence `seq_books` or identity). If using sequence:
  - `@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "books_seq_gen")`
  - `@SequenceGenerator(name = "books_seq_gen", sequenceName = "SEQ_BOOKS", allocationSize = 1)`
- **`backend/src/main/java/com/library/repository/BookRepository.java`**: `JpaRepository<Book,Long>` — data access layer.
- **`backend/src/main/java/com/library/service/impl/BookServiceImpl.java`**: Business logic and CRUD orchestration; calls repository methods.
- **`backend/src/main/java/com/library/controller/BookController.java`**: REST endpoints under `/api/books` — maps HTTP requests to service methods.
- **`backend/src/main/java/com/library/config/SecurityConfig.java`**: Dev-friendly security config (usually permits `/api/**`, disables CSRF for local dev).

**Frontend Files**
- **`frontend/package.json`**: Frontend scripts, dependencies, and `proxy` pointing to backend (e.g., `http://localhost:8080`).
- **`frontend/src/pages/BooksList.js`**: Page component that fetches `/api/books` via Axios, stores results in state, and renders the table and child components.
- **`frontend/src/components/BookForm.js`** (if present): Create / Edit form that posts to `/api/books` (use POST for create, PUT for update).

**Database scripts / objects**
- All schema and helper scripts are consolidated under `Lib_dbo/` (e.g., [Lib_dbo/00_create_schema_and_tablespace_for_library.sql](Lib_dbo/00_create_schema_and_tablespace_for_library.sql#L1)).
- Important scripts:
  - `Lib_dbo/05_sequences.sql` — creates sequences (e.g., `SEQ_BOOKS`, `SEQ_BOOK_COPIES`, `SEQ_LOANS`).
  - `Lib_dbo/02_master_tables.sql` — DDL for master tables such as `books`, `book_copies`, `members`, `loan_transactions`.
  - `Lib_dbo/10_sample_data.sql` — loads sample data used by the UI.
  - `Lib_dbo/data reconciliation.sql` — repair script to sync `books.total_copies` with `book_copies`.

**Flow: DB → Backend → UI (concise)**
1. Startup: Oracle DB service (listener) runs; schema `library_etl` exists with required tables/sequences (run `Lib_dbo/00_run_all_library_system.sql` to create).
2. Backend config: `application.yml` defines JDBC URL, `username`=`library_etl`, `password`=`library_etl`. Spring Boot auto-configures a `DataSource` and `EntityManager`.
3. JPA mapping: `Book` and other entity classes map columns (with `@Column`) and primary key generation (`@Id`, `@GeneratedValue`). Hibernate uses sequences or ID strategy to assign IDs on `save()`.
4. Repository layer: `BookRepository` exposes CRUD operations (`findAll()`, `save()`, `findById()`, `deleteById()`).
5. Service layer: `BookServiceImpl` implements business rules and calls repository methods; it transforms DTOs if present.
6. Controller layer: `BookController` exposes REST endpoints (`GET /api/books`, `POST /api/books`, `PUT /api/books/{id}`, `DELETE /api/books/{id}`). Responses are JSON.
7. Frontend request: `BooksList.js` (or equivalent) issues an Axios `GET /api/books` to the backend (proxy or CORS). Backend responds with JSON array of book records.
8. UI render: React component sets state with response and renders rows in a table. Create/update flows call POST/PUT; form components should clear and refresh list after success.

**Services & steps to run before opening the web UI**
- Oracle DB: ensure listener running and container/instance accessible at the JDBC URL in `application.yml` (default `localhost:1521/ORCLPDB`).
- (Optional) Run SQL scripts to create schema & sample data:
  ```bash
  sqlplus "library_etl/library_etl@ORCLPDB" @Lib_dbo/00_run_all_library_system.sql
  sqlplus "library_etl/library_etl@ORCLPDB" @Lib_dbo/10_sample_data.sql
  ```
- Backend: in project `backend/` run
  ```bash
  cd backend
  mvn spring-boot:run
  ```
  - Backend listens on port `8080` by default. Confirm logs show Hikari pool and Tomcat started.
- Frontend: in `frontend/` run
  ```bash
  cd frontend
  npm install
  npm start
  ```
  - CRA dev server usually runs on `http://localhost:3000` and proxies API requests to backend.

**Quick checks & troubleshooting**
- If POST/PUT fails with Hibernate ID error: ensure entity `@GeneratedValue` and sequence exist (see `Lib_dbo/05_sequences.sql`).
- If backend cannot connect: verify `application.yml` credentials and test with `sqlplus` from the same host.
- If frontend requests fail: check `frontend/package.json` `proxy` or enable CORS on backend.

**Recommendations**
- Keep DB DDL & sequences authoritative under `Lib_dbo/` and re-run on a fresh DB during testing.
- Add a small README that documents how to run DB → backend → frontend locally (I can create this if you want).
- Remove large artifacts from Git history (e.g., `backend/target/*.jar`) using `git filter-repo` or use Git LFS for future large files.

If you want, I can:
- generate a short `README.md` with exact commands and checks, or
- open and patch `Book.java` to ensure proper sequence-based ID generation now.
