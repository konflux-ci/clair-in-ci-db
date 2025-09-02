FROM quay.io/konflux-ci/konflux-test:v1.4.36@sha256:ed63df1970e2339eb5d170228616829ed56e292a5cff198fd0126b5d1f84045b as konflux-test

FROM quay.io/projectquay/clair-action:v0.0.12

RUN microdnf -y --setopt=tsflags=nodocs --setopt=install_weak_deps=0 install \
    jq && \
    microdnf clean all && \
    # Update the matcher database. Use the info log level to track sources
    DB_PATH=/tmp/matcher.db /bin/clair-action --level info update

COPY --from=konflux-test /utils.sh /utils.sh
COPY --from=konflux-test /usr/bin/retry /usr/bin/