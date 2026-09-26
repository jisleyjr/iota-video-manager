# YouTube monitoring sub-phases

Status: not started. Parent requirements stay in [the YouTube monitoring plan](../02-api-youtube-monitoring-plan.md). Behavior stays in the [YouTube monitoring design](../../pages/api/youtube-monitoring.adoc) and the [`YOUTUBE_VIDEO` record](../../pages/diagrams/data/erd.adoc).

Implement the phases in order. Each phase is mergeable on its own: its tests pass with MySQL Testcontainers and, once the client exists, a local HTTP stub. Tests never call YouTube or require a real API key.

Schema and stored reads are small because Liquibase, Hibernate validation, and the health endpoints already exist. The YouTube HTTP work is split into three phases so pagination, field mapping, and retry policy can be proven before any job writes the database.

| Order | Phase | Depends on | Delivers |
| --- | --- | --- | --- |
| 1 | [Schema and persistence](01-schema-and-persistence.md) | API foundation | `youtube_video` and `shedlock` migrations, entity, repository |
| 2 | [Configuration and read API](02-configuration-and-read-api.md) | 1 | Env config, list/detail endpoints, expiry filter on reads |
| 3 | [Discovery client](03-discovery-client.md) | Foundation HTTP stack | Channel uploads playlist, full page walk, video IDs only |
| 4 | [Video lookup and mapping](04-video-lookup-and-mapping.md) | 3 | Batches of 50, public-channel eligibility, field mapping |
| 5 | [Timeouts and retries](05-timeouts-and-retries.md) | 3, 4 | Shared attempt policy for every YouTube call |
| 6 | [Synchronization](06-synchronization.md) | 1, 2, 4, 5 | Per-batch commits, unavailable marking, thirty-minute bound |
| 7 | [Scheduling, locks, and retention](07-scheduling-locks-and-retention.md) | 1, 2, 6 | ShedLock, startup and interval runs, hourly delete |
| 8 | [Documentation and release validation](08-documentation-and-release-validation.md) | 1–7 | Setup docs, Compose smoke, design pages marked implemented |

Later product work stays outside this milestone: rendered-output column and foreign key, output-association editing, authentication, publishing, the portal UI, and media processing. Responses still include `renderedOutputId` and always return null.

Mark a phase `in progress` or `done` in its own file when work starts or its validation section passes. Leave the parent plan status as planned until phase 8 passes.
