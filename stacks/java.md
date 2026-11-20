## Stack: Java (Maven or Gradle)
Applies to the directory that contains `pom.xml`, `build.gradle`, or `build.gradle.kts`.
- Use the wrapper: `./mvnw` or `./gradlew`. Use bare `mvn` or `gradle` only if no wrapper exists.
  Do not change the wrapper version unless the task asks for it.
- Use the JDK version that the build declares (Gradle toolchain, `maven.compiler.release`, `.java-version`, `.sdkmanrc`).
  Do not raise it.
- Check: `./mvnw -q verify` or `./gradlew check`.
- One test: `./mvnw -q test -Dtest='Class#method'` or `./gradlew test --tests 'Class.method'`.
- Format: use the formatter that the build configures (for example Spotless with google-java-format).
  Check: `./mvnw spotless:check` or `./gradlew spotlessCheck`. Do not add a formatter.
- Static checks: run the configured tools (Error Prone, NullAway, SpotBugs, Checkstyle, PMD).
  Do not suppress a warning to pass a check.
- Dependencies: pin exact versions. Do not use dynamic versions (`1.+`, `latest.release`, ranges).
  Use the BOM or the version catalog (`gradle/libs.versions.toml`) if the project has one.
- Commit the wrapper files and the dependency lock files if they exist.
- Use try-with-resources for each `AutoCloseable`. Use `record` for immutable data if the JDK supports it.
- Use `Optional` only for return values. Do not use it for fields or parameters.
- Tests: JUnit 5 (`@ParameterizedTest` for cases, `@TempDir` for files).
  Use Testcontainers for a real database if the project uses it.
