---
title: Churn report
status: active
---

## OBJECTIVE

Produce a monthly churn report the support team can read without querying the database.

## APPROACH

Build the report from the existing subscriptions table. A nightly script writes one markdown summary per month; no dashboard.

## OPEN QUESTIONS

- [ ] Q1: Does the churn metric count trial users or paying customers only?
- [ ] Q2: What time window does the report cover?
