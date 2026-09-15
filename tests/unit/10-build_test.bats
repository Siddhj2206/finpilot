#!/usr/bin/env bats
# Unit tests for build/10-build.sh.
#
# This file is the transitional default-package provider: it installs RPMs and
# nothing else. Filesystem overlays and service enablement belong to
# 10-overlay.sh, and the package contract itself moves to
# 20-packages-and-services.sh. The tests below both exercise the package
# install and guard the boundary (no rsync, no systemctl).
#
# The script sources /ctx/build/copr-helpers.sh, so each test rewrites a
# throwaway copy to point at a sandbox context and stubs dnf5.
#
# Run with: bats tests/unit/10-build_test.bats

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_SRC="${REPO_ROOT}/build/10-build.sh"

setup() {
	TEST_ROOT="${BATS_TEST_TMPDIR:-${BATS_TMPDIR}}/10-build.${BATS_TEST_NUMBER:-0}.$$"
	CTX="${TEST_ROOT}/ctx"
	STUB_BIN="${TEST_ROOT}/stub-bin"
	SCRIPT="${TEST_ROOT}/10-build.sh"

	DNF5_LOG="${TEST_ROOT}/logs/dnf5.log"
	RSYNC_LOG="${TEST_ROOT}/logs/rsync.log"
	SYSTEMCTL_LOG="${TEST_ROOT}/logs/systemctl.log"

	mkdir -p "${STUB_BIN}" "${TEST_ROOT}/logs" "${CTX}/build"

	# The real helper library is sourced verbatim so a syntax break there fails
	# this suite too.
	cp "${REPO_ROOT}/build/copr-helpers.sh" "${CTX}/build/copr-helpers.sh"

	sed -e "s#/ctx/#${CTX}/#g" "${BUILD_SRC}" >"${SCRIPT}"

	export PATH="${STUB_BIN}:${PATH}"
	export DNF5_LOG RSYNC_LOG SYSTEMCTL_LOG

	for tool in dnf5 rsync systemctl; do
		local log_var
		log_var="$(printf '%s' "${tool}" | tr '[:lower:]' '[:upper:]')_LOG"
		cat >"${STUB_BIN}/${tool}" <<EOF
#!/usr/bin/bash
printf '%s\n' "\$*" >> "\${${log_var}}"
exit 0
EOF
		chmod +x "${STUB_BIN}/${tool}"
	done
}

teardown() {
	rm -rf "${TEST_ROOT}"
}

@test "10-build: sandbox rewrite left no writes to the host filesystem" {
	# Guards the rewrite above: if the script's paths change, the sed no longer
	# matches and every other test in this file would silently touch the host.
	run grep -nE '(^|[^-[:alnum:]])/ctx/' "${SCRIPT}"
	[ "$status" -ne 0 ]

	grep -q "source ${CTX}/build/copr-helpers.sh" "${SCRIPT}"
}

@test "10-build: completes successfully" {
	run bash "${SCRIPT}"
	[ "$status" -eq 0 ]
}

@test "10-build: emits GitHub Actions group markers" {
	run bash "${SCRIPT}"
	[ "$status" -eq 0 ]
	[[ "$output" == *"::group:: Install Default Packages"* ]]
	[[ "$output" == *"::endgroup::"* ]]
}

@test "10-build: installs the packages the default ujust recipes depend on" {
	run bash "${SCRIPT}"
	[ "$status" -eq 0 ]

	mapfile -t calls <"${DNF5_LOG}"
	[ "${#calls[@]}" -eq 1 ]
	[ "${calls[0]}" = "install -y tmux gum" ]
}

@test "10-build: performs no overlays or service enablement" {
	# Boundary guard for the split: overlays and services belong to
	# 10-overlay.sh, so this package script must not touch either.
	run bash "${SCRIPT}"
	[ "$status" -eq 0 ]

	[ ! -e "${RSYNC_LOG}" ]
	[ ! -e "${SYSTEMCTL_LOG}" ]
}

@test "10-build: sources copr-helpers.sh so copr_install_isolated is available" {
	cat >>"${SCRIPT}" <<'EOF'
declare -F copr_install_isolated >/dev/null && echo "HELPER_PRESENT"
EOF
	run bash "${SCRIPT}"
	[ "$status" -eq 0 ]
	[[ "$output" == *"HELPER_PRESENT"* ]]
}

@test "10-build: fails fast when copr-helpers.sh is missing from the context" {
	rm -f "${CTX}/build/copr-helpers.sh"
	run bash "${SCRIPT}"
	[ "$status" -ne 0 ]
}

@test "10-build: restores default glob behaviour before finishing" {
	cat >>"${SCRIPT}" <<'EOF'
shopt -q nullglob || echo "NULLGLOB_OFF"
EOF
	run bash "${SCRIPT}"
	[ "$status" -eq 0 ]
	[[ "$output" == *"NULLGLOB_OFF"* ]]
}
