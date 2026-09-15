#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Default packages and services
###############################################################################
# This phase owns RPM and COPR installation. RPMs are installed here, never in
# 10-overlay.sh, so that a filesystem-overlay change cannot invalidate the
# expensive package layer above it.
#
# The default package set is still being agreed, so this phase delegates to
# 10-build.sh, which carries the current default. When the set is decided this
# phase gains the implementation directly.
###############################################################################

exec /ctx/build/10-build.sh
