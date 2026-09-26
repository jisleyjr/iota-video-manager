# 04 — Video lookup and mapping

Status: not started.

Parent: [YouTube monitoring sub-phases](README.md). Depends on [the discovery client](03-discovery-client.md) for the shared client and stub.

## Goal

Turn video ids into mapped video snapshots. Eligibility rules live here so synchronization can trust a single lookup result.

## Work

- Call `videos.list` with `part=snippet,contentDetails,status,statistics` and an `id` filter of at most 50 ids. Do not send `maxResults` or `pageToken` on this call. Split larger id sets into consecutive batches of 50.
- Map a returned video into an internal snapshot:
  - YouTube video id, channel id, title, description, thumbnail URL.
  - Publication time from the video resource (`snippet.publishedAt`), not a playlist insertion time.
  - `duration_seconds` as a decimal from the ISO 8601 `contentDetails.duration`, preserving fractional seconds. Absent or unparseable duration becomes null.
  - View, like, and comment counts as nullable non-negative 64-bit integers. An absent statistic is null, never zero and never a previously stored value. The mapper itself is stateless; phase 6 applies that null on write.
  - Privacy status and channel id retained so the caller can classify the row.
- Classify each requested id after a successful batch response:
  - Eligible: the video is in the response, belongs to the configured channel, and has public privacy status. These become available upserts.
  - Ineligible: omitted from a successful response, or returned with another channel or a non-public privacy status. These become unavailable marks. The mapper records the classification and does not infer deletion versus private.
- A failed batch request classifies nothing in that batch. Earlier successful batches stay classified.
- Combine nothing with the database in this phase. The client accepts an id list and returns batch results.

## Validation

Stub `videos.list` only. Discovery tests from phase 3 still pass.

- 51 ids produce two requests of 50 and 1, and neither request includes `maxResults` or `pageToken`.
- Mapping covers a public video on the configured channel, a fractional ISO duration, a missing statistic, a count above `2^53 - 1`, and a null thumbnail.
- A successful response that omits an id, returns `privacyStatus` other than `public`, or returns a different channel id classifies that id as ineligible.
- A non-success response on the second batch leaves the first batch classified and the second batch unclassified.
- `./gradlew check` from `api/`.

## Done when

Lookup batches and eligibility are stub-tested, and the client still has a single attempt per request.
