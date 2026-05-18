---
name: hermetic-build-deps
description: Use when adding, updating, or troubleshooting RPM or artifact dependencies for the hermetic build. Covers rpms.in.yaml, rpms.lock.yaml, artifacts.lock.yaml, epel.repo, Cachi2 prefetching, and the Dockerfile install step.
---

# Hermetic Build Dependencies

## Overview

This repo uses Konflux hermetic builds — the `build-container` task runs with no network access. All external dependencies (RPMs, GPG keys) must be prefetched by Cachi2 during the `prefetch-dependencies` task and made available offline. Four files control this system and must stay in sync.

## When to Use

- Adding a new RPM package to the image
- Updating a pinned RPM version
- Prefetch-dependencies task is failing
- Understanding how Dockerfile installs relate to lock files
- Updating the EPEL GPG key or repository configuration

## Dependency Files

| File | Purpose | Format |
|------|---------|--------|
| `rpms.in.yaml` | Declares which packages to install | `packages: [jq]` + repo config pointer |
| `rpms.lock.yaml` | Pinned RPM versions, repos, checksums | Auto-generated lock file |
| `artifacts.lock.yaml` | Pinned generic artifacts (GPG keys, individual RPMs) | Manual checksums for non-repo downloads |
| `epel.repo` | EPEL 8 yum/dnf repository configuration | Standard repo file format |

## How They Work Together

```
rpms.in.yaml          ─── declares "I need jq" + points to epel.repo
    │
    ├─ rpms.lock.yaml  ─── resolves jq to exact version + checksum from repos
    │
    └─ epel.repo       ─── provides the EPEL 8 metalink URL for resolution

artifacts.lock.yaml    ─── pins the EPEL GPG key + individual RPM downloads
                           (these are fetched as "generic" artifacts by Cachi2)
```

### In the Tekton Pipeline

The `prefetch-input` parameter tells Cachi2 what to prefetch:

```yaml
prefetch-input: '[{"type": "rpm", "path": "."}, {"type": "generic", "path": "."}]'
```

- `type: rpm` — reads `rpms.in.yaml` → resolves via `rpms.lock.yaml` → downloads RPMs
- `type: generic` — reads `artifacts.lock.yaml` → downloads listed artifacts by URL + checksum

### In the Dockerfile

Prefetched artifacts land in `/cachi2/output/deps/`:

```dockerfile
RUN rpm --import /cachi2/output/deps/generic/RPM-GPG-KEY-EPEL-8 && \
    microdnf -y --setopt=tsflags=nodocs install \
    --setopt=install_weak_deps=0 \
    jq-1.6-11.el8_10 && \
    microdnf clean all
```

Key points:
- GPG key is imported from the Cachi2 generic artifacts path
- `microdnf install` uses exact version (`jq-1.6-11.el8_10`) matching `rpms.lock.yaml`
- `--setopt=tsflags=nodocs` and `--setopt=install_weak_deps=0` minimize image size

## Current Dependencies

### RPMs (via rpms.in.yaml + rpms.lock.yaml)
| Package | Pinned Version |
|---------|---------------|
| jq | 1.6-11.el8_10 |

### Generic Artifacts (via artifacts.lock.yaml)
| Artifact | Source |
|----------|--------|
| RPM-GPG-KEY-EPEL-8 | `dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8` |
| jq-1.6-11.el8_10.x86_64.rpm | `cdn-ubi.redhat.com` (UBI 8 appstream) |
| oniguruma-6.8.2-3.el8.x86_64.rpm | `cdn-ubi.redhat.com` (UBI 8 appstream, jq dependency) |

## How to Add a New RPM

1. Add the package name to `rpms.in.yaml`:
   ```yaml
   packages: [jq, newpackage]
   ```

2. Regenerate the lock file (requires the Cachi2 CLI or a Konflux workspace):
   ```bash
   cachi2 fetch-deps --source . rpm
   ```

3. If the RPM or its dependencies need to be pinned as generic artifacts, add entries to `artifacts.lock.yaml` with the download URL and SHA-256 checksum

4. Update the Dockerfile to install the new package with its exact version:
   ```dockerfile
   microdnf -y --setopt=tsflags=nodocs install \
   --setopt=install_weak_deps=0 \
   jq-1.6-11.el8_10 \
   newpackage-x.y-z.el8 && \
   ```

5. Keep it as a single `RUN` layer to minimize image size

## How to Update an Existing RPM Version

1. Update the version in `rpms.lock.yaml` (or regenerate with Cachi2)
2. Update the checksum in `artifacts.lock.yaml` if the RPM is also listed there
3. Update the exact version string in the Dockerfile `microdnf install` command
4. All three must match

## Common Mistakes

| Problem | Fix |
|---------|-----|
| prefetch-dependencies fails with checksum mismatch | Checksums in `artifacts.lock.yaml` or `rpms.lock.yaml` are stale — regenerate or update |
| Build fails with "package not found" | RPM version in Dockerfile doesn't match `rpms.lock.yaml` pinned version |
| GPG key import fails | `artifacts.lock.yaml` checksum for `RPM-GPG-KEY-EPEL-8` is wrong or key URL changed |
| New package not installed | Added to `rpms.in.yaml` but didn't regenerate `rpms.lock.yaml` |
| Transitive dependency missing | Add the dependency RPM to `artifacts.lock.yaml` as a generic artifact (like `oniguruma` for `jq`) |
| Hermetic build fails with network error | Verify all deps are in lock files — hermetic builds have no network access |