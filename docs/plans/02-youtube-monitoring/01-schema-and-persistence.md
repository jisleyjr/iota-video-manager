# 01 — Schema and persistence

Status: not started.

Parent: [YouTube monitoring sub-phases](README.md). Requirements: [database changes](../02-api-youtube-monitoring-plan.md).

## Goal

Add the two business tables and the JPA mapping that later phases read and write. Application startup still runs Liquibase, then Hibernate validates the schema.

## Work

- Append immutable, explicitly ordered YAML changesets to `api/src/main/resources/db/changelog/db.changelog-master.yml`. Keep the existing empty changelog history intact.
- Create `youtube_video` with the ERD columns except `rendered_output_id`. That column and its foreign key wait for a later milestone.
- Use a UUID primary key. Store `youtube_video_id` with a case-sensitive collation and a unique constraint. Index the channel-list order (`youtube_channel_id`, publication time, internal id) and the expiry lookup (`last_synced_at`).
- Map nullable title, description, thumbnail URL, publication time, decimal duration, and nullable view, like, and comment counts. Availability is `available` or `unavailable`. Timestamps are UTC instants: `created_at`, `last_checked_at`, `last_synced_at`.
- Create `shedlock` with the ShedLock JDBC columns (`name`, `lock_until`, `locked_at`, `locked_by`) and a primary key on `name`. The dependency and lock manager arrive in phase 7.
- Add `entity` and `repository` types under `com.iota.videomanager.api`. Constructor injection, no open session in view, `ddl-auto: validate` unchanged.
- Repository queries needed by later phases can land with the entity: find by YouTube video id, list stored ids for a channel, and page unexpired rows. Expiry comparison itself is defined in phase 2 so reads and deletes share one cutoff.

## Validation

- Testcontainers MySQL 8.4. Clean startup creates `youtube_video`, `shedlock`, and the Liquibase bookkeeping tables.
- A second startup applies no further changes and Hibernate validation succeeds.
- Insert two ids that differ only by case and confirm both rows persist.
- Confirm the unique video-id constraint rejects a true duplicate.
- `./gradlew check` from `api/`.

## Done when

Migrations and the entity/repository compile, the tests above pass, and no YouTube endpoint, client, scheduler, or ShedLock dependency has been added.
