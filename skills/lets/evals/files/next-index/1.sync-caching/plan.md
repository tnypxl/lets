---
title: Sync caching
status: locked
---

## OVERVIEW

Hashing first, then the skip path, so the cache exists before anything consults it.

## TASKS

### T1 - Hash payloads on fetch
Creates the cache the skip path reads.
- [x] Depends on: none
- [x] Each fetched payload's hash is written to the cache file

### T2 - Skip processing on hash match
The payoff: unchanged payloads cost one hash lookup.
- [x] Depends on: T1
- [x] A rerun against unchanged payloads processes zero of them
