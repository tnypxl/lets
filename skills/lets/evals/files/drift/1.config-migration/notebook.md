---
title: Config schema migration
status: active
---

## OBJECTIVE

Move the app's configuration to the new nested schema without breaking existing deployments.

## APPROACH

The app reads YAML config through the loader in app/config.sh. Port that YAML loader to the new nested schema in place, keeping the flat keys readable during a deprecation window so deployments migrate on their own schedule.

## OPEN QUESTIONS

- [x] Q1: How long is the deprecation window?
    - RESOLUTION: Two releases.
