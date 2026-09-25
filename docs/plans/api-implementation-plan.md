# Kotlin API implementation plan

## Summary

Create a runnable Spring Boot API in `api/`, with MySQL persistence, Liquibase migrations, ShedLock jobs, and the documented YouTube monitoring feature.

Use the Gradle Kotlin DSL with a version catalog, standard Spring configuration, and Liquibase migration organization. Keep a simple Controller → Service → Repository structure with public dependencies only.

Confirmed decisions: secrets in `.env`, localhost access, and YouTube/ShedLock tables only. Media processing, catalog workflows, authentication, and rendered-output associations remain deferred.

## Project and database foundation

- Create a standalone Gradle project named `iota-video-manager-api`, with package `com.iota.videomanager.api`, a committed wrapper, and `api/gradle/libs.versions.toml`.
- Use Java 21, Kotlin 2.3.20, Gradle 9.7.1, and Spring Boot 4.1.1. These follow the reference project and supported [Spring Boot](https://docs.spring.io/spring-boot/system-requirements.html) and [Kotlin/Gradle](https://kotlinlang.org/docs/gradle-configure-project.html) compatibility ranges.
- Define plugin and dependency aliases in the catalog. Use Spring’s dependency management for supported libraries; explicitly version dependencies outside its BOM. Include MVC, validation, Data JPA, Actuator, Jackson Kotlin support, MySQL Connector/J, Liquibase, and ShedLock.
- Use Kotlin JVM, Spring, and JPA plugins; configure JPA entities for proxying. Do not copy Bushel dependencies, plugins, packages, BIDL, private repositories, or remote Gradle scripts.
- Organize code into `controller`, `service`, `repository`, `entity`, `dto`, `client`, `job`, and `config` packages. Use constructor injection, dedicated response DTOs, and service-owned transaction boundaries.
- Run Liquibase during startup through the Boot Liquibase starter. Use an explicitly ordered YAML master changelog and immutable, numbered changesets. Configure Hibernate to validate the schema and disable Open Session in View. [Liquibase startup integration](https://docs.spring.io/spring-boot/how-to/data-initialization.html).
- Create only `youtube_video` and `shedlock`, plus Liquibase’s bookkeeping tables. Map the documented YouTube fields using UUID identifiers, UTC timestamps, nullable counts, and decimal durations. Use case-sensitive comparison for YouTube IDs, a unique video-ID constraint, and indexes for channel listing and expiry.
- Defer the rendered-output column and foreign key. Preserve the response field `renderedOutputId`, always returning null in this release.

## YouTube endpoints and background jobs

- Implement the existing monitoring design, with MySQL and ShedLock replacing PostgreSQL advisory locks.
- Add:
  - `GET /api/youtube/videos?page=0&size=25`
  - `GET /api/youtube/videos/{id}`
  - Actuator health with liveness and database-aware readiness.
- Preserve the documented response envelope, camelCase fields, UTC timestamp strings, decimal-string counts, pagination limits, and deterministic publication-date ordering with null dates last.
- Return consistent Spring `ProblemDetail` errors: 400 for invalid input, 404 for missing or expired records, and 503 for missing or invalid monitoring configuration. Reads use stored data and remain available during YouTube outages.
- Implement a Spring REST client for channel resolution, complete uploads-playlist pagination, and video lookups in batches of up to 50 IDs. Combine discovered IDs with previously stored IDs for the configured channel.
- Commit each successful lookup batch atomically, without holding database transactions during HTTP calls. Preserve stable internal IDs, replace absent optional values with null, accept decreasing counts, and mark unavailable videos only after successful lookups.
- Use five-second connection and thirty-second request timeouts. Follow the documented maximum of three attempts, exponential backoff with jitter, `Retry-After`, and non-retryable quota/configuration failures.
- Schedule an initial asynchronous sync after application readiness, followed by fixed-delay runs using `YOUTUBE_SYNC_INTERVAL`, default `PT6H`. Missing configuration disables synchronization without preventing API startup.
- Use ShedLock 7.10.0 with its JDBC provider and `usingDbTime()`. Route startup and periodic execution through the same proxied job method. Skip lock contention. Bound synchronization to thirty minutes with a one-hour maximum lock duration; check the deadline between requests, retries, and batches. ShedLock 7 supports Spring Boot 4. [ShedLock documentation](https://github.com/lukas-krecan/ShedLock).
- Run retention cleanup at startup and hourly under a separate lock, independently of monitoring configuration. Delete records at thirty days since their last successful refresh; apply the same cutoff to every read query.
- Give synchronization and cleanup separate scheduler capacity. Record sanitized run outcomes, timing, record counts, and failures without logging credentials, request URLs containing keys, or response payloads.

## Docker, configuration, and documentation

- Add a root `Dockerfile`, `docker-compose.yml`, and `.dockerignore`. Build the API with its Gradle wrapper in a Java 21 build stage; run the executable JAR as a non-root user in a Java 21 runtime stage.
- Compose starts `mysql:8.4` with a persistent named volume and the API after a successful database health check. Publish the API at `127.0.0.1:8080` and MySQL at `127.0.0.1:3306` for local development.
- Commit `.env.example` with placeholders; ignore `.env` in Git and exclude environment files from Docker build context. Store no credentials in MySQL.
- Define `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `YOUTUBE_API_KEY`, `YOUTUBE_CHANNEL_ID`, and `YOUTUBE_SYNC_INTERVAL`. Default the database/user to `iota_video_manager`/`iota`; require explicitly supplied database passwords.
- Inject variables explicitly per service: the API receives its database credentials and YouTube configuration; only MySQL receives the root password. Database connection configuration uses `mysql:3306` in Compose and localhost for host-run development.
- Document environment export for `bootRun`; Spring will consume environment variables without introducing a dotenv library. Configuration changes require an API restart.
- Document setup, build, tests, host-run development, `docker compose up --build`, logs, shutdown, and persistence. Explain that changing `.env` passwords does not update users in an existing database volume.
- Update architecture documentation from PostgreSQL/advisory locks to MySQL/ShedLock and distinguish implemented YouTube behavior from future catalog features. The README module descriptions and ERD navigation are already correct.

## Validation and acceptance

- Use JUnit through Spring Boot’s test support, MySQL Testcontainers, a controlled HTTP stub, and an injectable clock. Tests must not require real YouTube credentials.
- Verify clean migration startup, repeated startup, schema validation, persistence across container restarts, and failure on invalid database credentials.
- Test paginated discovery, repeated synchronization without duplicates, case-sensitive video IDs, changed and absent counts, unavailable/restored videos, partial failures, retries, and deadline handling.
- Test two competing job instances against one MySQL database: only one executes, failures release the lock, and abandoned locks expire.
- Test independent cleanup with missing credentials, exact thirty-day expiry, and exclusion of expired records from both endpoints.
- Test pagination, null ordering, UUID validation, 400/404/503 responses, UTC serialization, counts above JavaScript’s safe integer range, and `renderedOutputId: null`.
- Run Gradle `check` and `bootJar`, then a Compose smoke test confirming database/API health and expected behavior without YouTube configuration. Verify secrets are absent from Git, build context, image contents, and logs; finish with documentation-link checks and `git diff --check`.
