---
title: Greeting CLI
status: active
---

## OBJECTIVE

A one-file greeting script the docs team can call from their build.

## APPROACH

Plain bash, no dependencies. greet.sh takes a name argument and prints a greeting; flags extend behavior one at a time, each with a matching usage note in the script header.

## OPEN QUESTIONS

- [x] Q1: Does it need to handle multiple names per call?
    - RESOLUTION: No. One name per invocation; the build loops.
