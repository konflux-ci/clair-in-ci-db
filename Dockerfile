FROM quay.io/konflux-ci/konflux-test:v1.4.27@sha256:5f3200bb9f52c888be99d3eeacde6445b21b731b9216e20259522eba99f9766e as konflux-test

FROM quay.io/projectquay/clair-action:v0.0.11

RUN microdnf -y --setopt=tsflags=nodocs --setopt=install_weak_deps=0 install \
    jq && \
    microdnf clean all && \
    # Update the matcher database. Use the info log level to track sources
    DB_PATH=/tmp/matcher.db /bin/clair-action --level info update

COPY --from=konflux-test /utils.sh /utils.sh

