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
    Mark the migration as non-transactional in the tool. Prisma has no marker: see the Prisma rules below.
  - Add a foreign key or check with `NOT VALID`. Run `VALIDATE CONSTRAINT` in a separate migration.
  - Set `lock_timeout` in migrations that take locks.
  - Lint migrations with `squawk` if it is installed.
- Prisma (`schema.prisma`, `prisma/`). Run the CLI through the project package manager, for example `pnpm exec prisma`.
  - Checks: `prisma validate` and `prisma format --check`. Run `prisma generate` after each schema change.
  - Create a migration with `prisma migrate dev --create-only`. Read the SQL before you apply it.
    Edit the SQL there for `NOT VALID` or a data step. The schema file cannot express these.
  - Prisma has no non-transactional marker. PostgreSQL runs a multi-statement migration file in one transaction.
    Put each `CREATE INDEX CONCURRENTLY` alone in its own migration file. Remove the plain `CREATE INDEX` from the other file.
    Do not add `SET lock_timeout` or any other statement to that file.
  - Run `prisma migrate dev` only against a local database. It can ask to reset the database when it finds drift.
  - Never run `prisma migrate reset` or `prisma db push` against a shared database. `db push` skips the migration files.
  - Do not run `prisma migrate deploy` yourself. Write it in the report for the environment owner.
- Lint: `sqlfluff lint` if `.sqlfluff` exists.
- Queries: use parameters. Never build SQL with string concatenation. Select named columns in application code, not `*`.
- Check a new query on a large table with `EXPLAIN`. Do not run `EXPLAIN ANALYZE` on production: it runs the query.
- Never put production or customer data in seed files, fixtures, or tests. Use synthetic data.
