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

have() { command -v "$1" >/dev/null 2>&1; }

# Download an installer script completely before running it, so a truncated
# transfer can never execute a partial script. The script is fed to the given
# command on stdin, matching the vendors' documented `curl ... | sh` usage.
run_remote_script() {
  script_url=$1
  shift
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '+ curl -fsSL %s | %s\n' "$script_url" "$*"
    return
  fi

  script_file=$(mktemp "${TMPDIR:-/tmp}/dotfiles-installer.XXXXXX")
  if ! curl --proto '=https' --tlsv1.2 -fsSL "$script_url" -o "$script_file"; then
    rm -f "$script_file"
    say "Failed to download installer: $script_url" >&2
    return 1
  fi
  script_status=0
  "$@" < "$script_file" || script_status=$?
  rm -f "$script_file"
  return "$script_status"
}

# Download the asset of a repository's latest GitHub release whose name matches
# an extended regular expression, and verify it against the SHA-256 digest that
# GitHub publishes for the asset. Prints nothing and fails when the release
# metadata, the digest, or the download cannot be confirmed.
github_release_download() {
  release_repo=$1
  asset_pattern=$2
  asset_dest=$3

  have jq || { say 'jq is required to verify GitHub release downloads.' >&2; return 1; }
  release_json=$(curl --proto '=https' --tlsv1.2 -fsSL \
    -H 'Accept: application/vnd.github+json' \
    "https://api.github.com/repos/$release_repo/releases/latest") || {
    say "Could not read the latest $release_repo release metadata." >&2
    return 1
  }
  asset_record=$(printf '%s\n' "$release_json" | jq -r --arg pattern "$asset_pattern" '
    [.assets[] | select(.name | test($pattern))][0]
    | select(. != null)
    | "\(.browser_download_url) \(.digest // "")"
  ') || asset_record=""
  asset_url=${asset_record% *}
  asset_digest=${asset_record##* }

  [ -n "$asset_record" ] || { say "No $release_repo release asset matches $asset_pattern." >&2; return 1; }
  case "$asset_digest" in
    sha256:????????????????????????????????????????????????????????????????) asset_digest=${asset_digest#sha256:} ;;
    *) say "The $release_repo release does not publish a SHA-256 digest; refusing to install it." >&2; return 1 ;;
  esac
  case "$asset_url" in
    "https://github.com/$release_repo/releases/download/"*) ;;
    *) say "Unexpected $release_repo download URL: $asset_url" >&2; return 1 ;;
  esac

  curl --proto '=https' --tlsv1.2 -fL "$asset_url" -o "$asset_dest" || return 1
  actual_digest=$(sha256_file "$asset_dest") || return 1
  if [ "$actual_digest" != "$asset_digest" ]; then
    rm -f "$asset_dest"
    say "SHA-256 mismatch for $asset_url; the download was discarded." >&2
    return 1
  fi
}

sha256_file() {
  if have sha256sum; then
    sha256sum "$1" | sed 's/ .*//'
  else
    shasum -a 256 "$1" | sed 's/ .*//'
  fi
}

summary_reset() {
  SUMMARY_ITEMS=""
  SUMMARY_ACTIVE=0
}

summary_add() {
  record="$1|$2|${3:-}"
  if [ -n "$SUMMARY_ITEMS" ]; then
    SUMMARY_ITEMS="$SUMMARY_ITEMS
$record"
  else
    SUMMARY_ITEMS=$record
  fi
}

summary_version() {
  command_name=$1
  version_flag=$2
  [ -n "$version_flag" ] || return 0

  summary_status_file=$(mktemp "${TMPDIR:-/tmp}/dotfiles-summary-status.XXXXXX" 2>/dev/null) || return 0
  version_output=$(
    {
      "$command_name" "$version_flag" 2>&1
      printf '%s\n' "$?" > "$summary_status_file"
    } | dd bs=1 count=200 2>/dev/null
  )

  summary_probe_status=""
  if [ -r "$summary_status_file" ]; then
    IFS= read -r summary_probe_status < "$summary_status_file" || summary_probe_status=""
  fi
  rm -f "$summary_status_file"
  [ "$summary_probe_status" = 0 ] || return 0
  printf '%s\n' "$version_output" | sed -n '1{p;q;}'
}

summary_render() {
  original_status=$1
  [ -n "${SUMMARY_ITEMS:-}" ] || return 0
  say ''
  say 'Installation summary'

  if [ "$DRY_RUN" -eq 1 ]; then
    say 'Planned:'
    printf '%s\n' "$SUMMARY_ITEMS" | while IFS='|' read -r label command_name version_flag; do
      [ -n "$label" ] && say "  - $label"
    done
  else
    say 'Ready:'
    printf '%s\n' "$SUMMARY_ITEMS" | while IFS='|' read -r label command_name version_flag; do
      if have "$command_name"; then
        version=$(summary_version "$command_name" "$version_flag" || true)
        if [ -n "$version" ]; then say "  - $label — $version"; else say "  - $label"; fi
      fi
    done
    say 'Missing:'
    printf '%s\n' "$SUMMARY_ITEMS" | while IFS='|' read -r label command_name version_flag; do
      have "$command_name" || say "  - $label"
    done
  fi

  if [ "$original_status" -eq 0 ]; then
    say 'Installation completed.'
  else
    say 'Installation did not complete.'
  fi
}

summary_on_exit() {
  original_status=$?
  trap - 0
  set +e
  if [ "${SUMMARY_ACTIVE:-0}" -eq 1 ]; then summary_render "$original_status"; fi
  exit "$original_status"
}

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
