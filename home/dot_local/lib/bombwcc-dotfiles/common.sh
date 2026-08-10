say() { printf '%s\n' "$*"; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '+ '
    printf '%s ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

run_shell() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '+ sh -c %s\n' "$1"
  else
    sh -c "$1"
  fi
}

have() { command -v "$1" >/dev/null 2>&1; }

detect_os() {
  if [ -n "$OS_OVERRIDE" ]; then
    printf '%s\n' "$OS_OVERRIDE"
    return
  fi
  case "$(uname -s)" in
    Darwin) printf '%s\n' macos ;;
    Linux) printf '%s\n' linux ;;
    *) say "Unsupported operating system: $(uname -s)" >&2; exit 1 ;;
  esac
}

detect_linux_distro() {
  release_file=${1:-${DOTFILES_OS_RELEASE_FILE:-/etc/os-release}}
  [ -r "$release_file" ] || {
    say "Unsupported Linux system: cannot read $release_file" >&2
    return 1
  }

  DISTRO_NAME=""
  DISTRO_VERSION=""
  while IFS='=' read -r key value; do
    value=${value#\"}
    value=${value%\"}
    case "$key" in
      ID) DISTRO_NAME=$value ;;
      VERSION_ID) DISTRO_VERSION=$value ;;
    esac
  done < "$release_file"

  [ -n "$DISTRO_NAME" ] || {
    say "Unsupported Linux system: ID is missing from $release_file" >&2
    return 1
  }
}

validate_platform() {
  [ "$OS_NAME" = macos ] && return 0
  if [ "$OS_NAME" = linux ] && [ "$OS_OVERRIDE" = linux ] && [ "$DRY_RUN" -eq 1 ]; then
    DISTRO_NAME=apt-compatible
    DISTRO_VERSION=""
    return 0
  fi
  [ "$OS_NAME" = linux ] || return 0
  detect_linux_distro || return 1
  case "$DISTRO_NAME" in
    debian|ubuntu) return 0 ;;
    *) say "Unsupported Linux distribution: $DISTRO_NAME" >&2; return 1 ;;
  esac
}

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    run "$@"
  elif have sudo || [ "$DRY_RUN" -eq 1 ]; then
    run sudo "$@"
  else
    say "sudo is required: $*" >&2
    exit 1
  fi
}

ensure_homebrew() {
  have brew && return
  if [ "$DRY_RUN" -eq 1 ]; then
    say '+ install Homebrew'
    return
  fi
  say 'Installing Homebrew...'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

brew_formulae() { ensure_homebrew; run brew install "$@"; }
brew_casks() { ensure_homebrew; run brew install --cask "$@"; }

brew_optional() {
  ensure_homebrew
  for formula in "$@"; do
    if run brew install "$formula"; then
      :
    else
      say "SKIP: Homebrew formula $formula failed to install."
    fi
  done
}

apt_update() { as_root apt-get update; }
apt_packages() { as_root apt-get install -y "$@"; }

apt_optional() {
  for package in "$@"; do
    if [ "$DRY_RUN" -eq 1 ]; then
      as_root apt-get install -y "$package"
    elif apt-cache show "$package" >/dev/null 2>&1; then
      apt_packages "$package"
    else
      say "SKIP: $package is unavailable from this system's APT repositories."
    fi
  done
}
