#!/usr/bin/env bash

set -euo pipefail

# Transitional compatibility phase.
#
# Preserve the current cleanup implementation until the rewritten cleanup
# contract is ready. The Containerfile calls this final phase name so future
# replacement does not change image assembly order.
exec /ctx/build/clean-stage.sh
