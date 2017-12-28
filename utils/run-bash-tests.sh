#!/usr/bin/env bash

: ${BATS_BASH_TEST_DOCKER_COMPOSE:="$(pwd -P)/docker/docker-compose-tests.yaml"}


function main {
    docker-compose -f "${BATS_BASH_TEST_DOCKER_COMPOSE}" run bats-unit-tests "${@}"
}

set -euo pipefail
main "${@}"
