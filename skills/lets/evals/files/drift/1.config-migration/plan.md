---
title: Config schema migration
status: active
---

## OVERVIEW

Inventory what reads config first, then port the loader, so every call site is known before the format moves.

## TASKS

### T1 - Inventory config call sites
Establishes the blast radius before the loader changes.
- [x] Depends on: none
- [x] List every file that reads configuration values
- [x] Note which keys each site reads

### T2 - Port the YAML loader in app/config.sh to the new schema
The single point where the format changes.
- [ ] Depends on: T1
- [ ] Loader reads the nested schema
- [ ] Flat keys still resolve during the deprecation window
