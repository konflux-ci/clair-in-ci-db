FROM quay.io/konflux-ci/konflux-test:v1.5.1@sha256:e6b090c515168c8ed0fa932ffe0ac6f27dbc1ea41fdb2fe83cfcaa7829b910bd as konflux-test

FROM quay.io/projectquay/clair-action:v0.0.15@sha256:b1030714db65f576c1af4212d6d3dbd116e4cdf2a64efa2a54b1c41ea6209ddf

RUN rpm --import /cachi2/output/deps/generic/RPM-GPG-KEY-EPEL-8 && \
    microdnf -y --setopt=tsflags=nodocs install \
    --setopt=install_weak_deps=0 \
    jq-1.6-11.el8_10 && \
    microdnf clean all

COPY matcher.db /tmp/matcher.db
ENV DB_PATH=/tmp/matcher.db

COPY --from=konflux-test /utils.sh /utils.sh
COPY --from=konflux-test /usr/bin/retry /usr/bin/
COPY --from=konflux-test /usr/local/bin/yq /usr/local/bin/
COPY --from=konflux-test /usr/local/bin/select-oci-auth /usr/local/bin/
