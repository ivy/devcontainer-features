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

# Minimum versions that distrust the compromised eMudhra intermediates
# (CVE-2026-111943). Aider pins exact versions older than these.
MIN_CERTIFI_VERSION=2026.10.19
MIN_PIP_VERSION=26.2.2

# Python for Aider's venv. Every aider-chat release requires Python <3.13, and
# no 3.12 release is on the CVE-2026-111943 fixed list. uv 0.13.5 installs
# 3.12.15 from python-build-standalone 20261021, which bundles pip 26.2.2 and
# certifi 2026.10.19: the change CPython shipped as its fix in 3.13.17.
AIDER_PYTHON_VERSION=3.12.15

# uv, which installs that Python. 0.13.5 distrusts the compromised eMudhra
# intermediates (CVE-2026-111943).
UV_VERSION=0.13.5

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

# Upgrade the system CA bundle so it distrusts the compromised eMudhra
# intermediates (CVE-2026-111943).
upgrade_ca_certificates() {
    if [ "$ADJUSTED_ID" != debian ]; then
        return
    fi

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --only-upgrade ca-certificates
}

# Install a uv-managed Python for Aider, since the image's may be too new.
install_aider_python() {
    local uv="pipx run --spec uv==${UV_VERSION} uv"

    as_user "${uv} python install --no-bin ${AIDER_PYTHON_VERSION}"
    AIDER_PYTHON="$(as_user "${uv} python find --managed-python ${AIDER_PYTHON_VERSION}" | tail -n 1)"
}

# Install Aider using pipx.
install_aider() {
    local pipx_install="pipx install --python '${AIDER_PYTHON}'"

    if [ "$AIDER_VERSION" = latest ]; then
        as_user "${pipx_install} aider-chat"
    else
        as_user "${pipx_install} aider-chat==${AIDER_VERSION}"
    fi
}

# Override Aider's pinned certifi and pip, whose bundled CA stores trust the
# compromised eMudhra intermediates (CVE-2026-111943). Remove hf-xet, whose
# compiled-in webpki-roots store has no fixed release yet; it is optional.
upgrade_bundled_ca_stores() {
    as_user "pipx runpip aider-chat install --upgrade 'certifi>=${MIN_CERTIFI_VERSION}' 'pip>=${MIN_PIP_VERSION}'"
    as_user 'pipx runpip aider-chat uninstall -y hf-xet'
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
    upgrade_ca_certificates
    install_aider_python
    install_aider
    install_playwright
    upgrade_bundled_ca_stores
    clean_up

    echo "Aider has been installed!"
}

main