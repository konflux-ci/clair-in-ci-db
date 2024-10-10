FROM registry.access.redhat.com/ubi9/go-toolset@sha256:adeedd50ce51475df1978b2da5ab1c0017f9596a5310fc54a26af285345ad7cf as build

# For stability of the update process we need a newer version of claircore than
# the version currently used in clair-action 0.0.9. The version 1.5.31 includes
# a the needed fix from https://github.com/quay/claircore/pull/1410.

RUN git clone --depth 1 --branch v0.0.9 https://github.com/quay/clair-action.git

WORKDIR /opt/app-root/src/clair-action

RUN go get github.com/quay/claircore@v1.5.31 && \
    go build -o clair-action -trimpath ./cmd/cli

FROM registry.access.redhat.com/ubi9-minimal@sha256:c0e70387664f30cd9cf2795b547e4a9a51002c44a4a86aa9335ab030134bf392

COPY --from=build /opt/app-root/src/clair-action/clair-action /usr/bin/clair-action

# Update the matcher database. Use the info log level to track sources
RUN DB_PATH=/tmp/matcher.db /bin/clair-action --level info update
