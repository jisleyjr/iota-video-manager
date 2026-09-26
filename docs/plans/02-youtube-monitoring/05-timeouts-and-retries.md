# 05 — Timeouts and retries

Status: not started.

Parent: [YouTube monitoring sub-phases](README.md). Depends on [discovery](03-discovery-client.md) and [video lookup](04-video-lookup-and-mapping.md).

## Goal

Put one attempt policy around every YouTube call the client makes: channel resolution, each playlist page, and each video batch.

## Work

- Set a five-second connection timeout and a thirty-second request timeout on the Spring REST client.
- Allow at most three total attempts for a timeout, HTTP 429, or HTTP 5xx. Wait with exponential backoff plus jitter between attempts.
- Honor `Retry-After` when present. An injected clock and sleeper keep the tests fast. If the delay would run past a caller-supplied deadline, stop and return that the run should end. Phase 6 passes the synchronization deadline; this phase accepts the deadline as an argument and uses "no deadline" in unit tests that only check the retry count.
- Quota exhaustion, invalid credentials, invalid request configuration, and other non-transient 4xx responses fail immediately with a reason safe to log. Do not retry them. The reason must not include the API key, the request URL if it carries the key, or the response body.
- Retrying a playlist page or video batch retries that request only. Successful earlier pages and batches stay successful.
- Surface a distinct outcome for "stop this run" versus "this request failed transiently and attempts are exhausted" so phase 6 can keep stored rows unchanged.

## Validation

Use the existing stub. Advance an injected clock instead of sleeping wall-clock backoff.

- Timeout, 429, and 500 each succeed on the third attempt and do not make a fourth call.
- A third failure returns an exhausted transient failure and leaves any prior successful page or batch intact.
- `Retry-After` longer than the supplied deadline stops the run without another attempt.
- Quota, 401, and 403 configuration failures perform one attempt and return a sanitized reason.
- Discovery and lookup tests from phases 3 and 4 still pass with the policy enabled, including the happy path's single attempt.
- `./gradlew check` from `api/`.

## Done when

The client policy matches the design's failure section and synchronization can depend on it without embedding its own retry loop.
