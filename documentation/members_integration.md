# Members Stored Procedure and Integration

This document describes the new PL/SQL stored procedure, backend and frontend changes to expose members via a REST API and UI.

Files added
- PL/SQL procedure: Lib_dbo/sp_members.sql
- Backend: `MemberDTO`, `MemberRepository`, `MemberService`, `MemberServiceImpl`, `MemberController`
- Frontend: `frontend/src/pages/MembersList.tsx` and `frontend/src/App.tsx` updated

Step-by-step build & run

1. Apply the PL/SQL to your Oracle database

   - Connect to your target PDB and run the script: [Lib_dbo/sp_members.sql](Lib_dbo/sp_members.sql)

2. Configure the backend datasource

   - Edit [backend/src/main/resources/application.yml](backend/src/main/resources/application.yml#L1) and ensure `spring.datasource.url`, `username`, and `password` match your database.

3. Build and run the backend

   From repository root run:

   ```bash
   cd backend
   mvn clean package
   mvn spring-boot:run
   ```

   The API endpoint will be available at `http://localhost:8080/api/members`.

   Example query parameters: `?memberId=1`, `?name=John`, `?memberType=STUDENT`.

4. Build and run the frontend (development)

   From repository root run:

   ```bash
   cd frontend
   npm install
   npm start
   ```

   The UI will call `/api/members` (proxy assumed as in existing project). The `Members` view is rendered by [frontend/src/pages/MembersList.tsx](frontend/src/pages/MembersList.tsx).

5. Notes and troubleshooting

   - The backend uses Spring's `SimpleJdbcCall` to execute `sp_get_members` and map the returned `SYS_REFCURSOR` to a list of `MemberDTO` objects.
   - If you have driver issues, ensure the Oracle JDBC driver `ojdbc11` is available to the application (the project pom includes it with `runtime` scope). You may need to install the driver to your local Maven repo or change scope to `compile` for local builds.
   - SQL filtering is performed in the stored procedure. Supplying empty parameters returns all members.
