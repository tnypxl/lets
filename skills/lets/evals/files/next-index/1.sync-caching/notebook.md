---
title: Sync caching
status: active
---

## OBJECTIVE

Cut redundant fetches in the nightly sync by caching unchanged payloads.

## APPROACH

Hash each payload on fetch and skip processing when the hash matches the previous run's. The cache is a flat file of hashes keyed by endpoint; no external store.

## OPEN QUESTIONS

- [x] Q1: Where does the hash file live?
    - RESOLUTION: Alongside the sync state dir, one file per environment.
