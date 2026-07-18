---
title: Retry policy for sync.sh
status: active
---

## OBJECTIVE

Make scripts/sync.sh survive transient endpoint outages without hammering the endpoint.

## APPROACH

Draft: replace whatever retry behavior exists today with exponential backoff. How retries, timeouts, and failure handling currently work across the project has not been confirmed; the approach commits once that is known.

## OPEN QUESTIONS

- [ ] Q1: Where does retry behavior live today, and is it consistent across entry points?
