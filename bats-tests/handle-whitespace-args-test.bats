#!/usr/bin/env bats

load ../libs/bats/bats-support/load
load ../libs/bats/bats-assert/load

load helpers/base-test-helpers


@test "handle_no_args_succeeds" {
    setup_and_stub " : echo '${ECHO_SENTINEL}'"
    run run_stubbed
    assert_success
    assert_output "${ECHO_SENTINEL}"
}

@test "handle_no_args_fails_on_ws_arg" {
    setup_and_stub " : echo '${ECHO_SENTINEL}'"
    run run_stubbed ""
    assert_failure
    refute_output --partial "${ECHO_SENTINEL}"
    assert_output --partial "wrong number of expected args (0 != actual 1) for call 0 to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected :"
    assert_output --partial "actual   : ''"
}

@test "handle_no_args_fails_on_non_ws_arg" {
    setup_and_stub " : echo '${ECHO_SENTINEL}'"
    run run_stubbed asdf
    assert_failure
    refute_output --partial "${ECHO_SENTINEL}"
    assert_output --partial "wrong number of expected args (0 != actual 1) for call 0 to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected :"
    assert_output --partial "actual   : asdf"
}

@test "handle_ws_arg_succeeds" {
    setup_and_stub "'' : echo '${ECHO_SENTINEL}'"
    run run_stubbed ""
    assert_success
    assert_output "${ECHO_SENTINEL}"
}

@test "handle_ws_arg_fails_on_no_args" {
    setup_and_stub "'' : echo '${ECHO_SENTINEL}'"
    run run_stubbed
    assert_failure
    refute_output --partial "${ECHO_SENTINEL}"
    assert_output --partial "wrong number of expected args (1 != actual 0) for call 0 to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected : ''"
    assert_output --partial "actual   :"
}

@test "handle_ws_arg_fails_on_non_ws_arg" {
    setup_and_stub "'' : echo '${ECHO_SENTINEL}'"
    run run_stubbed asdf
    assert_failure
    refute_output --partial "${ECHO_SENTINEL}"
    assert_output --partial "incorrect arg 0 for call 0 to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected : ''"
    assert_output --partial "actual   : asdf"
}

@test "handle_multiple_ws_args_succeeds" {
    setup_and_stub "'' '' : echo '${ECHO_SENTINEL}'"
    run run_stubbed "" ""
    assert_success
    assert_output "${ECHO_SENTINEL}"
}

@test "handle_multiple_ws_args_fails_one_ws" {
    setup_and_stub "'' '' : echo '${ECHO_SENTINEL}'"
    run run_stubbed ""
    assert_failure
    refute_output --partial "${ECHO_SENTINEL}"
    assert_output --partial "wrong number of expected args (2 != actual 1) for call 0 to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected : '' ''"
    assert_output --partial "actual   : ''"
}

@test "handle_multiple_ws_args_fails_three_ws" {
    setup_and_stub "'' '' : echo '${ECHO_SENTINEL}'"
    run run_stubbed "" "" ""
    assert_failure
    refute_output --partial "${ECHO_SENTINEL}"
    assert_output --partial "wrong number of expected args (2 != actual 3) for call 0 to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected : '' ''"
    assert_output --partial "actual   : '' '' ''"
}

@test "handle_multiple_ws_args_fails_non_ws" {
    setup_and_stub "'' '' : echo '${ECHO_SENTINEL}'"
    run run_stubbed cat cat
    assert_failure
    refute_output --partial "${ECHO_SENTINEL}"
    assert_output --partial "incorrect arg 0 for call 0 to mock '${FAKE_EXE_NAME}'"
    assert_output --partial "expected : '' ''"
    assert_output --partial "actual   : cat cat"
}

@test "handle_json_expected_arg_succeeds" {
    setup_and_stub "'{\"cat\": \"echo\"}' : echo '${ECHO_SENTINEL}'"
    run run_stubbed "{\"cat\": \"echo\"}"
    assert_success
    assert_output "${ECHO_SENTINEL}"
}

@test "handle_json_run_command_succeeds" {
    setup_and_stub "'asdf' : echo '{\"cat\": \"${ECHO_SENTINEL}\"}'"
    run run_stubbed_jq_output ".cat" asdf
    assert_success
    assert_output "${ECHO_SENTINEL}"
}

@test "handle_json_expected_arg_and_run_command_succeeds" {
    setup_and_stub "'{\"dog\": \"oscar\"}' : echo '{\"cat\": \"${ECHO_SENTINEL}\"}'"
    run run_stubbed_jq_output ".cat" "{\"dog\": \"oscar\"}"
    assert_success
    assert_output "${ECHO_SENTINEL}"
}
