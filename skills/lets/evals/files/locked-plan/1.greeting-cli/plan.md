---
title: Greeting CLI
status: locked
---

## OVERVIEW

Skeleton first, then flags one at a time so each lands with its own check.

## TASKS

### T1 - Create greet.sh skeleton
Establishes the file, argument handling, and default output everything else extends.
- [x] Depends on: none
- [x] greet.sh takes an optional name argument, defaulting to world
- [x] `bash greet.sh alice` prints `hello, alice`

### T2 - Add --shout flag to greet.sh
Lets the build emphasize release-day greetings.
- [x] Depends on: T1
- [x] `bash greet.sh --shout alice` prints `HELLO, ALICE`
- [x] Without the flag, output is unchanged
