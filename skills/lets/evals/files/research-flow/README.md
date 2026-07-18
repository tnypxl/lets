# sync tools

Nightly sync runs from cron. When a run fails, the on-call re-runs
`scripts/sync.sh` by hand; there is no automatic recovery beyond the
script's own attempts. The request timeout comes from app/config.json.
