---
name: harness-redis
description: Use when you write or change code that uses Redis or Valkey (cache, locks, rate limits, queues, pub/sub, streams), or run redis-cli.
---

# Redis

Check which server the project uses (Redis, Valkey, or a managed service), its version, and cluster mode.

## Keys
- Use the key naming pattern of the project. Add a version part when the value format changes, for example `user:v2:{id}`.
- Each cache key needs a TTL.
- Cluster mode: a multi-key command or script needs all keys in the same hash slot. Use a hash tag: `{user:42}:a`, `{user:42}:b`.

## Commands
- Do not use `KEYS` outside local development. Use `SCAN`.
- Do not use `FLUSHALL` or `FLUSHDB` outside local development.
- Avoid O(N) commands on large collections (`HGETALL`, `SMEMBERS`, `LRANGE 0 -1`). Use `HSCAN`, `SSCAN`, or limits.
- Use pipelining for many independent commands.

## Atomicity and locks
- Use `MULTI`/`EXEC` or a Lua script for read-modify-write.
- Lock: `SET key token NX PX <ms>`. Release with a script that deletes the key only if the token matches.
- A Redis lock can expire while the holder still works. Do not use it alone for correctness.
  Protect the real write with a fencing token or a database constraint.

## Cache
- On write, delete the cache key after the database commit. Do not update the cache before the commit.
- The code must work when Redis is down or the key is missing. Fall back to the source.
- Prevent a stampede on hot keys: lock, early refresh, or TTL jitter.

## Data safety
- Redis can lose data on restart if persistence is not configured. Do not store the only copy of data there.
- Pub/Sub does not store messages. A subscriber that is offline loses them. Use Streams with consumer groups and `XACK` for durable delivery.
- Do not deserialize Redis values with `pickle` or other unsafe formats. Use JSON or the project format.
- Do not store secrets or personal data without a TTL and a reason.

## Tests
- Use a real Redis in a container, or the fake of the project. Use synthetic data.
