## Stack: SQL and migrations
Applies to SQL files and to the migration tool of the project (Flyway, Liquibase, Alembic, golang-migrate, Prisma, and others).
- Use the migration tool of the project. If the tool generates migration files, use its command. Do not write them by hand.
- Never edit a migration that has run in a shared environment. Add a new migration.
- Run migrations only on a local or test database. Write the command for other environments in the report.
- One migration is one logical change. Write the down migration if the tool supports it,
  or write why a rollback is not possible.
- A breaking change (rename, drop, type change, new `NOT NULL`) on a table that running code uses needs expand and contract:
  1. Expand: add the new column or table. It is nullable or has a default.
  2. Deploy code that writes both and reads the new one.
  3. Backfill in batches, in a job. Do not backfill in the deploy migration.
  4. Contract: remove the old column in a later release.
- PostgreSQL:
  - Use `CREATE INDEX CONCURRENTLY` and `DROP INDEX CONCURRENTLY`. They cannot run in a transaction.
    Mark the migration as non-transactional in the tool.
  - Add a foreign key or check with `NOT VALID`. Run `VALIDATE CONSTRAINT` in a separate migration.
  - Set `lock_timeout` in migrations that take locks.
  - Lint migrations with `squawk` if it is installed.
- Lint: `sqlfluff lint` if `.sqlfluff` exists.
- Queries: use parameters. Never build SQL with string concatenation. Select named columns in application code, not `*`.
- Check a new query on a large table with `EXPLAIN`. Do not run `EXPLAIN ANALYZE` on production: it runs the query.
- Never put production or customer data in seed files, fixtures, or tests. Use synthetic data.
