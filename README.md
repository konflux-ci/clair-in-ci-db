# Konflux Clair-in-CI Database

This repository contains a containerized [Clair](https://quay.github.io/clair/) vulnerability scanner designed for use in [Konflux CI](https://konflux-ci.dev/) pipelines. It builds a Docker image that includes the [clair-in-ci](https://github.com/quay/clair-action) utility for scanning container images and artifacts in CI/CD environments.

## What This Container Provides

- **Clair Vulnerability Scanning Engine**: Latest Clair Database with updated vulnerability definitions
- **Konflux Integration**: Built on konflux-test](https://github.com/konflux-ci/konflux-test) base with policy utilities
- **Container Security**: Dedicated scanning for container images and build artifacts

## Key Features

- Containerized clair-action utility
- Automated vulnerability definition updates via `clair-in-ci update` functionality

## Container Components

- **Base Image**: [clair-action](https://github.com/quay/clair-action) and [konflux-test](https://github.com/konflux-ci/konflux-test) images
- **Clair**: Configured Clair action vulnerability scanner
- **Utilities**: Includes jq, yq and utility scripts inherited from konflux-test
- **Konflux Policies**: Inherited policy framework from konflux-test

## Usage

### Basic Container Run
```bash
docker run -it --rm --entrypoint=/bin/bash <image-with-tag-name>
```

### In Konflux Pipeline
This container is designed to be used as part of Konflux build and security scanning pipelines, typically in the security scanning phase of the build process - see the [clair-scan](https://github.com/konflux-ci/konflux-test-tasks/tree/main/task/clair-scan) task for more details.
The latest versions of the image can be found at [quay.io/konflux-ci/clair-in-ci](https://quay.io/repository/konflux-ci/clair-in-ci).

## Build Requirements

The container automatically handles:
- Clair action installation and configuration
- Vulnerability database updates
- User and permission setup

## Development and Contribution

See the [CONTRIBUTING.md](CONTRIBUTING.md) file for details on contributing to this repository.

## License

See [LICENSE](LICENSE) file for details.

