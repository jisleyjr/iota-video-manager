# API foundation plan

## Summary

Status: implemented. Setup and executable commands are in the [API README](../../api/README.md).

Create the first runnable API in `api/`: Kotlin/Spring Boot, MySQL 8.4, Liquibase, health checks, and Docker. Business endpoints, YouTube tables/jobs, authentication, frontend work, and media processing belong to later milestones. See [YouTube monitoring](api-youtube-monitoring-plan.md) for the next milestone.

## Project foundation

- Create a standalone Gradle Kotlin DSL project named `iota-video-manager-api`, package `com.iota.videomanager.api`, with the complete Gradle wrapper and a plugin/dependency version catalog.
- Use Java 21, Kotlin 2.3.20, Gradle 9.3.0, and Spring Boot 4.1.1. Gradle 9.3.0 stays within the [Kotlin compatibility range](https://kotlinlang.org/docs/gradle-configure-project.html) and [Spring Boot requirements](https://docs.spring.io/spring-boot/system-requirements.html).
- Use public repositories and Spring Boot dependency management. Include MVC, validation, Data JPA, Actuator, Jackson Kotlin support, Kotlin reflection, MySQL Connector/J, and the Boot Liquibase starter.
- Enable Kotlin JVM, Spring, and JPA plugins, including entity proxy support. Add the application entry point and YAML configuration without placeholder business packages.
- Use an empty YAML Liquibase master changelog, with explicitly ordered immutable changesets added in future milestones. Only Liquibase bookkeeping tables exist initially.
- Configure Hibernate schema validation, disabled Open Session in View, and UTC JDBC timestamps.

## Health and container interfaces

- Expose `/actuator/health`, `/actuator/health/liveness`, and `/actuator/health/readiness`, returning status without internal details. Include database connectivity in readiness; keep liveness independent of MySQL.
- Add `api/Dockerfile` with `api/` as the build context: build the executable JAR with the wrapper and Java 21 JDK, then run it as a non-root user with Java 21 JRE. Include a readiness health check and `api/.dockerignore`.
- Root `docker-compose.yml` starts API and MySQL by default. Use `mysql:8.4` with a named data volume and an application-credential SQL health check. Gate API startup on healthy MySQL.
- Bind API port 8080 and MySQL port 3306 to `127.0.0.1`.
- Use `.env.example` for `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, and `MYSQL_ROOT_PASSWORD`. Default the database/user to `iota_video_manager`/`iota`; require explicit passwords. Only MySQL receives the root password.
- Host execution uses localhost by default; Compose overrides `SPRING_DATASOURCE_URL` to use `mysql:3306`.
- Ignore local secrets and Gradle/Kotlin artifacts in Git. Limit Docker context to required build inputs.

## Documentation

Document environment setup, prerequisites, wrapper commands (`bootRun`, `check`, `bootJar`), Docker build/run, Compose startup, database-only startup, health checks, logs, shutdown, and persistence. Explain environment export for host execution and that changed password variables do not update an existing database volume.

Update repository guidance and architecture references from PostgreSQL to MySQL; document ShedLock as planned. Distinguish the runnable foundation from all future business features.

## Validation

- Use Spring Boot test support with MySQL Testcontainers; tests require Docker but no manually configured database or YouTube credentials.
- Verify application startup, Liquibase bookkeeping without business tables, repeat startup, and health responses.
- Verify database failure makes readiness unhealthy while liveness remains healthy.
- Run `./gradlew check bootJar`.
- Smoke-test Compose startup, readiness, non-root execution, and persistence across container recreation.
- Check documentation links and `git diff --check`.
