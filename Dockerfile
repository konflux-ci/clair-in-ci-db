FROM quay.io/konflux-ci/konflux-test:v1.4.25@sha256:78f5fd149f6fcd1e8ab8c7227cfb82c1be2eba0bbda49f033b5d82e9154414b2 as konflux-test

FROM quay.io/projectquay/clair-action:v0.0.11

RUN microdnf -y --setopt=tsflags=nodocs --setopt=install_weak_deps=0 install \
    jq \
    xz \
    tar && \
    microdnf clean all

RUN ARCH=$(uname -m) && curl -s -L https://github.com/koalaman/shellcheck/releases/download/v0.9.0/shellcheck-v0.9.0.linux."$ARCH".tar.xz -o shellcheck-v0.9.0.linux."$ARCH".tar.xz && \
    tar -xJvf shellcheck-v0.9.0.linux."$ARCH".tar.xz && \
    mv shellcheck-v0.9.0/shellcheck /usr/local/bin/ && \
	shellcheck --version && \
	rm -f shellcheck-v0.9.0.linux."$ARCH".tar.xz

    # Update the matcher database. Use the info log level to track sources
RUN DB_PATH=/tmp/matcher.db /bin/clair-action --level info update



COPY --from=konflux-test /utils.sh /utils.sh

