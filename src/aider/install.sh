#!/usr/bin/env bash

[ -n "$DEBUG" ] && set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

# Version of Aider to install.
AIDER_VERSION="${VERSION:-latest}"

install_debian() {
    if ! dpkg -l pipx &> /dev/null; then
        echo "pipx not found. Installing..."
        apt-get update && apt-get install -y pipx
    fi

    if [ "$AIDER_VERSION" = latest ]; then
        echo "Installing latest Aider..."
        su -c 'pipx install aider-chat' vscode
    else
        echo "Installing Aider version $AIDER_VERSION..."
        su -c "pipx install aider-chat==${AIDER_VERSION}" vscode
    fi
}

if [ ! -r /etc/os-release ]; then
    echo "Unsupported distribution: Unknown" >&2
    exit 1
fi

# Read /etc/os-release to identify the Linux distribution
source /etc/os-release

# Ubuntu and other Debian-derivatives should be treated as Debian
if [ "${ID_LIKE:-}" = debian ]; then
    ID=debian
else
    ID="${ID:-}"
fi

case "$ID" in
    debian|ubuntu)
        install_debian
        ;;
    *)
        echo "Unsupported distribution: $ID" >&2
        exit 1
        ;;
esac