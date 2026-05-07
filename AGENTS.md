# AGENTS.md
## Overview

This repository contains a containerized [Clair](https://quay.github.io/clair/) vulnerability scanner designed for use in Konflux CI/CD pipelines. It builds a Docker image that includes the [clair-in-ci](https://github.com/quay/clair-action) utility for scanning container images and artifacts in CI/CD environments and reports on found [image CVEs](https://access.redhat.com/articles/red_hat_vulnerability_tutorial).

## Technology Stack

- **Language**: bash, Dockerfile
- **Pipeline engine**: Tekton PipelineRuns
- **Testing**: Tekton pipelines, GitHub actions
- **Build**: Dockerfile, Tekton build pipelines

## Repository Structure

```
integration-tests/     # Tekton pipeline and task definitions for running integration and e2e tests
rpms.in.yaml           # RPM dependency declaration (jq)
rpms.lock.yaml         # Pinned RPM versions and checksums for hermetic builds
artifacts.lock.yaml    # Pinned generic artifact checksums (EPEL GPG key, RPMs)                                
Dockerfile             # Container image definition 
```

## Architecture

### Clair Vulnerability Scanner

The image is meant to be used as part of the [clair-scan](https://github.com/konflux-ci/konflux-test-tasks/tree/main/task/clair-scan) Konflux CI Tekton task.
It is meant to provide the latest available version of the `clair-in-ci` utility with updated vulnerability database contained within it. See more details in `README.md`.

### Automated updates

A GitHub Actions cron job (.github/workflows/trigger-clair-db-build.yaml) runs daily at ~04:00 UTC, pushing an empty commit to main. This triggers the Tekton push pipeline (.tekton/clair-in-ci-db-hermetic-push.yaml), which runs the fetch-db-data step to download the latest vulnerability database via clair-action update. The resulting matcher.db is then baked into the container image.

Note: the fetch-db-data step requires 16-32 GiB of memory and has a 2-hour timeout, making it the most resource-intensive and failure-prone part of the pipeline.

### Integration Testing

The integration test pipeline (`integration-tests/clair_validation.yaml`) validates the built image by running a Clair scan against `registry.access.redhat.com/ubi9-minimal` using the embedded `matcher.db`. It verifies that the output contains valid vulnerability data with named features and vulnerabilities. This test runs automatically on both PR and push pipelines.

## Development Guidelines

- See `CONTRIBUTING.md` for overall guidelines for making contributions to this repository.
- **Git**: conventional commits with Jira ticket as scope — `type(issue-id): description` (e.g. `feat(STONEINTG-1519): create PR group snapshots from ComponentGroups`)
    - The `main` branch is read only, never push there directly, a new feature branch must be created instead
    - Pull requests are used to propose changes to the `main` branch
- Don't change whitespaces or newlines in the existing unrelated code and never add whitespaces or tabs to empty lines
- Don't remove unrelated code and don't change files when/where modifications are not needed
- Don't add trailing newlines at the end of file, last newline character is at the end of code
- Never make changes that include sensitive information like API keys, secrets, passwords, etc.
- Comment changes, but only for logic that is not obvious.
- Make sure that the Dockerfile is well-formatted and does not include unnecessary layers
