#!/usr/bin/env bats

# Unit tests for build/00-image-info.sh. ROOT_DIR directs the script's image
# filesystem writes into a disposable sandbox.

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
IMAGE_INFO_SRC="${SCRIPT_DIR}/../../build/00-image-info.sh"

setup() {
    TEST_ROOT="${BATS_TEST_TMPDIR:-${BATS_TMPDIR}}/image-info.${BATS_TEST_NUMBER:-0}.$$"
    SANDBOX="${TEST_ROOT}/root"
    IMAGE_INFO_JSON="${SANDBOX}/usr/share/ublue-os/image-info.json"
    OS_RELEASE="${SANDBOX}/usr/lib/os-release"

    mkdir -p "$(dirname "${OS_RELEASE}")"
    export ROOT_DIR="${SANDBOX}"
    export IMAGE_NAME="finpilot"
    export IMAGE_VENDOR="projectbluefin"
    export UBLUE_IMAGE_TAG="stable"
    export BASE_IMAGE_NAME="silverblue"
    export FEDORA_MAJOR_VERSION="44"

    cat >"${OS_RELEASE}" <<'EOF'
NAME="Fedora Linux"
VERSION="44.20260905.0 (Silverblue)"
ID=fedora
VERSION_ID=44
DEFAULT_HOSTNAME="fedora"
HOME_URL="https://silverblue.fedoraproject.org"
DOCUMENTATION_URL="https://docs.fedoraproject.org/"
SUPPORT_URL="https://ask.fedoraproject.org/"
BUG_REPORT_URL="https://github.com/fedora-silverblue/issue-tracker/issues"
ID_LIKE="fedora"
VARIANT="Silverblue"
VARIANT_ID=silverblue
OSTREE_VERSION='44.20260905.0'
EOF
}

teardown() {
    rm -rf "${TEST_ROOT}"
}

run_script() {
    run bash "${IMAGE_INFO_SRC}"
}

json_field() {
    python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "${IMAGE_INFO_JSON}" "$1"
}

@test "00-image-info: writes Bluefin-compatible image metadata" {
    run_script
    [ "$status" -eq 0 ]

    run python3 -m json.tool "${IMAGE_INFO_JSON}"
    [ "$status" -eq 0 ]
    [ "$(json_field image-name)" = "finpilot" ]
    [ "$(json_field image-vendor)" = "projectbluefin" ]
    [ "$(json_field image-ref)" = "ostree-image-signed:docker://ghcr.io/projectbluefin/finpilot" ]
    [ "$(json_field image-tag)" = "stable" ]
    [ "$(json_field base-image-name)" = "silverblue" ]
    [ "$(json_field fedora-version)" = "44" ]
}

@test "00-image-info: does not create a flavor field from the image name" {
    export IMAGE_NAME="finpilot-nvidia"
    run_script
    [ "$status" -eq 0 ]
    [ "$(json_field image-ref)" = "ostree-image-signed:docker://ghcr.io/projectbluefin/finpilot-nvidia" ]
    run python3 -c 'import json,sys; sys.exit("image-flavor" in json.load(open(sys.argv[1])))' "${IMAGE_INFO_JSON}"
    [ "$status" -eq 0 ]
}

@test "00-image-info: updates existing base os-release identity" {
    export VERSION="44.20260907.1"
    run_script
    [ "$status" -eq 0 ]

    grep -q '^VARIANT_ID="finpilot"$' "${OS_RELEASE}"
    grep -q '^PRETTY_NAME="finpilot (Version: 44.20260907.1)"$' "${OS_RELEASE}"
    grep -q '^NAME="finpilot"$' "${OS_RELEASE}"
    grep -q '^VERSION="44.20260907.1 (silverblue)"$' "${OS_RELEASE}"
    grep -q '^OSTREE_VERSION="44.20260907.1"$' "${OS_RELEASE}"
    grep -q '^IMAGE_ID="finpilot"$' "${OS_RELEASE}"
    grep -q '^IMAGE_VERSION="44.20260907.1"$' "${OS_RELEASE}"
    grep -q '^DEFAULT_HOSTNAME="fedora"$' "${OS_RELEASE}"
    grep -q '^ID=fedora$' "${OS_RELEASE}"
    grep -q '^ID_LIKE="fedora"$' "${OS_RELEASE}"
}

@test "00-image-info: derives GitHub URLs from image identity" {
    run_script
    [ "$status" -eq 0 ]

    grep -q '^HOME_URL="https://github.com/projectbluefin/finpilot"$' "${OS_RELEASE}"
    grep -q '^DOCUMENTATION_URL="https://github.com/projectbluefin/finpilot/blob/main/README.md"$' "${OS_RELEASE}"
    grep -q '^SUPPORT_URL="https://github.com/projectbluefin/finpilot/issues"$' "${OS_RELEASE}"
    grep -q '^BUG_REPORT_URL="https://github.com/projectbluefin/finpilot/issues/new"$' "${OS_RELEASE}"
    grep -q '^ID_LIKE="fedora"$' "${OS_RELEASE}"
}

@test "00-image-info: permits explicit URL overrides without changing base identity" {
    export HOME_URL="https://finpilot.example"
    export DOCUMENTATION_URL="https://docs.finpilot.example"
    export SUPPORT_URL="https://support.finpilot.example"
    export BUG_REPORT_URL="https://bugs.finpilot.example"
    run_script
    [ "$status" -eq 0 ]

    grep -q '^PRETTY_NAME="finpilot (Version: stable)"$' "${OS_RELEASE}"
    grep -q '^NAME="finpilot"$' "${OS_RELEASE}"
    grep -q '^ID_LIKE="fedora"$' "${OS_RELEASE}"
    grep -q '^HOME_URL="https://finpilot.example"$' "${OS_RELEASE}"
    grep -q '^DOCUMENTATION_URL="https://docs.finpilot.example"$' "${OS_RELEASE}"
    grep -q '^SUPPORT_URL="https://support.finpilot.example"$' "${OS_RELEASE}"
    grep -q '^BUG_REPORT_URL="https://bugs.finpilot.example"$' "${OS_RELEASE}"
}

@test "00-image-info: records a source revision when supplied" {
    export SHA_HEAD_SHORT="abc1234"
    run_script
    [ "$status" -eq 0 ]
    grep -q '^BUILD_ID="abc1234"$' "${OS_RELEASE}"
}

@test "00-image-info: is idempotent" {
    run_script
    [ "$status" -eq 0 ]
    run_script
    [ "$status" -eq 0 ]

    run grep -c '^VARIANT_ID=' "${OS_RELEASE}"
    [ "$output" -eq 1 ]
    run grep -c '^IMAGE_ID=' "${OS_RELEASE}"
    [ "$output" -eq 1 ]
}

@test "00-image-info: still writes metadata without os-release" {
    rm -f "${OS_RELEASE}"
    run_script
    [ "$status" -eq 0 ]
    [ -f "${IMAGE_INFO_JSON}" ]
    [ ! -f "${OS_RELEASE}" ]
}

@test "00-image-info: escapes JSON values" {
    export IMAGE_PRETTY_NAME='Finpilot "OS"'
    export IMAGE_NAME='finpilot"test'
    run_script
    [ "$status" -eq 0 ]

    run python3 -m json.tool "${IMAGE_INFO_JSON}"
    [ "$status" -eq 0 ]
    [ "$(json_field image-name)" = 'finpilot"test' ]
}

@test "00-image-info: fails before writing when required identity is missing" {
    unset IMAGE_NAME
    run_script
    [ "$status" -ne 0 ]
    [ ! -f "${IMAGE_INFO_JSON}" ]
}
