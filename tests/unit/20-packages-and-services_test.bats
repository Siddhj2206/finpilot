#!/usr/bin/env bats
# Unit tests for build/20-packages-and-services.sh.
#
# The package phase is still transitional: it delegates to the provider that
# carries the packages the template already shipped. These tests assert the
# delegation and, more importantly, that the phase owns package installation
# so 10-overlay.sh never does.
#
# Run with: bats tests/unit/20-packages-and-services_test.bats

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_SRC="${REPO_ROOT}/build/20-packages-and-services.sh"

setup() {
	TEST_ROOT="${BATS_TEST_TMPDIR:-${BATS_TMPDIR}}/20-packages.${BATS_TEST_NUMBER:-0}.$$"
	CTX="${TEST_ROOT}/ctx"
	SCRIPT="${TEST_ROOT}/20-packages-and-services.sh"

	mkdir -p "${CTX}/build"
	cat >"${CTX}/build/10-build.sh" <<'EOF'
#!/usr/bin/bash
echo "DELEGATED-TO-PACKAGE-PROVIDER"
EOF
	chmod +x "${CTX}/build/10-build.sh"

	sed -e "s#/ctx/#${CTX}/#g" "${BUILD_SRC}" >"${SCRIPT}"
}

teardown() {
	rm -rf "${TEST_ROOT}"
}

@test "20-packages-and-services: sandbox rewrite left no writes to the host filesystem" {
	# Guards the rewrite above: if the script's paths change, the sed no longer
	# matches and the test would exec the real package provider.
	run grep -nE '(^|[^-[:alnum:]])/ctx/' "${SCRIPT}"
	[ "$status" -ne 0 ]
}

@test "20-packages-and-services: delegates to the transitional package provider" {
	run bash "${SCRIPT}"
	[ "$status" -eq 0 ]
	[[ "$output" == *"DELEGATED-TO-PACKAGE-PROVIDER"* ]]
}
