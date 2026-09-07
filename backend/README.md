# Library Backend

Minimal Spring Boot backend scaffold for the Library Management System.

How to build:

```bash
mvn -f backend/pom.xml -DskipTests package
```

Configure DB connection via environment variables:

- `DB_URL` (example: `jdbc:oracle:thin:@//host:1521/ORCLPDB`)
- `DB_USERNAME`
- `DB_PASSWORD`

Notes:
- `spring.jpa.hibernate.ddl-auto` is set to `validate` to avoid schema changes.
- Entities map to existing Oracle schema; do not change the DB from the app.
