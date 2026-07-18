---
title: Usage reporting
status: active
---

## OVERVIEW

Schema first, then the query layer that fills it, then renderers on top. Each renderer consumes the query layer, never the events table directly.

## TASKS

### T1 - Define report schema
Fixes the row shape every downstream task builds against.
- [x] Depends on: none
- [x] List the columns with types and one example row
- [x] Review the schema with an account manager

### T2 - Build query layer
Fills the schema from the events table so renderers stay dumb.
- [ ] Depends on: T1
- [ ] Write the aggregation query producing one row per account per month
- [ ] Add a fixture-backed test for a known month

### T3 - Render HTML report
The primary customer-facing output.
- [ ] Depends on: T2
- [ ] Render the query rows into the report template
- [ ] Check the output against the example row from the schema
