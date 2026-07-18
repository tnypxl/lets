---
title: Usage reporting
status: active
---

## OBJECTIVE

Give account managers a monthly usage report they can hand to customers.

## APPROACH

Define the report schema first, then a query layer that fills it from the events table, then renderers on top. HTML is the primary output; a CSV export of the same rows follows so customers can load the data into their own tools. Renderers share the query layer and never query directly.

## OPEN QUESTIONS

- [x] Q1: One report per account or per workspace?
    - RESOLUTION: Per account. Workspaces roll up.
