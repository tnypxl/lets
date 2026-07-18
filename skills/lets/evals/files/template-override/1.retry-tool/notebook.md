---
title: Retry tool
status: active
workflow: golang
---

## OBJECTIVE

A command-line tool that retries a failing command with exponential backoff until it succeeds or a budget is exhausted.

## APPROACH

A single `main` package wrapping `os/exec`: parse flags (attempts, base delay, max elapsed), run the command, classify exit codes, and back off with jitter between attempts. Ship as one binary with table-driven tests over the backoff schedule.

Deliverable: tool — the `retry` command-line binary.

## OPEN QUESTIONS

- [x] Q1: Configuration file or flags only?
    - RESOLUTION: Flags only; the tool is small enough that a config file adds surface without value.
