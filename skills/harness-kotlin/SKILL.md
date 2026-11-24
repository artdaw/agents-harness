---
name: harness-kotlin
description: Use when you write or change Kotlin code, especially Spring Boot services, configuration, JPA entities, coroutines, or Kotlin tests.
---

# Kotlin and Spring Boot

Check the Kotlin, Spring Boot, and JDK versions in the build files first. Build with the Gradle or Maven wrapper (`stacks/java.md`).

## Kotlin
- Do not add `!!`. Handle `null` with `?.`, `?:`, or an explicit check.
- Values from Java APIs have platform types. Declare the nullability at the boundary.
- Prefer `val` and immutable collections. Use `data class` for values, not for JPA entities.
- Lint with `ktlint` or `detekt` if the project has it.

## Spring Boot
- Use constructor injection with `val` parameters. Do not add `@Autowired lateinit var` fields.
- The build needs the `kotlin("plugin.spring")` plugin. Spring proxies need open classes.
  JPA entities also need `kotlin("plugin.jpa")`.
- Bind configuration with `@ConfigurationProperties` and validate it with `@Validated`. Secrets come from the environment or Key Vault, not from `application.yml`.
- `@Transactional` works only on public methods called from another bean. A call from the same class skips the proxy.
- Avoid N+1 queries: check the SQL log when you add a relation, and use a fetch join or an entity graph.
- Actuator: expose only `health`, `info`, and the metrics endpoint that the monitoring uses. Use the liveness and readiness health groups for Kubernetes probes.
- Metrics and traces go through Micrometer, with the registry that the project uses (Prometheus or OTLP).

## Coroutines and blocking
- Do not call blocking code (JDBC, JPA, file I/O) inside a coroutine on the default dispatcher. Use `withContext(Dispatchers.IO)`.
- Do not mix WebFlux with blocking JPA in one request path. Follow the stack that the project uses (Spring MVC or WebFlux).

## Tests
- JUnit 5. Use test slices (`@WebMvcTest`, `@DataJpaTest`) before a full `@SpringBootTest`.
- Use the mock library that the project uses (MockK or Mockito-Kotlin).
- Use Testcontainers for PostgreSQL, Redis, and Service Bus emulators, as the project does. Use synthetic data.
