FROM quay.io/konflux-ci/konflux-test:v1.4.41@sha256:afea44d83043be7f528ec2cacaeb0c3b69cdafdd86a1b930957def38400f8a6c as konflux-test

FROM quay.io/projectquay/clair-action:v0.0.12

RUN microdnf -y --setopt=tsflags=nodocs --setopt=install_weak_deps=0 install \
    jq && \
    microdnf clean all && \
    # Update the matcher database. Use the info log level to track sources
    DB_PATH=/tmp/matcher.db /bin/clair-action --level info update

COPY --from=konflux-test /utils.sh /utils.sh
COPY --from=konflux-test /usr/bin/retry /usr/bin/