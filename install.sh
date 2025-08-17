#!/usr/bin/env bash
# /home/anish/workspace/dotfiles/install.sh
# Debian-oriented installer: nushell, oh-my-posh, pyenv, rust, atuin
set -euo pipefail

USER_HOME="${HOME}"
USER_NAME="$(id -un)"
SUDO_CMD="sudo"

# Helpers
info() { printf '\e[1;34m[INFO]\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33m[WARN]\e[0m %s\n' "$*"; }
err() { printf '\e[1;31m[ERROR]\e[0m %s\n' "$*" >&2; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

if ! command_exists sudo; then
    warn "sudo not found; running as-is. Some steps may require root privileges."
    SUDO_CMD=""
fi

# Ensure Debian-like
if [[ ! -f /etc/debian_version && ! -f /etc/lsb-release ]]; then
    warn "This script is intended for Debian-based systems. Continuing anyway."
fi

# Update and install packages required for building/installing tools
info "Updating apt and installing prerequisites..."
${SUDO_CMD} apt-get update -y
${SUDO_CMD} apt-get install -y --no-install-recommends \
    build-essential curl git ca-certificates pkg-config libssl-dev libbz2-dev \
    libreadline-dev libsqlite3-dev zlib1g-dev libncurses5-dev libncursesw5-dev \
    libffi-dev liblzma-dev make gcc g++ gnupg2 neovim

# 1) Install Rust (rustup) non-interactively if missing
if ! command_exists rustc || ! command_exists cargo; then
    info "Installing Rust (rustup)..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # Ensure cargo env is available in this shell
    if [[ -f "${USER_HOME}/.cargo/env" ]]; then
        # shellcheck source=/dev/null
        source "${USER_HOME}/.cargo/env"
    fi
else
    info "Rust already installed."
fi

# 2) Install nushell via apt (fury) if missing, fallback to cargo
if ! command_exists nu; then
    if command_exists apt-get; then
        info "Installing nushell from Fury apt repo..."
        # Add Fury GPG key and repository (use sudo if available)
        ${SUDO_CMD} bash -c 'set -e; curl -fsSL https://apt.fury.io/nushell/gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/fury-nushell.gpg'
        ${SUDO_CMD} bash -c 'echo "deb https://apt.fury.io/nushell/ /" > /etc/apt/sources.list.d/fury.list'
        ${SUDO_CMD} apt-get update -y
        if ${SUDO_CMD} apt-get install -y nushell; then
            info "nushell installed via apt."
        else
            warn "apt install nushell failed; falling back to cargo if available..."
            if command_exists cargo; then
                info "Installing nushell (nu) via cargo..."
                cargo install nu --locked || {
                    warn "cargo install nu failed; please install nushell manually."
                }
            else
                err "Neither apt nor cargo could install nushell."
            fi
        fi
    fi
else
    info "nushell (nu) already present."
fi

# 3) Install oh-my-posh (official install script) if missing
if ! command_exists oh-my-posh; then
    info "Installing oh-my-posh (via official install script)..."
    # installer supports -b to choose install dir
    curl -s https://ohmyposh.dev/install.sh | bash -s
else
    info "oh-my-posh already present."
fi

# 4) Install atuin via cargo if missing
if ! command_exists atuin; then
    if command_exists cargo; then
        info "Installing atuin via cargo..."
        cargo install atuin-cli --locked || cargo install atuin --locked || {
            warn "cargo install for atuin failed. You can install manually from https://github.com/ellie/atuin"
        }
        mkdir -p "${USER_HOME}/.local/share/atuin"
        if command_exists atuin; then
            info "Initializing atuin for nushell..."
            if atuin init nu --disable-up-arrow > "${USER_HOME}/.local/share/atuin/init.nu"; then
                TARGET_USER="${SUDO_USER:-${USER_NAME}}"
                chown "${TARGET_USER}:${TARGET_USER}" "${USER_HOME}/.local/share/atuin/init.nu" 2>/dev/null || true
                info "Written atuin nushell init to ${USER_HOME}/.local/share/atuin/init.nu"
            else
                warn "atuin init nu failed; skipping nushell initialization."
            fi
        else
            warn "atuin not found; cannot initialize for nushell."
        fi
    else
        warn "cargo not available; skipping atuin install."
    fi
else
    info "atuin already present."
fi

# 5) Install pyenv
PYENV_ROOT="${USER_HOME}/.pyenv"
if [[ ! -d "${PYENV_ROOT}" ]]; then
    info "Installing pyenv into ${PYENV_ROOT}..."
    git clone --depth 1 https://github.com/pyenv/pyenv.git "${PYENV_ROOT}"
else
    info "pyenv already installed at ${PYENV_ROOT}."
fi

# 6) Ensure PATH and init for pyenv and cargo -> add to ~/.profile if not present
PROFILE_FILE="${USER_HOME}/.profile"
add_line_if_missing() {
    local file="$1"; shift
    local line="$*"
    grep -Fxq "${line}" "${file}" 2>/dev/null || printf '%s\n' "${line}" >> "${file}"
}

info "Configuring environment in ${PROFILE_FILE} (adds pyenv and cargo to PATH)."
add_line_if_missing "${PROFILE_FILE}" 'export PATH="$HOME/.cargo/bin:$HOME/.pyenv/bin:$HOME/.pyenv/shims:$PATH"'
add_line_if_missing "${PROFILE_FILE}" 'if command -v pyenv 1>/dev/null 2>&1; then eval "$(pyenv init --path)"; fi'

# Install Carapace apt repo and package
CARAPACE_REPO='deb [trusted=yes] https://termux.carapace.sh termux extras'
FURY_LIST='/etc/apt/sources.list.d/fury.list'

if ! ${SUDO_CMD} grep -Fxq "${CARAPACE_REPO}" "${FURY_LIST}" 2>/dev/null; then
    info "Adding Carapace apt repo to ${FURY_LIST}..."
    ${SUDO_CMD} bash -c 'mkdir -p /etc/apt/sources.list.d'
    ${SUDO_CMD} bash -c 'echo "deb [trusted=yes] https://apt.fury.io/rsteube/ /" >> /etc/apt/sources.list.d/fury.list'
else
    info "Carapace repo already present in ${FURY_LIST}."
fi

info "Updating apt and installing carapace-bin..."
${SUDO_CMD} apt-get update -y
if ${SUDO_CMD} apt-get install -y --no-install-recommends carapace-bin; then
    info "carapace-bin installed."
else
    warn "Failed to install carapace-bin via apt. You may need to install it manually."
fi


# 7) Create basic nushell config to include these PATH entries for nushell sessions
NUSHELL_DIR="${USER_HOME}/.config/nushell"
mkdir -p "${NUSHELL_DIR}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}"
TARGET_USER="${SUDO_USER:-${USER_NAME}}"
DEST_CONFIG="${NUSHELL_CONFIG}"
NUSHELL_CONFIG="${NUSHELL_DIR}/config.nu"
DEST_ENV="${NUSHELL_DIR}/env.nu"

info "Copying config.nu and env.nu from ${REPO_ROOT} to ${NUSHELL_DIR}..."
cp -a "${REPO_ROOT}/config.nu" "${DEST_CONFIG}"
cp -a "${REPO_ROOT}/env.nu" "${DEST_ENV}"
chown "${TARGET_USER}:${TARGET_USER}" "${DEST_CONFIG}" "${DEST_ENV}" 2>/dev/null || true
info "Copied ${DEST_CONFIG} and ${DEST_ENV}."

# 8) Make nushell the default login shell
NU_PATH="$(command -v nu || true)"
if [[ -z "${NU_PATH}" ]]; then
    NU_PATH="${USER_HOME}/.cargo/bin/nu"
fi

if [[ -x "${NU_PATH}" ]]; then
    info "Setting nushell (${NU_PATH}) as a valid shell and changing default shell for ${USER_NAME}..."
    if ! grep -Fxq "${NU_PATH}" /etc/shells 2>/dev/null; then
        info "Adding ${NU_PATH} to /etc/shells"
        printf '%s\n' "${NU_PATH}" | ${SUDO_CMD} tee -a /etc/shells >/dev/null
    fi
    # Change default shell
    chsh -s "${NU_PATH}" "${USER_NAME}" || warn "chsh failed. You can run: chsh -s ${NU_PATH} ${USER_NAME}"
else
    warn "nushell binary not found or not executable at ${NU_PATH}; cannot set as default shell."
fi

info "Installation steps completed. Please log out and back in for environment changes to take effect."
info "Notes:"
info " - pyenv installed at ${PYENV_ROOT}. Add python versions via pyenv if needed."
info " - rust (rustup) installed; cargo binaries in ${USER_HOME}/.cargo/bin"
info " - If any step failed, rerun this script after resolving issues."

# Mention atuin initialization and ensure nushell loads it if present
if command_exists atuin && [[ -f "${USER_HOME}/.local/share/atuin/init.nu" ]]; then
    if ! grep -Fq 'source $env.HOME + "/.local/share/atuin/init.nu"' "${NUSHELL_CONFIG}" 2>/dev/null; then
        info "Configuring nushell to source atuin init..."
        cat >> "${NUSHELL_CONFIG}" <<'NU'
# Load atuin history integration for nushell
source $env.HOME + "/.local/share/atuin/init.nu"
NU
    else
        info "Nushell already configured to source atuin init."
    fi
else
    info "To enable atuin for nushell, run:"
    info "  atuin init nu --disable-up-arrow > ~/.local/share/atuin/init.nu"
    info "Then add the following to ${NUSHELL_CONFIG} if not added automatically:"
    info "  source \$env.HOME + \"/.local/share/atuin/init.nu\""
fi

exit 0