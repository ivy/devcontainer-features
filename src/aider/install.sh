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

# Whether to install Playwright for web scraping.
INSTALLPLAYWRIGHT="${INSTALLPLAYWRIGHT:-true}"

# Browsers to install for Playwright.
INSTALLPLAYWRIGHTBROWSERS="${INSTALLPLAYWRIGHTBROWSERS:-chromium}"

# Username to install Aider for.
USERNAME="${USERNAME:-"${_REMOTE_USER:-automatic}"}"

# Detect the Linux distribution ID. Adjust to account for derivatives.
detect_adjusted_id() {
    if [ ! -r /etc/os-release ]; then
        echo "WARN: Unable to detect the OS release." >&2
        return
    fi

    # shellcheck disable=SC1091
    source /etc/os-release

    case "${ID:-unknown}" in
        debian|ubuntu)
            ADJUSTED_ID=debian
            ;;
        *)
            ADJUSTED_ID="${ID:-unknown}"
            ;;
    esac
}

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

as_user() {
    # HACK(ivy): PS1=true works around an edge case where pipx isn't added
    # to the PATH. This happens with the `mcr.microsoft.com/devcontainers/base:ubuntu`
    # image which includes a check at the top of /etc/bash.bashrc which
    # returns in non-interactive shells.
    if [ "$USERNAME" = root ]; then
        bash -c "PS1=true; . /etc/bash.bashrc || true; $1"
    else
        su - "$USERNAME" bash -c "PS1=true; . /etc/bash.bashrc || true; $1"
    fi
}

# Install Aider using pipx.
install_aider() {
    if [ "$AIDER_VERSION" = latest ]; then
        as_user 'pipx install aider-chat'
    else
        as_user "pipx install aider-chat==${AIDER_VERSION}"
    fi
}

install_playwright() {
    local browsers

    if [ "$INSTALLPLAYWRIGHT" != true ]; then
        return
    fi

    as_user 'pipx inject --include-apps --include-deps aider-chat playwright'

    if [ -n "$INSTALLPLAYWRIGHTBROWSERS" ]; then
        # Split $INSTALLPLAYWRIGHTBROWSERS by comma into an array and bind it to $browsers.
        IFS=, read -r -a browsers <<< "$INSTALLPLAYWRIGHTBROWSERS"

        echo "Installing Playwright browsers: $INSTALLPLAYWRIGHTBROWSERS..."
        as_user "playwright install --with-deps ${browsers[*]}"
    fi
}

# Clean up caches and temporary files.
clean_up() {
    # Clean up pipx cache.
    as_user 'pipx runpip aider-chat cache purge'

    if [ "$ADJUSTED_ID" = debian ]; then
        rm -fr /var/lib/apt/lists/*
    fi
}

# Main entrypoint
main() {
    if [ "$(id -u)" -ne 0 ]; then
        echo 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.' >&2
        exit 1
    fi

    detect_adjusted_id
    detect_username
    install_aider
    install_playwright
    clean_up

    echo "Aider has been installed!"
}

main