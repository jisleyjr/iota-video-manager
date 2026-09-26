# 08 — Documentation and release validation

Status: not started.

Parent: [YouTube monitoring sub-phases](README.md). Depends on phases 1 through 7.

## Goal

Record how to configure and operate the feature, then run the milestone checks that are awkward to express as a unit test. Update the design pages to say the feature is implemented only after those checks pass.

## Work

- Document `YOUTUBE_API_KEY`, `YOUTUBE_CHANNEL_ID`, and `YOUTUBE_SYNC_INTERVAL` in the API README and the root setup instructions: required values, the `PT6H` default, and that changing them requires an API restart.
- Document that a missing or invalid monitoring configuration still starts the API, serves health, runs retention, and makes both YouTube reads return 503.
- Document operational logs, the thirty-day retention rule, and failure recovery: transient errors retry inside a run, quota and configuration errors wait for the next scheduled run, a failed page or batch leaves earlier commits in place, and the next run upserts without duplicates.
- State that password and API-key changes in `.env` do not rewrite an existing MySQL volume, and that the YouTube key is not stored in MySQL.
- After validation, remove the planned-feature note from `docs/pages/api/youtube-monitoring.adoc` and align the roadmap entry. Describe behavior that this milestone actually ships. Leave rendered-output association, authentication, publishing, portal UI, and media processing described as future work.
- Confirm the C4, ERD, and sequence pages still match the implementation, including `renderedOutputId` always null and the deferred output foreign key.

## Validation

- `./gradlew check bootJar` from `api/`.
- Compose smoke without any YouTube variables: MySQL healthy, API readiness healthy, both video routes return the configuration 503, liveness stays healthy.
- A second smoke with stub-free configuration omitted is enough for this pass. A live YouTube call is not required.
- Recreate the API container and confirm MySQL rows from a fixture inserted during the smoke are still present. Confirm a non-root API process.
- Search the Git tree, Docker build context, image filesystem, and API logs for the sample API key and the database passwords used in the smoke.
- Check documentation links that the new README sections add, and run `git diff --check`.
- Re-run the phase 2 through 7 automated tests as part of `check` so the release bar includes pagination, retries, locks, and the thirty-day cutoff.

## Done when

The commands above pass, setup docs describe restart and recovery, and the parent plan plus the design page can be marked implemented.
