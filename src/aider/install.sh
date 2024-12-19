#!/usr/bin/env bash
#
# This script installs Aider into a devcontainer.
#
# NOTE(ivy): @marcozac has some great optimizations for reducing layer size.
# See https://github.com/marcozac/devcontainer-features/blob/89d2a85f360a46eb74fc512080c19e10e40d357c/src/shellcheck/library_scripts.sh
#

[ -n "$DEBUG" ] && set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

# Version of Aider to install.
AIDER_VERSION="${VERSION:-latest}"

# Username to install Aider for.
USERNAME="${USERNAME:-"${_REMOTE_USER:-automatic}"}"

# Detect the username to use for the installation. This code is adapted from the
# official devcontainer Python feature.
detect_username() {
    local possible_users=(
        vscode
        node
        codespace
        "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)"
    )

    # Determine the appropriate non-root user.
    if [ "$USERNAME" = auto ] || [ "$USERNAME" = automatic ]; then
        USERNAME=

        for user in "${possible_users[@]}"; do
            if id -u "$user" &>/dev/null; then
                # Use the first user found.
                USERNAME="$user"
                break
            fi
        done

        if [ -z "$USERNAME" ]; then
            # If there is no non-root user, use the default username.
            USERNAME=root
        fi
    elif [ "$USERNAME" = none ] || ! id -u "$USERNAME" &>/dev/null; then
        # If the specified user does not exist or is unspecified, use default.
        USERNAME=root
    fi
}

# Main entrypoint
main() {
    if [ "$(id -u)" -ne 0 ]; then
        echo 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.' >&2
        exit 1
    fi

    detect_username
    
    if [ "$AIDER_VERSION" = latest ]; then
        echo "Installing latest Aider..."
        su -c 'pipx install aider-chat' "$USERNAME"
    else
        echo "Installing Aider version $AIDER_VERSION..."
        su -c "pipx install aider-chat==${AIDER_VERSION}" "$USERNAME"
    fi

    echo "Aider has been installed!"
}

main