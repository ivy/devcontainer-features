#!/bin/bash

# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'color' Feature with no options.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md
#
# Eg:
# {
#    "image": "<..some-base-image...>",
#    "features": {
#      "color": {}
#    },
#    "remoteUser": "root"
# }
#
# Thus, the value of all options will fall back to the default value in the
# Feature's 'devcontainer-feature.json'.
# For the 'color' feature, that means the default favorite color is 'red'.
#
# These scripts are run as 'root' by default. Although that can be changed
# with the '--remote-user' flag.
# 
# This test can be run with the following command:
#
#    devcontainer features test    \ 
#               --features color   \
#               --remote-user root \
#               --skip-scenarios   \
#               --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
#               /path/to/this/repo

set -e

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md#dev-container-features-test-lib
# Provides the 'check' and 'reportResults' commands.
# shellcheck disable=SC1091
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib. Syntax is...
# check <LABEL> <cmd> [args...]
check "validate aider installed" command -v aider
check "validate playwright installed" command -v playwright
check "validate CA stores distrust eMudhra intermediates" bash -c "\"\$(dirname \"\$(readlink -f \"\$(command -v aider)\")\")/python\" -c 'import certifi, pip; v = lambda s: tuple(map(int, s.split(\".\"))); assert v(certifi.__version__) >= (2026, 10, 19) and v(pip.__version__) >= (26, 2, 2)'"
check "validate hf-xet removed" bash -c "! \"\$(dirname \"\$(readlink -f \"\$(command -v aider)\")\")/python\" -c 'import hf_xet'"

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults