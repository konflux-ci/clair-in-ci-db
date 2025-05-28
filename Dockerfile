FROM quay.io/konflux-ci/konflux-test:v1.4.26@sha256:124643eeaa77684dea6270eada4553ebd7d63fcc06ff0c57f4a7d43695507bb5 as konflux-test

FROM quay.io/projectquay/clair-action:v0.0.11

RUN microdnf -y --setopt=tsflags=nodocs --setopt=install_weak_deps=0 install \
    jq && \
    microdnf clean all && \
    # Update the matcher database. Use the info log level to track sources
    DB_PATH=/tmp/matcher.db /bin/clair-action --level info update

COPY --from=konflux-test /utils.sh /utils.sh

