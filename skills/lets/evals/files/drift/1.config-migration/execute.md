---
title: Config schema migration
status: active
---

## LOG

### T1 - Inventory config call sites
`2026-07-02`
**Done**
- Searched the app tree for configuration reads

**Outcome** — app/config.sh is the only reader; app/main.sh consumes its exported values.

**Files touched**
- none
