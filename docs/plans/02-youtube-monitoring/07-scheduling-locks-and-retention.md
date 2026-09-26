# 07 — Scheduling, locks, and retention

Status: not started.

Parent: [YouTube monitoring sub-phases](README.md). Depends on [schema](01-schema-and-persistence.md), [configuration and read API](02-configuration-and-read-api.md), and [synchronization](06-synchronization.md).

## Goal

Run synchronization and retention as two scheduled jobs. One MySQL database allows one active sync and one active cleanup across API instances, using ShedLock.

## Work

- Add ShedLock 7.10.1 and the JDBC provider to the version catalog and `api/build.gradle.kts`. ShedLock 7 supports Spring Boot 4. Use `usingDbTime()` against the `shedlock` table from phase 1.
- After application readiness, trigger one asynchronous synchronization, then run it on a fixed delay of `YOUTUBE_SYNC_INTERVAL`. Both entry points call the same proxied method so the lock annotation applies.
- Lock name for synchronization is distinct from cleanup. `lockAtMostFor` is one hour. Skip the run when the lock is already held. Release the lock on success and on failure. An abandoned lock older than its `lock_until` can be taken by the next instance.
- The sync method's thirty-minute bound remains inside the lock. The lock is the cross-instance guard; the deadline is the single-run guard.
- Delete rows whose `last_synced_at` is at least 30 days before the injected clock. Use the same cutoff phase 2 applies to both read endpoints. Run cleanup at startup and every hour. Cleanup runs when the YouTube key or channel id is missing. It deletes only `youtube_video` rows.
- Give synchronization and cleanup separate scheduler capacity so a long sync cannot hold the hourly cleanup behind it.
- Log each run's start, end, duration, discovered count, refreshed count, unavailable count, expired-delete count, and sanitized failure reason. Do not log the API key, request URLs that contain the key, or response payloads.
- Disabled monitoring configuration skips synchronization and still runs cleanup. Read endpoints continue to return the phase 2 configuration 503 when configuration is disabled.

## Validation

- Two application contexts against one MySQL container: overlapping sync invocations result in one execution. The loser skips.
- A sync that throws releases the lock so the next invocation runs.
- A lock row whose `lock_until` is in the past is taken by a later invocation.
- Cleanup with no YouTube configuration deletes rows at the thirty-day boundary and leaves a row one second newer. Both read endpoints omit the deleted and the boundary row.
- Cleanup and a blocked sync lock do not block each other.
- Log capture for a failed run contains the sanitized reason and does not contain the API key or a response body.
- Actuator liveness and readiness stay as they were in the foundation.
- `./gradlew check` from `api/`.

## Done when

Startup scheduling, the interval, ShedLock, and retention behave as the parent plan describes. Release documentation and the Compose smoke test are phase 8.
