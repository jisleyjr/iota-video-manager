# Questions for the API implementation plan

Open questions from the review of `api-implementation-plan.md` (2026-09-09). Versions were verified against Maven Central and Gradle on the review date.

## Questions

1. **Reference project location.** The plan defers to "the CRM reference project" (Gradle DSL, catalog, configuration, migration organization, version pins) but never names it. What is its path or URL?

Answer: Removed this reference to a CRM project. What are the lines that you see that references at?

Review: The "CRM" name is gone, but two references remain — line 14 ("These follow the reference project and supported ... compatibility ranges") and line 16 ("Do not copy Bushel dependencies, plugins, packages, BIDL, private repositories, or remote Gradle scripts"). Decide whether to reword both or name the actual project.

2. **Version policy.** The pins are stale where they are not already latest: Kotlin 2.3.20 (latest 2.4.20, released 2026-09-07; 2.3.21 also exists) and ShedLock 7.10.0 (7.10.1 released 2026-09-08). Match the reference project exactly (document why), or take current latest (Kotlin 2.4.20, ShedLock 7.10.1)? Spring Boot 4.1.1 and Gradle 9.7.1 are already the current stable releases.

Answer: Use Shedlock 7.10.1, Kotlin 2.4.20

Review: The plan still pins Kotlin 2.3.20 (line 14) and ShedLock 7.10.0 (line 35). Update both to the decided versions.

3. **Case-sensitive video IDs.** MySQL 8's default collation (`utf8mb4_0900_ai_ci`) is case-insensitive, so a plain unique constraint on `youtube_video_id` would let `AbC123` and `abc123` collide. Which mechanism: `utf8mb4_bin` collation on the column and unique index, or store the ID as `VARBINARY`?

Answer: Is there another database like MariaDB, Postgresql, or others that would be a better option?

Review: The plan still uses MySQL 8.4 and specifies "case-sensitive comparison for YouTube IDs" (line 19) without naming the mechanism. On the database question: MySQL 8.4 is a sound choice — the collision is solved with a `utf8mb4_bin` collation (or `VARBINARY`) on the column, so there is no correctness reason to switch. Moving to PostgreSQL or MariaDB would rewrite the migrations, driver, compose service, and the "MySQL persistence" framing already in the plan and docs, for no functional gain. Recommend keeping MySQL and picking the column mechanism (`utf8mb4_bin` vs `VARBINARY`) explicitly.

4. **`YOUTUBE_CHANNEL_ID` format.** Accept only `UC…` channel IDs (regex-validated; anything else is an invalid-configuration 503), or also `@handles` (which need a resolution step; YouTube Data API v3 has no documented handle-lookup endpoint, so ID-only is the leaner option)?

Review: Still open. The plan defines `YOUTUBE_CHANNEL_ID` (line 44) but does not specify the accepted format or validation.

5. **Host port conflicts.** Compose publishes `127.0.0.1:3306` and `127.0.0.1:8080`. If anything already runs on 3306 or 8080 on the host, should the published ports be env-overridable in `docker-compose.yml` instead of fixed?

Answer: yes they should be overridable

Review: The plan still publishes fixed ports (line 42: "Publish the API at `127.0.0.1:8080` and MySQL at `127.0.0.1:3306`"). Update to make the published ports env-overridable.

6. **`api/README.md` update.** AGENTS.md requires documenting setup, build, run, and test commands when a module is scaffolded. The plan's documentation section should explicitly include updating `api/README.md`, which currently states no code exists yet.

Review: The plan's documentation section now says "Document setup, build, tests, host-run development, `docker compose up --build`, logs, shutdown, and persistence" (line 47), which covers setup/build/run/test. The remaining point is whether to name `api/README.md` explicitly.

7. **Root-level Dockerfile/compose.** Given `app/` and `processor/` will each become independently buildable modules later, is a root `Dockerfile` (building only the API) deliberate, or should it live at `api/Dockerfile` from the start?

Review: Still open. The plan currently specifies a root `Dockerfile` (line 41: "Add a root `Dockerfile`, `docker-compose.yml`, and `.dockerignore`") but the choice has not been confirmed.

## Context notes

- Docs needing the PostgreSQL-to-MySQL edit: `docs/pages/api/youtube-monitoring.adoc:7` and `:17`, and `docs/partials/diagrams/c4/model.dsl:50`. The sequence diagram's "synchronization lock" language is generic and needs no change.
- The plan's 503/400/404 semantics, retention rules, lock behavior, response envelope, and deferrals all match the design docs.
- Questions 1-4 affect plan content directly; 5-7 are scope confirmations.
