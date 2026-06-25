---
name: daily-db-update
description: Use when troubleshooting the automated daily vulnerability database update, understanding the build trigger flow, or debugging fetch-db-data failures. Covers the GitHub Actions cron, push pipeline, matcher.db lifecycle, and manual triggering.
---

# Daily Database Update

## Overview

The entire purpose of this repo is to keep the Clair vulnerability database fresh. A GitHub Actions cron job runs daily at ~04:00 UTC, pushes an empty commit to `main`, which triggers the Tekton push pipeline. The pipeline's `fetch-db-data` step downloads the latest vulnerability database (`matcher.db`) from upstream Clair sources, and the Dockerfile bakes it into the container image.

## When to Use

- The daily build didn't run or failed
- `fetch-db-data` is failing (OOM, timeout, network)
- You need to manually trigger a database update
- You need to understand why the image has stale vulnerability data
- The integration test fails after a DB update

## Daily Update Flow

```
GitHub Actions cron (04:00 UTC daily)
  │
  ├─ .github/workflows/trigger-clair-db-build.yaml
  │    └─ Checks out main
  │    └─ Creates empty commit: git commit --allow-empty -m "$(date)"
  │    └─ Force pushes to main
  │
  ▼
PAC detects push to main
  │
  ├─ Triggers .tekton/clair-in-ci-db-hermetic-push.yaml
  │
  ▼
Tekton Push Pipeline
  │
  ├─ clone-repository
  ├─ fetch-db-data (NON-HERMETIC)
  │    └─ DB_PATH=matcher.db /bin/clair-action --level info update
  │    └─ Downloads latest vulnerability data from upstream sources
  │    └─ Produces matcher.db as part of SOURCE_ARTIFACT
  ├─ prefetch-dependencies (hermetic RPM + generic artifacts)
  ├─ build-container (hermetic)
  │    └─ Dockerfile: COPY matcher.db /tmp/matcher.db
  │    └─ ENV DB_PATH=/tmp/matcher.db
  ├─ security scans (clair, clamav, snyk, etc.)
  └─ integration test (clair_validation.yaml)
       └─ Scans ubi9-minimal with the new image
       └─ Verifies valid vulnerability data in output
```

## fetch-db-data Details

This is the most critical and failure-prone step in the entire pipeline.

| Property | Value |
|----------|-------|
| Task bundle | `run-script-oci-ta:0.1` |
| Runner image | `quay.io/projectquay/clair-action:v0.0.15` |
| Command | `DB_PATH=matcher.db /bin/clair-action --level info update` |
| Hermetic | **No** — explicitly set `HERMETIC: "false"` |
| CPU | 2 cores request, 4 cores limit |
| Memory | 16 GiB request, 32 GiB limit |
| Timeout | 2 hours |

Why non-hermetic: The vulnerability database must be downloaded from live upstream sources (NVD, Red Hat, etc.) at build time. This is the only step in the pipeline that has network access — all other steps run hermetically.

## Manual Trigger

To manually trigger a database update outside the daily schedule:

1. **Via GitHub UI**: Go to Actions → "Trigger clair db image build" → "Run workflow" (uses `workflow_dispatch`)
2. **Via CLI**: `gh workflow run trigger-clair-db-build.yaml`

Both trigger the same flow: empty commit to main → PAC push pipeline.

## Push Pipeline Specifics

| Property | Value |
|----------|-------|
| File | `.tekton/clair-in-ci-db-hermetic-push.yaml` |
| Image tag | `{{revision}}` (commit SHA) |
| Image expiry | None (permanent) |
| Cancel in-progress | No (`"false"`) — each build runs to completion |
| Output registry | `quay.io/redhat-user-workloads/rhtap-integration-tenant/clair-in-ci-db-hermetic` |
| Service account | `build-pipeline-clair-in-ci-db-hermetic` |

## Integration Test Validation

After the push pipeline builds the image, the integration test (`integration-tests/clair_validation.yaml`) validates it:

```bash
clair-action report \
  --image-ref=registry.access.redhat.com/ubi9-minimal \
  --db-path=/tmp/matcher.db \
  --format=quay > clairdata.json

jq -e '.data[].Features[0] | select(has("Name") and has("Vulnerabilities")) \
  or error("Required keys do not exist")' clairdata.json
```

This confirms the image can actually scan containers and produce valid vulnerability data with the embedded database.

## Troubleshooting

| Symptom | Likely Cause | Action |
|---------|-------------|--------|
| Daily build didn't trigger | GH Actions cron didn't fire or failed | Check Actions tab; manually trigger via workflow_dispatch |
| fetch-db-data OOM killed | Vulnerability DB processing exceeds 32 GiB | Check clair-action upstream for memory regression; may need limit increase |
| fetch-db-data timeout (>2h) | Slow network or very large DB update | Retry; check upstream Clair for known issues |
| fetch-db-data network error | Upstream vulnerability sources unreachable | Transient — retry; check NVD/Red Hat feed status |
| Integration test fails | matcher.db is corrupt or incomplete | Check fetch-db-data logs for partial download or processing errors |
| Image has stale vuln data | Daily build failing silently | Check push pipeline run history in Konflux dashboard |
| Empty commit push rejected | Branch protection or permission issue | Verify the GH Actions token has `contents: write` permission |

## Monitoring

To check if daily updates are working:

1. **GitHub Actions**: Check the "Trigger clair db image build" workflow runs for daily execution
2. **Konflux dashboard**: Check push PipelineRun history for `clair-in-ci-db-hermetic-on-push`
3. **Quay.io**: Check `quay.io/redhat-user-workloads/rhtap-integration-tenant/clair-in-ci-db-hermetic` for recent image tags
4. **Git log**: `git log --oneline main` — should show daily empty commits from "daily-build-trigger"
