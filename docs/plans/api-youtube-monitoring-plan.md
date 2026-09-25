# API YouTube monitoring plan

## Status and prerequisite

Planned follow-up to [the API foundation](api-foundation-plan.md). Do not implement this feature as part of the foundation milestone.

Implement the [YouTube monitoring design](../pages/api/youtube-monitoring.adoc) using the foundation's Kotlin/Spring Boot project, MySQL 8.4, Liquibase, version catalog, and Docker configuration. Keep Controller → Service → Repository boundaries, constructor injection, dedicated DTOs, and service-owned transactions. Add `controller`, `service`, `repository`, `entity`, `dto`, `client`, `job`, and `config` packages as needed.

## Database changes

- Add immutable, numbered migrations to the explicitly ordered YAML master changelog.
- Create only `youtube_video` and `shedlock`; Liquibase bookkeeping already exists.
- Map the documented YouTube fields using UUID identifiers, UTC timestamps, nullable counts, and decimal durations. Use case-sensitive comparison for YouTube IDs, a unique video-ID constraint, and indexes for channel listing and expiry.
- Defer the rendered-output column and foreign key. Preserve the response field `renderedOutputId`, always returning null in this release. Output association acceptance scenarios remain future work.
- Retain Hibernate schema validation and disabled Open Session in View.

## YouTube endpoints and background jobs

- Implement the existing monitoring design, with MySQL and ShedLock replacing PostgreSQL advisory locks.
- Add:
  - `GET /api/youtube/videos?page=0&size=25`
  - `GET /api/youtube/videos/{id}`
- Preserve the foundation's Actuator health with liveness and database-aware readiness.
- Preserve the documented response envelope, camelCase fields, UTC timestamp strings, decimal-string counts, pagination limits, and deterministic publication-date ordering with null dates last.
- Return consistent Spring `ProblemDetail` errors: 400 for invalid input, 404 for missing or expired records, and 503 for missing or invalid monitoring configuration. Reads use stored data and remain available during YouTube outages.
- Implement a Spring REST client for channel resolution, complete uploads-playlist pagination, and video lookups in batches of up to 50 IDs. Combine discovered IDs with previously stored IDs for the configured channel.
- Commit each successful lookup batch atomically, without holding database transactions during HTTP calls. Preserve stable internal IDs, replace absent optional values with null, accept decreasing counts, and mark unavailable videos only after successful lookups.
- Use five-second connection and thirty-second request timeouts. Follow the documented maximum of three attempts, exponential backoff with jitter, `Retry-After`, and non-retryable quota/configuration failures.
- Schedule an initial asynchronous sync after application readiness, followed by fixed-delay runs using `YOUTUBE_SYNC_INTERVAL`, default `PT6H`. Missing configuration disables synchronization without preventing API startup.
- Use ShedLock 7.10.1 with its JDBC provider and `usingDbTime()`. Route startup and periodic execution through the same proxied job method. Skip lock contention. Bound synchronization to thirty minutes with a one-hour maximum lock duration; check the deadline between requests, retries, and batches. ShedLock 7 supports Spring Boot 4. [ShedLock documentation](https://github.com/lukas-krecan/ShedLock).
- Run retention cleanup at startup and hourly under a separate lock, independently of monitoring configuration. Delete records at thirty days since their last successful refresh; apply the same cutoff to every read query.
- Give synchronization and cleanup separate scheduler capacity. Record sanitized run outcomes, timing, record counts, and failures without logging credentials, request URLs containing keys, or response payloads.

## Configuration and documentation

- Add `YOUTUBE_API_KEY`, `YOUTUBE_CHANNEL_ID`, and `YOUTUBE_SYNC_INTERVAL` (default `PT6H`) to `.env.example`, API configuration, Compose's API environment, and setup instructions.
- Keep credentials in environment variables, never database records. Only MySQL receives its root password; only the API receives the YouTube API key.
- Missing or invalid monitoring configuration disables synchronization without preventing unrelated API startup; YouTube reads return the documented 503 configuration error.
- Keep API and database bindings on localhost. Authentication, publishing, frontend work, media processing, catalog workflows, and rendered-output associations remain deferred.
- Document configuration changes requiring API restart, operational logs, retention, and failure recovery. Update feature documentation to mark behavior implemented only after this milestone passes validation.

## Validation and acceptance

- Use JUnit through Spring Boot’s test support, MySQL Testcontainers, a controlled HTTP stub, and an injectable clock. Tests must not require real YouTube credentials.
- Verify clean migration startup, repeated startup, schema validation, persistence across container restarts, and failure on invalid database credentials.
- Test paginated discovery, repeated synchronization without duplicates, case-sensitive video IDs, changed and absent counts, unavailable/restored videos, partial failures, retries, and deadline handling.
- Test two competing job instances against one MySQL database: only one executes, failures release the lock, and abandoned locks expire.
- Test independent cleanup with missing credentials, exact thirty-day expiry, and exclusion of expired records from both endpoints.
- Test pagination, null ordering, UUID validation, 400/404/503 responses, UTC serialization, counts above JavaScript’s safe integer range, and `renderedOutputId: null`.
- Run Gradle `check` and `bootJar`, then a Compose smoke test confirming database/API health and expected behavior without YouTube configuration. Verify secrets are absent from Git, build context, image contents, and logs; finish with documentation-link checks and `git diff --check`.
