FROM quay.io/konflux-ci/konflux-test:v1.4.32@sha256:7e04a34cc9adb5fa0bfe5070d1a60321205f5e6f0cd3fb2e8a33a5ec8508fd29 as konflux-test

FROM quay.io/projectquay/clair-action:v0.0.11

RUN microdnf -y --setopt=tsflags=nodocs --setopt=install_weak_deps=0 install \
    jq && \
    microdnf clean all && \
    # Update the matcher database. Use the info log level to track sources
    DB_PATH=/tmp/matcher.db /bin/clair-action --level info update

COPY --from=konflux-test /utils.sh /utils.sh
COPY --from=konflux-test /usr/bin/retry /usr/bin/