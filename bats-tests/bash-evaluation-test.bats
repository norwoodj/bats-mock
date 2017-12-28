#!/usr/bin/env bats

load ../libs/bats/bats-support/load
load ../libs/bats/bats-assert/load

load helpers/base-test-helpers

@test "test_command_with_pipe" {
    setup_and_stub "arg : echo blue '|' sed 's/blue/green/g'"
    cat /tmp/veintitres-stub-plan
    run run_stubbed arg
    assert_success
    assert_output green
}

@test "test_command_with_herestring" {
    setup_and_stub "arg : sed 's/blue/green/g' '<<<' blue"
    run run_stubbed arg
    assert_success
    assert_output green
}

@test "test_command_with_for_loop" {
    setup_and_stub "arg : for a in one 'two;' do echo '\$a;' done"
    run run_stubbed arg
    assert_success
    assert_output "$(cat <<EOF
one
two
EOF
)"
}

@test "test_command_echo_pipe" {
    setup_and_stub "arg : echo '\"|\"'"
    run run_stubbed arg
    assert_success
    assert_output "|"
}

@test "test_command_echo_herestring" {
    setup_and_stub "arg : echo '\"<<<\"'"
    run run_stubbed arg
    assert_success
    assert_output "<<<"
}
