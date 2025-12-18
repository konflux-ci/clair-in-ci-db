FROM quay.io/konflux-ci/konflux-test:v1.4.44@sha256:00d5ba3ac4fadb315da2199e931c1167f2b45884d2990de39104dfa9b78117d4 as konflux-test

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
