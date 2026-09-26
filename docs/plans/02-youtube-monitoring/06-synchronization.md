# 06 — Synchronization

Status: not started.

Parent: [YouTube monitoring sub-phases](README.md). Depends on [schema](01-schema-and-persistence.md), [configuration](02-configuration-and-read-api.md), [video lookup](04-video-lookup-and-mapping.md), and [timeouts and retries](05-timeouts-and-retries.md).

## Goal

One service method refreshes the configured channel: discover, look up, and commit. Scheduling and the database lock wrap this method in phase 7. Calling it directly from tests is enough here.

## Work

- When monitoring configuration is disabled, the method returns immediately and writes nothing.
- Resolve and paginate the uploads playlist through the phase 3 client. A failed discovery page stops the run. Ids that were never confirmed by a finished discovery pass are not marked unavailable. Videos already stored keep their counts, availability, `last_checked_at`, and `last_synced_at` when discovery fails before their lookup.
- Build the lookup set from discovered ids plus YouTube ids already stored for the configured channel. Look them up in batches of 50 through the phase 4 client.
- Commit each successful batch in its own transaction. Open that transaction only after the HTTP call returns. One batch commit:
  - Eligible videos upsert by `youtube_video_id`. Replace metadata and counts, set availability to `available`, and set both `last_checked_at` and `last_synced_at`. Preserve the internal UUID and `created_at` on update. There is no rendered-output column to preserve in this milestone.
  - Ineligible ids that already exist are marked `unavailable`. Keep their stored metadata and counts. Advance `last_checked_at` only.
  - Absent optional fields and absent statistics overwrite stored values with null. A smaller new count replaces a larger stored count.
  - Insert a row only for an eligible video. An unknown id omitted from YouTube creates nothing.
- A failed lookup batch commits nothing for those ids. Batches already committed stay committed. The next invocation can repeat discovery and upsert without creating a second row.
- Bound the invocation to thirty minutes using the injected clock. Check the deadline before each YouTube request, before each retry the client is about to wait for, and before each batch commit. Hitting the deadline stops the run, leaves the current uncommitted batch unchanged, and keeps earlier commits.
- Return a run summary the scheduler can log: discovered count, refreshed count, unavailable count, and a sanitized failure reason when the run stops early. Logging format and the scheduler are phase 7; the summary fields exist here so they can be unit-tested.

## Validation

Testcontainers MySQL plus the HTTP stub and the injected clock.

- Several playlist pages import public videos, skip non-public items, and store case-sensitive ids as distinct rows.
- A second invocation changes a title and a count, clears a count that the payload omits, decreases a count, and keeps the same internal id. It does not insert a duplicate.
- Omitting a stored id from a successful batch marks it unavailable without clearing counts or moving `last_synced_at`. A later response that includes it sets availability back to `available` and advances `last_synced_at`.
- Discovery failing on page two leaves stored rows unchanged and does not mark ids that might have appeared on later pages.
- A lookup failure on batch two keeps batch one's commit and leaves batch two's rows unchanged.
- The deadline stops the run between batches. A retry wait that would pass the deadline stops the run through the phase 5 policy.
- Disabled configuration performs no HTTP call and no write.
- `./gradlew check` from `api/`.

## Done when

The sync method passes the scenarios above when invoked directly. It is not yet scheduled, locked, or logged by the application runner.
