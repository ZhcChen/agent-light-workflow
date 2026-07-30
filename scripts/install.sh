#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${AGENT_LIGHT_WORKFLOW_REPO_URL:-https://github.com/ZhcChen/agent-light-workflow.git}"
INSTALL_ROOT="${AGENT_LIGHT_WORKFLOW_INSTALL_ROOT:-${HOME}/.agent-light-workflow}"
REPO_DIR="${INSTALL_ROOT}/repo"
USER_BIN="${AGENT_LIGHT_WORKFLOW_USER_BIN:-${HOME}/.local/bin}"
WRAPPER_PATH="${USER_BIN}/agent-light-workflow"
SKIP_PATH_UPDATE="${AGENT_LIGHT_WORKFLOW_SKIP_PATH_UPDATE:-0}"

log() {
  printf '==> %s\n' "$*"
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    sudo "$@"
    return 0
  fi

  fail "This installer needs root privileges to install missing system packages. Install sudo or run as root."
}

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  fail "Homebrew is required on macOS when git is missing. Install Homebrew first, then rerun this script."
}

install_git_macos() {
  if command -v git >/dev/null 2>&1; then
    return 0
  fi

  ensure_brew
  log "Installing git via Homebrew"
  brew install git
}

install_git_linux() {
  if command -v git >/dev/null 2>&1; then
    return 0
  fi

  if command -v apt-get >/dev/null 2>&1; then
    log "Installing git with apt-get"
    run_as_root apt-get update
    run_as_root apt-get install -y git
    return 0
  fi

  if command -v dnf >/dev/null 2>&1; then
    log "Installing git with dnf"
    run_as_root dnf install -y git
    return 0
  fi

  if command -v yum >/dev/null 2>&1; then
    log "Installing git with yum"
    run_as_root yum install -y git
    return 0
  fi

  if command -v pacman >/dev/null 2>&1; then
    log "Installing git with pacman"
    run_as_root pacman -Sy --noconfirm --needed git
    return 0
  fi

  if command -v zypper >/dev/null 2>&1; then
    log "Installing git with zypper"
    run_as_root zypper --non-interactive install git
    return 0
  fi

  if command -v apk >/dev/null 2>&1; then
    log "Installing git with apk"
    run_as_root apk add git
    return 0
  fi

  fail "Unsupported Linux package manager. Install git manually, then rerun this script."
}

ensure_git() {
  case "$(uname -s)" in
    Darwin)
      install_git_macos
      ;;
    Linux)
      install_git_linux
      ;;
    *)
      fail "Unsupported operating system: $(uname -s)"
      ;;
  esac
}

clone_or_update_repo() {
  mkdir -p "$INSTALL_ROOT"

  if [[ -d "$REPO_DIR/.git" ]]; then
    log "Updating existing repository in $REPO_DIR"
    git -C "$REPO_DIR" pull --ff-only
    return 0
  fi

  rm -rf "$REPO_DIR"
  log "Cloning repository into $REPO_DIR"
  git clone "$REPO_URL" "$REPO_DIR"
}

create_wrapper() {
  mkdir -p "$USER_BIN"

  cat > "$WRAPPER_PATH" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec "$REPO_DIR/init.sh" "\$@"
EOF

  chmod +x "$WRAPPER_PATH"
  log "Installed command wrapper at $WRAPPER_PATH"
}

ensure_path() {
  local shell_rc
  local line

  if [[ "$SKIP_PATH_UPDATE" = "1" ]]; then
    log "Skipping PATH update because AGENT_LIGHT_WORKFLOW_SKIP_PATH_UPDATE=1"
    return 0
  fi

  if printf '%s' "${PATH:-}" | tr ':' '\n' | grep -Fx "$USER_BIN" >/dev/null 2>&1; then
    return 0
  fi

  line="export PATH=\"$USER_BIN:\$PATH\""
  shell_rc="$HOME/.zshrc"
  if [[ "${SHELL:-}" == */bash ]]; then
    shell_rc="$HOME/.bashrc"
  fi

  if [[ ! -f "$shell_rc" ]] || ! grep -Fqx "$line" "$shell_rc"; then
    printf '\n# Added by agent-light-workflow\n%s\n' "$line" >> "$shell_rc"
    log "Added $USER_BIN to PATH in $shell_rc"
  fi

  log "Open a new shell, or run: export PATH=\"$USER_BIN:\$PATH\""
}

main() {
  ensure_git
  clone_or_update_repo
  create_wrapper
  ensure_path

  log "Done"
  log "Verify with: agent-light-workflow --help"
  log "Initialize with: agent-light-workflow ."
}

main "$@"
