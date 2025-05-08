#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

# Retry a given command RETRY_COUNT times, defaults to 3.
# Retry stops once the expected exit status is encountered.
# Expected exit status is given in the first positional argument.
# Added heret to be used in clair-scan tasks
retry() {
    local status
    local retry=0
    local -r interval=${RETRY_INTERVAL:-5}
    local -r max_retries=5
    local expected_status
    if grep -q "^[[:digit:]]\+$" <<<"$1"; then
        expected_status=$1
        shift
    fi
    while true; do
        "$@" && break
        status=$?
        if [[ -v expected_status ]] && [[ $status -eq $expected_status ]]; then
            return $status
        fi
        ((retry+=1))
        if [ $retry -gt $max_retries ]; then
            return $status
        fi
        echo "info: Waiting for a while, then retry ..." 1>&2
        sleep "$interval"
    done
}
