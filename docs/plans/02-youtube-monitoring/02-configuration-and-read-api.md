# 02 — Configuration and read API

Status: not started.

Parent: [YouTube monitoring sub-phases](README.md). Depends on [schema and persistence](01-schema-and-persistence.md).

## Goal

Serve stored videos over the documented read API, and define the monitoring settings later jobs will use. This phase performs no YouTube HTTP.

## Work

- Add `YOUTUBE_API_KEY`, `YOUTUBE_CHANNEL_ID`, and `YOUTUBE_SYNC_INTERVAL` to API configuration, `.env.example`, and the Compose API service environment. Default the interval to `PT6H`.
- Treat a blank key, a blank channel id, or a non-positive interval as monitoring configuration disabled. The process still starts. Credentials stay in the environment, never in the database or logs.
- Bind the API and MySQL ports to localhost, as the foundation already does. Pass the YouTube API key only to the API service. Keep `MYSQL_ROOT_PASSWORD` on the MySQL service only.
- Add `controller`, `service`, and `dto` types. The service owns the transaction. Responses use a dedicated DTO, not the entity.
- `GET /api/youtube/videos?page=0&size=25` returns `items`, `page`, `size`, and `total`. Page is zero-based. Size is 1 through 100. Order by publication time descending, then internal id ascending, with null publication times last. Include available and unavailable rows for the configured channel whose `last_synced_at` is inside the retention window.
- `GET /api/youtube/videos/{id}` returns one unexpired row for the configured channel by internal UUID.
- JSON is camelCase. UUIDs and timestamps are strings. Timestamps are ISO 8601 UTC. Counts are decimal strings or null, including values above JavaScript's safe integer range. `durationSeconds` is a number or null. `watchUrl` is derived from the YouTube video id. `renderedOutputId` is present and null.
- Share one retention cutoff, `last_synced_at` at least 30 days before an injected clock, so phase 7 deletes the same rows these queries hide.
- Invalid page, size, or UUID returns 400. Unknown or expired id returns 404. Disabled monitoring configuration returns 503. Use Spring `ProblemDetail` for all three. A configured channel with no current rows returns an empty page.
- Leave Actuator health as it is: status only, database in readiness, liveness independent of MySQL.

## Validation

Seed rows through the repository or SQL. No YouTube credentials and no HTTP stub.

- Pagination boundaries, null publication ordering, and stable internal-id tie break.
- Detail hit, unknown UUID, expired row hidden from both endpoints.
- Count serialized as a decimal string above `2^53 - 1`, UTC timestamp format, and `renderedOutputId: null`.
- 400, 404, and 503 problem responses.
- Startup with monitoring variables unset still serves `/actuator/health/readiness`.
- `./gradlew check` from `api/`.

## Done when

The read contract matches the design for stored data, configuration is wired through Compose and `.env.example`, and synchronization, the YouTube client, and ShedLock are still absent.
