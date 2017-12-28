#!/usr/bin/env bats

load ../libs/bats/bats-support/load
load ../libs/bats/bats-assert/load

load helpers/base-test-helpers

@test "handle_wrong_single_arg" {
    setup_and_stub " arg : echo '${ECHO_SENTINEL}'"
    run run_stubbed "other-arg"

    assert_failure
    refute_output --partial "${ECHO_SENTINEL}"
    assert_output --partial "incorrect arg 0 for call 0 to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected : arg"
    assert_output --partial "actual   : other-arg"
}

@test "handle_two_wrong_args" {
    setup_and_stub "arg arg : echo '${ECHO_SENTINEL}'"
    run run_stubbed "arg" "other-arg"

    assert_failure
    refute_output --partial "${ECHO_SENTINEL}"
    assert_output --partial "incorrect arg 1 for call 0 to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected : arg arg"
    assert_output --partial "actual   : arg other-arg"
}

@test "handle_wrong_args_on_third_call" {
    setup_and_stub \
        " arg : echo ${ECHO_SENTINEL}0" \
        " arg : echo ${ECHO_SENTINEL}1" \
        " arg : echo ${ECHO_SENTINEL}2"

    run run_stubbed_three_calls other-arg

    assert_failure
    assert_output --partial "${ECHO_SENTINEL}0"
    assert_output --partial "${ECHO_SENTINEL}1"
    refute_output --partial "${ECHO_SENTINEL}2"
    assert_output --partial "incorrect arg 0 for call 2 to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected : arg"
    assert_output --partial "actual   : other-arg"
}

@test "handle_wrong_args_on_third_call_add_stubs" {
    setup_and_stub \
        " arg : echo ${ECHO_SENTINEL}0" \
        " arg : echo ${ECHO_SENTINEL}1"

    add_stubs " arg : echo ${ECHO_SENTINEL}2"

    run run_stubbed_three_calls other-arg

    assert_failure
    assert_output --partial "${ECHO_SENTINEL}0"
    assert_output --partial "${ECHO_SENTINEL}1"
    refute_output --partial "${ECHO_SENTINEL}2"
    assert_output --partial "incorrect arg 0 for call 2 to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected : arg"
    assert_output --partial "actual   : other-arg"
}

@test "handle_wrong_number_args_on_third_call" {
    setup_and_stub \
        " arg : echo ${ECHO_SENTINEL}0" \
        " arg : echo ${ECHO_SENTINEL}1" \
        " arg : echo ${ECHO_SENTINEL}2"

    run run_stubbed_three_calls arg arg

    assert_failure
    assert_output --partial "${ECHO_SENTINEL}0"
    assert_output --partial "${ECHO_SENTINEL}1"
    refute_output --partial "${ECHO_SENTINEL}2"
    assert_output --partial "wrong number of expected args (1 != actual 2) for call 2 to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected : arg"
    assert_output --partial "actual   : arg arg"
}

@test "handle_wrong_number_args_on_third_call_add_stubs" {
    setup_and_stub \
        " arg : echo ${ECHO_SENTINEL}0" \
        " arg : echo ${ECHO_SENTINEL}1"

    add_stubs " arg : echo ${ECHO_SENTINEL}2"

    run run_stubbed_three_calls arg arg

    assert_failure
    assert_output --partial "${ECHO_SENTINEL}0"
    assert_output --partial "${ECHO_SENTINEL}1"
    refute_output --partial "${ECHO_SENTINEL}2"
    assert_output --partial "wrong number of expected args (1 != actual 2) for call 2 to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected : arg"
    assert_output --partial "actual   : arg arg"
}

@test "handle_too_few_calls" {
    setup_and_stub \
        " arg : echo ${ECHO_SENTINEL}0" \
        " arg : echo ${ECHO_SENTINEL}1" \
        " arg : echo ${ECHO_SENTINEL}2" \
        " arg : echo ${ECHO_SENTINEL}3"

    run run_stubbed_three_calls arg

    assert_failure
    assert_output --partial "${ECHO_SENTINEL}0"
    assert_output --partial "${ECHO_SENTINEL}1"
    assert_output --partial "${ECHO_SENTINEL}2"
    refute_output --partial "${ECHO_SENTINEL}3"
    assert_output --partial "fewer calls than expected to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected : 4"
    assert_output --partial "actual   : 3"
}

@test "handle_too_many_calls" {
    setup_and_stub \
        " arg : echo ${ECHO_SENTINEL}0" \
        " arg : echo ${ECHO_SENTINEL}1" \

    run run_stubbed_three_calls arg

    assert_failure
    assert_output --partial "${ECHO_SENTINEL}0"
    assert_output --partial "${ECHO_SENTINEL}1"
    assert_output --partial "more calls than expected to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected : 2"
    assert_output --partial "actual   : 3"
}

@test "handle_any_arg_sentinel_fails_too_few_args" {
    setup_and_stub "__ANY__ : echo ${ECHO_SENTINEL}"

    run run_stubbed
    assert_failure
    refute_output --partial "${ECHO_SENTINEL}"
    assert_output --partial "wrong number of expected args (1 != actual 0) for call 0 to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected : __ANY__"
    assert_output --partial "actual   :"
}

@test "handle_any_arg_sentinel_fails_too_many_args" {
    setup_and_stub "__ANY__ : echo ${ECHO_SENTINEL}"

    run run_stubbed arg arg
    assert_failure
    refute_output --partial "${ECHO_SENTINEL}"
    assert_output --partial "wrong number of expected args (1 != actual 2) for call 0 to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected : __ANY__"
    assert_output --partial "actual   : arg arg"
}

@test "handle_any_arg_sentinel_fails_other_arg" {
    setup_and_stub "__ANY__ asdf : echo ${ECHO_SENTINEL}"

    run run_stubbed arg arg
    assert_failure
    refute_output --partial "${ECHO_SENTINEL}"
    assert_output --partial "incorrect arg 1 for call 0 to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected : __ANY__ asdf"
    assert_output --partial "actual   : arg arg"
}
