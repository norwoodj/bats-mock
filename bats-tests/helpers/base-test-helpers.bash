#!/usr/bin/env bash

: ${FAKE_EXE_NAME:="veintitres"}
: ${ECHO_SENTINEL:="__sentinel__"}


function setup_and_stub {
    source /opt/testing/bats-mock/stub.bash
    stub "${FAKE_EXE_NAME}" "${@}"
}

function add_stubs {
    stub --add-stubs "${FAKE_EXE_NAME}" "${@}"
}

function run_stubbed {
    "${FAKE_EXE_NAME}" "${@}"
    unstub "${FAKE_EXE_NAME}"
}

function run_stubbed_jq_output {
    local jq_pattern=${1}
    "${FAKE_EXE_NAME}" "${@:2}" | jq -r "${jq_pattern}"
    unstub "${FAKE_EXE_NAME}"
}

function run_stubbed_three_calls {
    "${FAKE_EXE_NAME}" arg
    "${FAKE_EXE_NAME}" arg
    "${FAKE_EXE_NAME}" "${@}"
    unstub "${FAKE_EXE_NAME}"
}

function run_stubbed_jq_output {
    local jq_pattern=${1}
    "${FAKE_EXE_NAME}" "${@:2}" | jq -r "${jq_pattern}"
    unstub "${FAKE_EXE_NAME}"
}
