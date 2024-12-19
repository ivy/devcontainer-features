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
    elif [ "$USERNAME" = "none" ] || ! id -u "$USERNAME" &>/dev/null; then
        # If the specified user does not exist or is unspecified, use default.
        USERNAME=root
    fi
}

# Install Aider on Debian-based systems.
install_debian() {
    if ! dpkg -l pipx &>/dev/null; then
        echo "pipx not found. Installing..."
        apt-get update && apt-get install -y pipx
    fi

    if [ "$AIDER_VERSION" = latest ]; then
        echo "Installing latest Aider..."
        su -c 'pipx install aider-chat' "$USERNAME"
    else
        echo "Installing Aider version $AIDER_VERSION..."
        su -c "pipx install aider-chat==${AIDER_VERSION}" "$USERNAME"
    fi
}

# Clean up
clean_up() {
    case "$ADJUSTED_ID" in
        debian)
            rm -rf /var/lib/apt/lists/*
            ;;
        *)
            echo "Unsupported distribution: $ADJUSTED_ID" >&2
            exit 1
            ;;
    esac
}

# Main entrypoint
main() {
    if [ "$(id -u)" -ne 0 ]; then
        echo 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.' >&2
        exit 1
    fi

    detect_username

    if [ ! -r /etc/os-release ]; then
        echo "Unsupported distribution: Unknown" >&2
        exit 1
    fi

    # Read /etc/os-release to identify the Linux distribution
    # shellcheck disable=SC1091
    source /etc/os-release

    # Ubuntu and other Debian-derivatives should be treated as Debian
    if [ "${ID_LIKE:-}" = debian ]; then
        ADJUSTED_ID=debian
    else
        ADJUSTED_ID="${ID:-}"
    fi

    case "$ADJUSTED_ID" in
        debian|ubuntu)
            install_debian
            ;;
        *)
            echo "Unsupported distribution: $ADJUSTED_ID" >&2
            exit 1
            ;;
    esac

    clean_up

    echo "Aider has been installed!"
}

main