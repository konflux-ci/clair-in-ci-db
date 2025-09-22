FROM quay.io/konflux-ci/konflux-test:v1.4.40@sha256:99eb8bcc7bcb35bdd5edea7b0ac333bbdb67586dea6b4dab92baf2b8fb32bf2c as konflux-test

FROM quay.io/projectquay/clair-action:v0.0.12@sha256:adfc28d51f08b82978aa6dc41b166b05a2a728fa9643c3a1b73b2032f18e7c30

RUN rpm --import /cachi2/output/deps/generic/RPM-GPG-KEY-EPEL-8 && \
    microdnf -y --setopt=tsflags=nodocs install \
    --setopt=install_weak_deps=0 \
    jq-1.6-11.el8_10 && \
    microdnf clean all

COPY matcher.db /tmp/matcher.db
ENV DB_PATH=/tmp/matcher.db

COPY --from=konflux-test /utils.sh /utils.sh
COPY --from=konflux-test /usr/bin/retry /usr/bin/
