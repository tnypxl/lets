---
title: Retry policy for sync.sh
status: active
---

## OBJECTIVE

Make scripts/sync.sh survive transient endpoint outages without hammering the endpoint.

## APPROACH

Replace the fixed three-attempt loop in scripts/sync.sh with exponential backoff plus jitter. Attempt count and base delay come from SYNC_MAX_ATTEMPTS and SYNC_BASE_DELAY, defaulting to the current behavior when unset. The backoff calculation moves into a small helper function inside sync.sh so the retry loop reads as policy, not arithmetic. The change is documented with the two variables and their defaults in a short usage comment at the top of the script.

## OPEN QUESTIONS

- [x] Q1: Should failures after the final attempt page anyone?
    - RESOLUTION: No. Exit nonzero and let cron's mail handle it, same as today.
