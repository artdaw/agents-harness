---
name: harness-postgres
description: Use when you write or change PostgreSQL schema, queries, indexes, migrations, or connection settings, or run psql.
---

# PostgreSQL

Migrations follow the SQL stack section (`stacks/sql.md`): expand and contract, `CONCURRENTLY`, `NOT VALID`, `lock_timeout`.
This skill adds the rules for schema, queries, and access.

## Version
- Check the server version (`SHOW server_version;`) before you use a feature.
  Examples: `MERGE` needs 15+. `NULLS NOT DISTINCT` needs 15+.

## Access
- Before each `psql` command, check the host and the database name.
- On a database that you are not allowed to change, run read-only:
  `BEGIN READ ONLY;` or `SET default_transaction_read_only = on;`.
- Set `statement_timeout` for ad-hoc queries on shared databases.
- Run scripts with `psql -v ON_ERROR_STOP=1`.
- Do not run `EXPLAIN ANALYZE` on production. It executes the query. Use `EXPLAIN` there.

## Schema
- Time: `timestamptz`, not `timestamp`.
- Text: `text`. Add a `CHECK` for a length limit if one is needed.
- IDs: `bigint GENERATED ALWAYS AS IDENTITY` or `uuid`. Do not add new `serial` columns.
- Money and exact values: `numeric`. Never `float` or `real`.
- JSON: `jsonb`, not `json`.
- Each foreign key needs an index on the referencing column, unless the project has a reason not to.
- Follow the existing naming and type conventions first.

## Queries
- Use parameters. Never build SQL with string concatenation.
- Use `NOT EXISTS`, not `NOT IN`, when the subquery can return `NULL`.
- Upsert with `INSERT ... ON CONFLICT`.
- Large tables: paginate with a keyset (`WHERE id > $1 ORDER BY id LIMIT n`), not a large `OFFSET`.
- Job queues in a table: `SELECT ... FOR UPDATE SKIP LOCKED`.
- Keep transactions short. Do not call the network inside a transaction.
- Prevent N+1 queries. Check the ORM output when you add a relation load.

## Connection pooling
- With PgBouncer in transaction mode, session state does not survive between transactions:
  `SET`, session advisory locks, `LISTEN`, temporary tables. Use `SET LOCAL` and transaction-level locks.
- Do not open a new connection per request. Use the pool of the project.

## Tests
- Test against a real PostgreSQL (Docker or Testcontainers, as the project does). Do not use SQLite as a substitute.
- Use synthetic data only.
