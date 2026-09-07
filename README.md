# Library Management System (scaffold)

This workspace contains the Oracle SQL deployment scripts and a scaffold for a Java Spring Boot backend and a React frontend.

What's included:

- Oracle deployment scripts (SQL files)
- `backend/` - Spring Boot scaffold (Maven) with Authors, Publishers, Books, BookCopies endpoints
- `frontend/` - Minimal React+TypeScript scaffold with a Books list page

Next steps:

1. Configure environment variables `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`.
2. Build backend: `mvn -f backend/pom.xml -DskipTests package`.
3. Start frontend: `cd frontend && npm install && npm start` (or use preferred tooling).
