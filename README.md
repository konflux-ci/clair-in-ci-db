# Project overview
Repo for building clair-in-ci DB on scheduled basis. Plays the key role for executing vulnerability scan in build-definitions pipeline.
Project is owned by integration-service members.

## Dockerfile
Located on root level using konflux-test image as an base image together with clair-action one.
- build hermetically
- pushed to corresponding quay.io repository

## Installation
No installation is required for this check.

### Basic usage
Once the image is build and pushed to quay.io, clair-scan task will use this latest image for evaluating vulnerabilities.

- no scripts required for running the image
- to debug your changes you can use ```docker run -it --rm --entrypoint=/bin/bash <image-with-tag-name>```

