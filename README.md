# IOTA Video Manager

Iota Video Manager is a self-hosted system for turning footage into short/long videos. It is designed for a library of snowmobiling, off-roading, and snowboarding videos and photos. It will also monitor public YouTube uploads and display their current statistics. The Kotlin/Spring Boot API foundation is implemented with MySQL, Liquibase, health checks, and Docker Compose. The product workflows below remain planned.

## Run the API foundation

Copy `.env.example` to `.env`, set both database passwords, then run `docker compose up --build --wait` from the repository root. The API is available at `http://localhost:8080/actuator/health/readiness`, with MySQL on localhost port 3306.

See [API setup, development, and tests](api/README.md) and the [implementation roadmap](docs/plans/00-api-implementation-roadmap.md).

## What it will do

### Processing Videos

1. Import media from watched server folders and browser uploads.
2. Analyze videos to identify high-quality action scenes, including their timestamps, subjects, activity, setting, and visual quality.
3. Analyze photos and associate them with related video clips and adventures.
4. Build a searchable media catalog of clips, photos, metadata, and AI-derived tags.
5. Recommend complete YouTube Short and Instagram Reel drafts, including a hook, selected media, pacing, captions, title, hashtags, and soundtrack suggestion.
6. Let the creator approve, reject, or request edits to each proposed draft.
7. Render approved videos in a vertical 9:16 format and make the final MP4 and thumbnail available for download.
8. Trace every rendered output to the exact draft version, source assets, and scene time ranges used to create it.

### Monitor Videos

1. Discover one configured YouTube channel's public uploads, including videos created outside Iota.
2. Refresh video metadata and current view, like, and comment counts every six hours by default.
3. Show uploaded videos, their availability, and when their statistics were last refreshed.
4. Allow the data model to connect a YouTube upload to a local rendered output without requiring that connection.

See the [YouTube monitoring API design](docs/pages/api/youtube-monitoring.adoc) and [catalog ERD](docs/pages/diagrams/data/erd.adoc).

## Initial operating model

The system will run on an Ubuntu server with two 12 GB GPUs. GPU work will include media analysis, creative-draft generation, and final video rendering. The first release will use manual uploading: after reviewing a finished video, the creator downloads it and uploads it to YouTube Shorts or Instagram Reels.

The Kotlin Application API will use a server-side API key for read-only monitoring of public YouTube uploads. OAuth, private-video access, historical statistics, and YouTube Analytics are deferred. Future releases may integrate directly with YouTube and Instagram for publishing and scheduling.
