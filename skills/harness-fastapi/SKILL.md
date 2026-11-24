---
name: harness-fastapi
description: Use when you write or change FastAPI endpoints, dependencies, Pydantic models, settings, middleware, or FastAPI tests.
---

# FastAPI

Check the installed versions of `fastapi`, `pydantic`, and `starlette` first. The rules below assume Pydantic 2.

## Endpoints
- An `async def` endpoint must not block: no `requests`, no sync database driver, no `time.sleep`.
  Use an async client (`httpx.AsyncClient`, `asyncpg`, async `psycopg`), or write a plain `def` endpoint. FastAPI runs it in a thread pool.
- Declare dependencies with `Annotated[T, Depends(...)]`.
- A dependency that opens a resource uses `yield` and closes it after the request. One database session per request.
- Use separate models for input and output. Never return an ORM object or a model with secrets. Set `response_model` or the return type.
- Validate input at the model: types, `Field` constraints, and `model_config = ConfigDict(extra="forbid")` for strict input.
- Raise `HTTPException` with the right status code. Do not put stack traces or internal details in the response.

## Pydantic 2
- Use `model_validate`, `model_dump`, `model_config`, and `field_validator`. Do not add `.dict()`, `.parse_obj()`, `class Config`, or `@validator`.

## Application
- Use the `lifespan` context manager for startup and shutdown. Do not add `@app.on_event`.
- Settings: `pydantic-settings` `BaseSettings`, read from the environment. No secret has a default value.
- `BackgroundTasks` is only for short, best-effort work. Durable work goes to Temporal or Service Bus.
- Kubernetes probes: a liveness endpoint without dependency checks, and a readiness endpoint that checks the dependencies.
- The OpenAPI schema is a public API. A breaking change needs a new version or a deprecation period.

## Tests
- Use `TestClient`, or `httpx.AsyncClient` with `ASGITransport` for async tests.
- Replace dependencies with `app.dependency_overrides`. Clear the overrides after each test.
- Test against a real PostgreSQL (`harness-postgres`). Use synthetic data.
