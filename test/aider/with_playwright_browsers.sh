#!/bin/bash

# This test file will be executed against one of the scenarios devcontainer.json test that
# includes the 'color' feature with "favorite": "gold" option.

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
# shellcheck disable=SC2016
check "chromium is installed" bash -c 'find ~/.cache/ms-playwright -maxdepth 1 -type d | grep -E chromium'
check "firefox is installed" bash -c 'find ~/.cache/ms-playwright -maxdepth 1 -type d | grep -E firefox'

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults