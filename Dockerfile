FROM quay.io/konflux-ci/konflux-test:v1.4.53@sha256:724ecf16a1fc9b51a1b20c91c5125556c53d471d0d8db1648d2404e4715f204e as konflux-test

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
COPY --from=konflux-test /usr/local/bin/yq /usr/local/bin/
COPY --from=konflux-test /usr/local/bin/select-oci-auth /usr/local/bin/
