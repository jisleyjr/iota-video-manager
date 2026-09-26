# 03 — Discovery client

Status: not started.

Parent: [YouTube monitoring sub-phases](README.md). Depends on the foundation HTTP stack. Can proceed in parallel with phases 1 and 2, and must finish before [synchronization](06-synchronization.md).

## Goal

Resolve one channel's uploads playlist and collect every public upload's video id. This phase covers the happy path and incomplete pagination. Timeouts, retries, and `videos.list` are the next client phases.

## Work

- Add a `client` type that calls the YouTube Data API v3 with a server-side key. The key is a request parameter or header held by the client, never written to logs or to the stored video row.
- `channels.list` with `part=contentDetails` and the configured channel id. Read `contentDetails.relatedPlaylists.uploads`. A missing channel or a missing uploads playlist is a failed discovery, not an empty channel.
- `playlistItems.list` with `part=contentDetails`, that playlist id, and `maxResults=50`. Follow every `nextPageToken` until the playlist is exhausted. Collect `contentDetails.videoId` only. Playlist item ids are not video ids.
- Return the ordered id list plus enough failure context for phase 6 to stop without marking undiscovered videos unavailable. A failure on a later page keeps the ids already collected on earlier pages available to the caller so the caller can decide what was fully discovered. Phase 6 defines that decision; this phase only reports which page failed.
- Introduce one local HTTP stub (JDK server or a test library already acceptable to the build) that later client phases reuse. Point the client at the stub base URL in tests.
- Keep connection and read timeouts finite in the client builder. Phase 5 sets them to five seconds and thirty seconds and owns the retry loop. This phase may call each URL once.

## Validation

Against the stub, with no MySQL required unless the module test slice already starts the context:

- A channel whose uploads playlist spans three pages returns every video id and ignores playlist item ids.
- The stub receives `maxResults=50` and the previous page's token on each follow-up request.
- An empty playlist returns an empty id list.
- A missing channel, a channel without an uploads playlist, and a non-success status on page two surface a discovery failure that still exposes ids committed from page one.
- Logs and assertions show the API key is not part of any log line emitted by the client.
- `./gradlew check` from `api/`.

## Done when

Discovery pagination is covered by the stub and the client does not upsert, schedule work, or call `videos.list`.
