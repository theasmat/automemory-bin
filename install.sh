#!/usr/bin/env bash
# ==============================================================================
# AutoMemory Universal Installer (macOS & Linux)
# https://github.com/theasmat/automemory
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/theasmat/automemory/main/install.sh | bash
# ==============================================================================

set -euo pipefail

# ANSI color codes
BOLD="$(tput bold 2>/dev/null || printf '')"
GREEN="$(tput setaf 2 2>/dev/null || printf '')"
YELLOW="$(tput setaf 3 2>/dev/null || printf '')"
CYAN="$(tput setaf 6 2>/dev/null || printf '')"
RED="$(tput setaf 1 2>/dev/null || printf '')"
RESET="$(tput sgr0 2>/dev/null || printf '')"

log_info() {
    printf "${CYAN}==>${RESET} ${BOLD}%s${RESET}\n" "$1"
}

log_success() {
    printf "${GREEN}✓${RESET} ${BOLD}%s${RESET}\n" "$1"
}

log_warn() {
    printf "${YELLOW}⚠${RESET} %s\n" "$1"
}

log_error() {
    printf "${RED}✗ Error:${RESET} %s\n" "$1" >&2
}

REPO="theasmat/automemory"
BINARY_NAME="automemory"
INSTALL_DIR="${HOME}/.cargo/bin"

if [ ! -d "${INSTALL_DIR}" ]; then
    mkdir -p "${INSTALL_DIR}"
fi

printf "\n"
printf "${BOLD}========================================================${RESET}\n"
printf "           ${YELLOW}AutoMemory Universal Installer${RESET}               \n"
printf "  Persistent Intelligence & Guardrails for AI Agents    \n"
printf "${BOLD}========================================================${RESET}\n\n"

# 1. Detect Operating System & Architecture
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "${OS}" in
    darwin)
        TARGET_OS="apple-darwin"
        ;;
    linux)
        TARGET_OS="unknown-linux-gnu"
        ;;
    *)
        log_error "Unsupported OS: ${OS}. On Windows, use PowerShell: irm https://raw.githubusercontent.com/theasmat/automemory/main/install.ps1 | iex"
        exit 1
        ;;
esac

case "${ARCH}" in
    x86_64|amd64)
        TARGET_ARCH="x86_64"
        ;;
    arm64|aarch64)
        TARGET_ARCH="aarch64"
        ;;
    *)
        log_error "Unsupported CPU architecture: ${ARCH}"
        exit 1
        ;;
esac

TARGET_TRIPLE="${TARGET_ARCH}-${TARGET_OS}"
log_info "Detected Platform: ${OS} (${ARCH}) -> Target: ${TARGET_TRIPLE}"

INSTALLED=false

# 2. Check if running inside repository clone
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
if [ -f "${SCRIPT_DIR}/Cargo.toml" ] && grep -q 'automemory' "${SCRIPT_DIR}/Cargo.toml" 2>/dev/null; then
    log_info "Detected local repository clone at ${SCRIPT_DIR}"
    if [ -f "${SCRIPT_DIR}/target/release/${BINARY_NAME}" ]; then
        log_info "Using existing local release binary..."
        cp "${SCRIPT_DIR}/target/release/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
        INSTALLED=true
    elif command -v cargo >/dev/null 2>&1; then
        log_info "Building release binary with Cargo..."
        (cd "${SCRIPT_DIR}" && cargo build --release)
        cp "${SCRIPT_DIR}/target/release/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
        INSTALLED=true
    fi
fi

# 3. If not installed from clone, try downloading pre-built GitHub release binary
if [ "${INSTALLED}" = false ]; then
    RELEASE_URL="https://github.com/${REPO}/releases/latest/download/automemory-${TARGET_TRIPLE}.tar.gz"
    TEMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'automemory-install')"
    trap 'rm -rf "${TEMP_DIR}"' EXIT

    log_info "Attempting to download pre-built release from GitHub..."
    if curl -fsSL -o "${TEMP_DIR}/automemory.tar.gz" "${RELEASE_URL}" 2>/dev/null; then
        tar -xzf "${TEMP_DIR}/automemory.tar.gz" -C "${TEMP_DIR}"
        if [ -f "${TEMP_DIR}/${BINARY_NAME}" ]; then
            chmod +x "${TEMP_DIR}/${BINARY_NAME}"
            mv "${TEMP_DIR}/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
            INSTALLED=true
            log_success "Downloaded pre-built binary for ${TARGET_TRIPLE}"
        fi
    fi
fi

# 4. If release binary download failed, fallback to cargo install
if [ "${INSTALLED}" = false ]; then
    if command -v cargo >/dev/null 2>&1; then
        log_info "Release asset not available for ${TARGET_TRIPLE}. Building via cargo install..."
        cargo install --git "https://github.com/${REPO}.git" --bin automemory
        INSTALLED=true
    else
        log_error "Could not download pre-built binary and Rust/Cargo is not installed."
        log_info "To install Rust and Cargo, run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        exit 1
    fi
fi

chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
log_success "Binary installed to: ${INSTALL_DIR}/${BINARY_NAME}"

# 5. Check PATH
case ":${PATH}:" in
    *:"${INSTALL_DIR}":*)
        ;;
    *)
        log_warn "${INSTALL_DIR} is not currently in your PATH!"
        printf "Add it to your shell profile by running:\n"
        printf "  export PATH=\"%s:\$PATH\"\n\n" "${INSTALL_DIR}"
        export PATH="${INSTALL_DIR}:${PATH}"
        ;;
esac

# 6. Verify Installation with doctor
log_info "Verifying AutoMemory health diagnostics..."
"${INSTALL_DIR}/${BINARY_NAME}" doctor || true

# 7. Offer to connect agents
printf "\n"
log_info "Configuring universal coding agent connectors..."
if "${INSTALL_DIR}/${BINARY_NAME}" connect all -g; then
    log_success "Connected 20 AI coding agents globally!"
fi

printf "\n"
printf "${BOLD}${GREEN}========================================================${RESET}\n"
printf "  ${BOLD}${GREEN}AutoMemory was successfully installed!${RESET}               \n"
printf "  Version: $(${INSTALL_DIR}/${BINARY_NAME} --version)    \n"
printf "${BOLD}${GREEN}========================================================${RESET}\n\n"
printf "Quick commands to get started:\n"
printf "  ${CYAN}automemory serve${RESET}        Launch local web dashboard at http://127.0.0.1:4545\n"
printf "  ${CYAN}automemory doctor${RESET}       Run system health checks\n"
printf "  ${CYAN}automemory connect all${RESET}  Connect all 20 agents in your current workspace\n"
printf "  ${CYAN}automemory proposal summary${RESET} View review proposal metrics\n\n"
