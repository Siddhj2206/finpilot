#!/usr/bin/bash

set -euo pipefail

###############################################################################
# Default packages (transitional)
###############################################################################
# Carries the current default package set. It is called by
# 20-packages-and-services.sh, which owns package installation and will absorb
# this file once the default set is agreed.
#
# tmux smoke-tests that the DNF metadata cache is warm. gum is required by the
# default ujust recipes for interactive prompts.
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

# Enable nullglob for all glob operations to prevent failures on empty matches
shopt -s nullglob

echo "::group:: Install Default Packages"

dnf5 install -y tmux gum

# Example using COPR with the isolated pattern:
# copr_install_isolated "ublue-os/staging" package-name

echo "::endgroup::"

# Restore default glob behavior
shopt -u nullglob
