---
name: ci-pipeline-debugging
description: Use when a Tekton build pipeline fails, when you need to understand task ordering or resource requirements, or when debugging security scan failures. Covers PR and push pipeline differences, the fetch-db-data step, and all security scan tasks.
---

# CI Pipeline Debugging

## Overview

This repo has two Tekton PipelineRun definitions in `.tekton/`: one for pull requests and one for pushes to main. Both are hermetic builds using trusted artifacts (OCI TA) with Cachi2 prefetching. The most critical and failure-prone step is `fetch-db-data`, which downloads the Clair vulnerability database and needs 16-32 GiB of memory.

## When to Use

- A Tekton pipeline task failed and you need to understand what it does
- You need to understand the task execution order
- The `fetch-db-data` step is failing (OOM, timeout, network)
- A security scan is blocking the pipeline
- You need to understand PR vs push pipeline differences

## Task Execution Order

```
init
  └─ clone-repository
       └─ fetch-db-data (non-hermetic, downloads matcher.db)
            └─ prefetch-dependencies (RPMs + generic artifacts via Cachi2)
                 └─ build-container (buildah, hermetic)
                      └─ build-image-index
                           ├─ clair-scan
                           ├─ clamav-scan
                           ├─ sast-snyk-check
                           ├─ sast-shell-check
                           ├─ sast-unicode-check
                           ├─ coverity-availability-check → sast-coverity-check
                           ├─ ecosystem-cert-preflight-checks
                           ├─ deprecated-base-image-check
                           ├─ rpms-signature-scan
                           ├─ apply-tags
                           ├─ push-dockerfile
                           └─ build-source-image (push only)
finally:
  └─ show-sbom
```

## PR vs Push Pipeline Differences

| Aspect | PR Pipeline | Push Pipeline |
|--------|------------|---------------|
| File | `.tekton/clair-in-ci-db-hermetic-pull-request.yaml` | `.tekton/clair-in-ci-db-hermetic-push.yaml` |
| Trigger | `event == "pull_request" && target_branch == "main"` | `event == "push" && target_branch == "main"` |
| Image tag | `on-pr-{{revision}}` | `{{revision}}` |
| Image expiry | 5 days | None (permanent) |
| Cancel in-progress | Yes | No |
| Max kept runs | 3 | 3 |
| Source image build | No | Yes (when enabled) |
| Pipeline timeout | 2 hours | 2 hours |

## fetch-db-data Step (Most Common Failure Point)

This step downloads the latest Clair vulnerability database. It is the most resource-intensive and failure-prone task.

| Property | Value |
|----------|-------|
| Task | `run-script-oci-ta` |
| Runner image | `quay.io/projectquay/clair-action:v0.0.15` |
| Command | `DB_PATH=matcher.db /bin/clair-action --level info update` |
| Hermetic | **No** (needs network access to download DB) |
| CPU request/limit | 2 / 4 cores |
| Memory request/limit | 16 GiB / 32 GiB |
| Timeout | 2 hours |

The output artifact (`SCRIPT_ARTIFACT`) is passed to `prefetch-dependencies`, which means the `matcher.db` file is included in the source artifact chain and eventually available during the `build-container` step where the Dockerfile `COPY matcher.db /tmp/matcher.db` picks it up.

## Resource Requirements

Most tasks request 10 GiB memory. Key allocations:

| Task | Memory (request/limit) | Notes |
|------|----------------------|-------|
| fetch-db-data | 16 GiB / 32 GiB | Database download + processing |
| build-container | 10 GiB / 10 GiB | buildah image build |
| prefetch-dependencies | 10 GiB / 10 GiB | Cachi2 RPM + generic artifact download |
| clair-scan | 10 GiB / 10 GiB | Vulnerability scanning of built image |
| clamav-scan | 10 GiB / 10 GiB | Antivirus scan |

## Security Scan Tasks

All scans run in parallel after `build-image-index` and can be skipped with `skip-checks: "true"`:

| Scan | Task Bundle | What It Checks |
|------|------------|----------------|
| Clair | `task-clair-scan:0.3` | CVE vulnerabilities in container image |
| ClamAV | `task-clamav-scan:0.3` | Malware/virus scan |
| Snyk SAST | `task-sast-snyk-check-oci-ta:0.4` | Static analysis security testing |
| ShellCheck | `task-sast-shell-check-oci-ta:0.1` | Shell script security and quality |
| Unicode | `task-sast-unicode-check-oci-ta:0.4` | Homoglyph/trojan-source attacks |
| Coverity | `task-sast-coverity-check-oci-ta:0.3` | Deep static analysis (if available) |
| RPM signatures | `task-rpms-signature-scan:0.2` | Verifies RPM package signatures |
| Preflight | `task-ecosystem-cert-preflight-checks:0.2` | Red Hat certification checks |
| Deprecated image | `task-deprecated-image-check:0.5` | Base image deprecation warnings |

## Common Failures

| Problem | Likely Cause | Fix |
|---------|-------------|-----|
| fetch-db-data OOM killed | Database processing exceeds memory | Check if clair-action version needs more memory; may need to increase limits |
| fetch-db-data timeout | Network slow or database very large | Retry; check clair-action upstream for issues |
| prefetch-dependencies fails | Lock files out of sync with rpms.in.yaml | Regenerate `rpms.lock.yaml` and `artifacts.lock.yaml` |
| build-container fails | Dockerfile error or missing prefetched deps | Check Dockerfile syntax; verify all deps are in lock files |
| clair-scan fails | High/critical CVEs found in built image | Review CVE report; update base image or add exceptions |
| rpms-signature-scan fails | Unsigned or incorrectly signed RPM | Verify RPM source and GPG key in artifacts.lock.yaml |
| Pipeline stuck at coverity | Coverity not available in tenant | Expected — coverity-availability-check gates it |

## Trusted Artifacts (OCI TA)

This pipeline uses OCI-based trusted artifacts instead of PVCs for sharing data between tasks:
- Source code is stored as OCI artifacts in the output image registry
- `SOURCE_ARTIFACT` results chain through: clone → fetch-db-data → prefetch → build
- `CACHI2_ARTIFACT` carries prefetched dependencies from prefetch → build
- Artifacts expire based on `ociArtifactExpiresAfter` (PR: 5 days, push: never)
