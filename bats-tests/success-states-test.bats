#!/usr/bin/env bats

load ../libs/bats/bats-support/load
load ../libs/bats/bats-assert/load

load helpers/base-test-helpers

@test "handle_correct_args_on_third_call" {
    setup_and_stub \
        " arg : echo ${ECHO_SENTINEL}0" \
        " arg : echo ${ECHO_SENTINEL}1" \
        " other-arg : echo ${ECHO_SENTINEL}2"

    run run_stubbed_three_calls other-arg
    assert_success
    assert_output --partial "${ECHO_SENTINEL}0"
    assert_output --partial "${ECHO_SENTINEL}1"
    assert_output --partial "${ECHO_SENTINEL}2"
}

@test "handle_correct_args_on_third_call_add_stubs" {
    setup_and_stub \
        " arg : echo ${ECHO_SENTINEL}0" \
        " arg : echo ${ECHO_SENTINEL}1"

    add_stubs " other-arg : echo ${ECHO_SENTINEL}2"

    run run_stubbed_three_calls other-arg
    assert_success
    assert_output --partial "${ECHO_SENTINEL}0"
    assert_output --partial "${ECHO_SENTINEL}1"
    assert_output --partial "${ECHO_SENTINEL}2"
}

@test "handle_any_arg_sentinel_only_arg" {
    setup_and_stub "__ANY__ : echo ${ECHO_SENTINEL}"

    run run_stubbed crazy-arg-that-definitely-doesnt-match
    assert_success
    assert_output --partial "${ECHO_SENTINEL}"
}

@test "handle_any_arg_sentinel_first_arg" {
    setup_and_stub "__ANY__ asdf : echo ${ECHO_SENTINEL}"

    run run_stubbed crazy-arg-that-definitely-doesnt-match asdf
    assert_success
    assert_output --partial "${ECHO_SENTINEL}"
}

@test "handle_any_arg_sentinel_second_arg" {
    setup_and_stub "asdf __ANY__  : echo ${ECHO_SENTINEL}"

    run run_stubbed asdf crazy-arg-that-definitely-doesnt-match
    assert_success
    assert_output --partial "${ECHO_SENTINEL}"
}

@test "handle_any_command_two_args" {
    setup_and_stub "echo ${ECHO_SENTINEL}"

    run run_stubbed asdf crazy-arg-that-definitely-doesnt-match
    assert_success
    assert_output --partial "${ECHO_SENTINEL}"
}

@test "handle_any_command_no_args" {
    setup_and_stub "echo ${ECHO_SENTINEL}"

    run run_stubbed
    assert_success
    assert_output --partial "${ECHO_SENTINEL}"
}
