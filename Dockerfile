FROM quay.io/konflux-ci/konflux-test:v1.4.29@sha256:3619ffde751d337d02f1f61c83c5c39eb87d8091dbe5a9af58ea98577fa09461 as konflux-test

FROM quay.io/projectquay/clair-action:v0.0.11

RUN microdnf -y --setopt=tsflags=nodocs --setopt=install_weak_deps=0 install \
    jq && \
    microdnf clean all && \
    # Update the matcher database. Use the info log level to track sources
    DB_PATH=/tmp/matcher.db /bin/clair-action --level info update

COPY --from=konflux-test /utils.sh /utils.sh
COPY --from=konflux-test /usr/bin/retry /usr/bin/