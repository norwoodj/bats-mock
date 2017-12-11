#!/usr/bin/env bash

: ${BATS_TMPDIR:="/tmp"}
: ${BATS_MOCK_TMPDIR:="${BATS_TMPDIR}"}
: ${BATS_MOCK_BINDIR:="${BATS_MOCK_TMPDIR}/bin"}
: ${BATS_MOCK_ANY_ARG_SENTINEL:="__ANY__"}

PATH="${BATS_MOCK_BINDIR}:${PATH}"


function _cleanup {
    rm -f "${mock_exe_path}" "${stub_plan_file}" "${stub_run_index_file}" "${stub_run_error_file}"
}

function _report_error {
    local program="${1}"
    local stub_run_error_file="${BATS_MOCK_TMPDIR}/${program}-stub-run-errors"

    if [[ ! -f "${stub_run_error_file}" ]]; then
        _cleanup
        return
    fi

    local error_message=$(jq -r ".message" "${stub_run_error_file}")
    local expected=$(jq -r ".expected" "${stub_run_error_file}" | base64 -d)
    local actual=$(jq -r ".actual" "${stub_run_error_file}" | base64 -d)

    _cleanup
    batslib_print_kv_single_or_multi 8 \
        'expected' "${expected}" \
        'actual'   "${actual}" \
    | batslib_decorate "${error_message}" \
    | fail
}

function stub {
    while [[ "${1}" == -* ]]; do
        case "${1}" in
            --add-stubs | -a) local add_stubs=1 ;;
        esac

        shift
    done

    local program="${1}"
    local stub_plan_file="${BATS_MOCK_TMPDIR}/${program}-stub-plan"
    local stub_run_index_file="${BATS_MOCK_TMPDIR}/${program}-stub-run-index"
    local stub_run_error_file="${BATS_MOCK_TMPDIR}/${program}-stub-run-errors"
    local mock_exe_path="${BATS_MOCK_BINDIR}/${program}"

    if [[ -z "${add_stubs:+_}" ]]; then
        _cleanup
        mkdir -p "${BATS_MOCK_BINDIR}"
        ln -sf "$(dirname ${BASH_SOURCE[0]})/binstub" "${mock_exe_path}"
        echo 0 > "${stub_run_index_file}"
    fi

    for plan in "${@:2}"; do
        declare -a 'args=('"${plan}"')'

        for a in "${args[@]}"; do
            # Print the seperator between the command to match and the command to run in response
            if [[ "${a}" == ":" ]]; then
                echo -n ": "
            # Quote empty string or strings that contain spaces
            elif [[ -z "${a}" ]] || [[ "${a}" =~ '\ |\' ]]; then
                echo -n "$(echo -n "'${a}'" | base64 --wrap=0) "
            # All other symbols are printed as is
            else
                echo -n "$(echo -n "${a}" | base64 --wrap=0) "
            fi

        done

        echo
    done >> "${stub_plan_file}"
}

function unstub {
    local program="${1}"
    local stub_plan_file="${BATS_MOCK_TMPDIR}/${program}-stub-plan"
    local stub_run_index_file="${BATS_MOCK_TMPDIR}/${program}-stub-run-index"
    local stub_run_error_file="${BATS_MOCK_TMPDIR}/${program}-stub-run-errors"
    local mock_exe_path="${BATS_MOCK_BINDIR}/${program}"

    local expected_num_commands_run="$(wc -l < "${stub_plan_file}")"
    local stub_run_commands_seen="$(cat "${stub_run_index_file}")"

    if [[ ! -f "${stub_run_error_file}" ]]; then
        if [[ "${stub_run_commands_seen}" != "${expected_num_commands_run}" ]]; then
            jq . > "${stub_run_error_file}" <<EOF
{
    "message": "fewer calls than expected to mock '${program}'",
    "expected": "$(echo -n "${expected_num_commands_run}" | base64)",
    "actual": "$(echo -n "${stub_run_commands_seen}" | base64)"
}
EOF
        fi
    fi

    _report_error "${program}"
}
