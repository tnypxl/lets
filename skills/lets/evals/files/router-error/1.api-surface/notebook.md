---
title: Public API surface
status: active
domain: api-design
---

## OBJECTIVE

Decide which endpoints the v2 API exposes and freeze their shapes.

## APPROACH

Start from the endpoints v1 clients actually call, drop the rest, and version the survivors under /v2 with explicit response schemas.

## OPEN QUESTIONS

- [ ] Q1: Do we keep the batch endpoint or split it?
