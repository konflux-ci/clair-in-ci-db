FROM quay.io/konflux-ci/konflux-test:v1.5.8@sha256:ce93e7ff1618deda40a66d90289d8fee1bf1ac151c06f1defd33d2a56dbd2b94 as konflux-test

FROM quay.io/projectquay/clair-action:v0.0.16@sha256:a4f36fc822dd6ae9ea4031fb5cfe642c39f37ddf46043b70433c95d27e5959eb

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
