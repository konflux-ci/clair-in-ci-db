FROM quay.io/konflux-ci/konflux-test:v1.4.40@sha256:99eb8bcc7bcb35bdd5edea7b0ac333bbdb67586dea6b4dab92baf2b8fb32bf2c as konflux-test

FROM quay.io/projectquay/clair-action:v0.0.11

RUN microdnf -y --setopt=tsflags=nodocs --setopt=install_weak_deps=0 install \
    jq && \
    microdnf clean all && \
    # Update the matcher database. Use the info log level to track sources
    DB_PATH=/tmp/matcher.db /bin/clair-action --level info update

COPY --from=konflux-test /utils.sh /utils.sh
COPY --from=konflux-test /usr/bin/retry /usr/bin/