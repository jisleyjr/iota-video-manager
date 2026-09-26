# API implementation roadmap

1. [API foundation](01-api-foundation-plan.md): implemented Kotlin/Spring Boot, MySQL connectivity, Liquibase, health checks, Docker, and local development instructions.
2. [YouTube monitoring](02-api-youtube-monitoring-plan.md): stored video queries, synchronization, retention, and ShedLock jobs. This remains planned follow-up work. Sub-phases are tracked in [02-youtube-monitoring](02-youtube-monitoring/README.md).

The API is a standalone Gradle project in `api/`. Docker Compose starts the API and MySQL 8.4 together by default. See [API setup](../../api/README.md) for executable commands.
