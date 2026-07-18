#!/usr/bin/env bash
set -euo pipefail

URL="${SYNC_URL:-https://example.internal/sync}"

attempt=1
while [ "$attempt" -le 3 ]; do
    if curl -fsS "$URL" -o /tmp/sync-payload.json; then
        echo "sync ok on attempt $attempt"
        exit 0
    fi
    echo "attempt $attempt failed" >&2
    attempt=$((attempt + 1))
done

echo "sync failed after 3 attempts" >&2
exit 1
