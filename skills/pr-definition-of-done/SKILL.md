---
name: pr-definition-of-done
description: Use when preparing a pull request for review or when CI checks fail. Checklist covering commit conventions, Dockerfile linting, formatting rules, security, and all CI checks that run on PRs.
---

# PR Definition of Done

## Overview

Every PR to this repo triggers GitHub Actions workflows (hadolint, agentready) and a Tekton build pipeline (hermetic image build + security scans + integration test). This checklist covers what CI enforces and what reviewers expect.

## When to Use

- Before pushing a PR for review
- When CI checks fail and you need to understand why
- When reviewing someone else's PR

## Pre-Push Checklist

### Commits
- [ ] Conventional format: `type(JIRA-ID): description` (e.g., `fix(STONEINTG-1644): update jq version`)
- [ ] Types: `feat`, `fix`, `chore`, `refactor`, `test`, `docs`
- [ ] Signed off (DCO): `git commit -s`
- [ ] Title < 72 chars, description lines < 72 chars
- [ ] AI-assisted work: add `Assisted-by: <tool-name>` trailer

### Dockerfile
- [ ] Well-formatted, no unnecessary layers
- [ ] Passes hadolint (DL3041 is ignored — `microdnf` usage is expected)
- [ ] Package versions match `rpms.lock.yaml` pins exactly
- [ ] No secrets, keys, or credentials
- [ ] Single `RUN` for package installation to minimize layers

### Code Formatting
- [ ] No whitespace changes to unrelated code
- [ ] No whitespace or tabs on empty lines
- [ ] Exactly one newline at the end of the file (no extra blank lines)
- [ ] No removal of unrelated code or unnecessary file changes

### Dependency Changes
- [ ] `rpms.in.yaml`, `rpms.lock.yaml`, and `artifacts.lock.yaml` are in sync
- [ ] Dockerfile version strings match lock file pins
- [ ] Checksums verified for any new artifacts

### Security
- [ ] No secrets, API keys, or credentials committed
- [ ] No sensitive information in commit messages or PR description

### PR Content
- [ ] Title: clear, descriptive, < 72 chars
- [ ] Description explains the "why", not just the "what"
- [ ] Testing approach described
- [ ] Related issues or Jira tickets linked

## CI Checks That Run on PRs

### GitHub Actions

| Workflow | File | What It Checks |
|----------|------|----------------|
| Dockerfile linter | `.github/workflows/linters.yaml` | hadolint on `Dockerfile` (ignores DL3041) |
| Agentready | `.github/workflows/agentready.yaml` | AI-readiness assessment of repo structure |

### Tekton Pipeline (`.tekton/clair-in-ci-db-hermetic-pull-request.yaml`)

| Phase | Tasks |
|-------|-------|
| Build | init → clone → fetch-db-data → prefetch → build-container → build-image-index |
| Security scans | clair-scan, clamav-scan, sast-snyk-check, sast-shell-check, sast-unicode-check, sast-coverity-check, rpms-signature-scan, ecosystem-cert-preflight-checks, deprecated-base-image-check |
| Finalize | show-sbom, apply-tags, push-dockerfile |

### Integration Test (`integration-tests/clair_validation.yaml`)

Runs automatically after the Tekton build pipeline succeeds:
1. Extracts container image from Snapshot
2. Runs hadolint on the Dockerfile source
3. Runs `clair-action report` against `registry.access.redhat.com/ubi9-minimal` using the built image
4. Validates output contains valid vulnerability data (named Features with Vulnerabilities)

### PR Image Behavior
- Tag: `on-pr-{{revision}}`
- Expires after: 5 days
- Cancel in-progress: yes (new push cancels previous PR pipeline)
- Max kept: 3 pipeline runs

## CODEOWNERS

All files are owned by the integration-service team. Reviews are automatically requested based on the `.github/CODEOWNERS` file.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| hadolint fails | Check Dockerfile syntax; DL3041 is ignored but other rules apply |
| Pipeline timeout | fetch-db-data has 2h timeout and needs 16-32 GiB — this is expected for large DB updates |
| Checksum mismatch in prefetch | Lock files are out of sync — regenerate `rpms.lock.yaml` and `artifacts.lock.yaml` |
| Integration test fails | Built image can't scan ubi9-minimal — check that matcher.db was correctly built into the image |
| Commit not signed off | Use `git commit -s` or amend with `git commit --amend -s` |