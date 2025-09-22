FROM quay.io/konflux-ci/konflux-test:v1.4.39@sha256:89cdc9d251e15d07018548137b4034669df8e9e2b171a188c8b8201d3638cb17 as konflux-test

FROM quay.io/projectquay/clair-action:v0.0.11@sha256:80486643baad47f2ac606e5c0e5274f296c08464aebb3dc90f97f22ba92505dd

RUN rpm --import /cachi2/output/deps/generic/RPM-GPG-KEY-EPEL-8 && \
    microdnf -y --setopt=tsflags=nodocs install \
    --setopt=install_weak_deps=0 \
    jq-1.6-11.el8_10 && \
    microdnf clean all

COPY clair-db/matcher.db /tmp/matcher.db
ENV DB_PATH=/tmp/matcher.db

COPY --from=konflux-test /utils.sh /utils.sh
COPY --from=konflux-test /usr/bin/retry /usr/bin/
