#!/bin/sh
set -eu

INSTALLER="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)/home/dot_local/bin/executable_dotfiles-install"
LIB_ROOT="$(dirname "$INSTALLER")/../lib/bombwcc-dotfiles"
failures=0

assert_contains() {
  output=$1
  expected=$2
  case "$output" in
    *"$expected"*) ;;
    *)
      printf 'FAIL: expected output to contain: %s\n' "$expected" >&2
      failures=$((failures + 1))
      ;;
  esac
}

assert_not_contains() {
  output=$1
  unexpected=$2
  case "$output" in
    *"$unexpected"*)
      printf 'FAIL: expected output not to contain: %s\n' "$unexpected" >&2
      failures=$((failures + 1))
      ;;
    *) ;;
  esac
}

assert_equals() {
  actual=$1
  expected=$2
  if [ "$actual" != "$expected" ]; then
    printf 'FAIL: expected <%s>, got <%s>\n' "$expected" "$actual" >&2
    failures=$((failures + 1))
  fi
}

assert_file() {
  file=$1
  if [ ! -f "$file" ]; then
    printf 'FAIL: expected file to exist: %s\n' "$file" >&2
    failures=$((failures + 1))
  fi
}

# Regression guarded: the entry point loads focused installer modules.
assert_file "$LIB_ROOT/common.sh"
assert_file "$LIB_ROOT/profiles/minimal.sh"
assert_file "$LIB_ROOT/profiles/full.sh"
assert_file "$LIB_ROOT/extensions/dev.sh"
assert_file "$LIB_ROOT/extensions/ai.sh"
assert_file "$LIB_ROOT/extensions/server.sh"
assert_file "$LIB_ROOT/extensions/mac.sh"
assert_file "$LIB_ROOT/installers/oh-my-pi.sh"
assert_file "$LIB_ROOT/installers/codex-security.sh"
assert_file "$LIB_ROOT/installers/herdr.sh"

# Linux distribution detection accepts Debian and Ubuntu release metadata.
# A missing detect_linux_distro implementation would make these assertions fail.
test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT HUP INT TERM

printf 'ID=debian\nVERSION_ID="12"\n' > "$test_tmp/debian-release"
output=$(
  sh -c '. "$1"; detect_linux_distro "$2"; printf "%s|%s\\n" "$DISTRO_NAME" "$DISTRO_VERSION"' \
    sh "$LIB_ROOT/common.sh" "$test_tmp/debian-release"
)
assert_equals "$output" 'debian|12'

printf 'ID=ubuntu\nVERSION_ID="24.04"\n' > "$test_tmp/ubuntu-release"
output=$(
  sh -c '. "$1"; detect_linux_distro "$2"; printf "%s|%s\\n" "$DISTRO_NAME" "$DISTRO_VERSION"' \
    sh "$LIB_ROOT/common.sh" "$test_tmp/ubuntu-release"
)
assert_equals "$output" 'ubuntu|24.04'

# Linux in a real run validates the detected distribution even when --os linux
# is present. This fixture keeps that boundary test independent of the host.
output=$(
  sh -c '. "$1"; DRY_RUN=0; OS_NAME=linux; OS_OVERRIDE=linux; DOTFILES_OS_RELEASE_FILE=$2; validate_platform; printf "%s|%s\\n" "$DISTRO_NAME" "$DISTRO_VERSION"' \
    sh "$LIB_ROOT/common.sh" "$test_tmp/debian-release"
)
assert_equals "$output" 'debian|12'

printf 'ID=fedora\nVERSION_ID="42"\n' > "$test_tmp/fedora-release"
if output=$(sh -c '. "$1"; DRY_RUN=0; OS_NAME=linux; OS_OVERRIDE=""; DOTFILES_OS_RELEASE_FILE=$2; validate_platform' \
  sh "$LIB_ROOT/common.sh" "$test_tmp/fedora-release" 2>&1); then
  printf 'FAIL: Fedora platform validation unexpectedly succeeded\n' >&2
  failures=$((failures + 1))
else
  assert_contains "$output" 'Unsupported Linux distribution: fedora'
fi

# Regression guarded: macOS minimal must never install tmux.
output=$(sh "$INSTALLER" --dry-run --os macos minimal 2>&1)
assert_contains "$output" 'brew install'
assert_contains "$output" 'btop'
assert_contains "$output" 'fzf'
assert_contains "$output" 'bat cache --build'
assert_not_contains "$output" 'tmux'
assert_not_contains "$output" '@openai/codex-security'

# Regression guarded: Linux minimal still includes tmux.
output=$(sh "$INSTALLER" --dry-run --os linux minimal 2>&1)
assert_contains "$output" 'apt-get install'
assert_contains "$output" 'tmux'
assert_contains "$output" 'fzf'
assert_contains "$output" 'bat cache --build'

# Regression guarded: full includes both minimum and full-only tools.
output=$(sh "$INSTALLER" --dry-run --os macos full 2>&1)
assert_contains "$output" 'starship'
assert_contains "$output" 'lazygit'
assert_contains "$output" 'doggo'
assert_contains "$output" '@openai/codex-security'
assert_not_contains "$output" 'tmux'

output=$(sh "$INSTALLER" --dry-run --os linux full 2>&1)
assert_contains "$output" '@openai/codex-security'
# Removing sd from install_full_linux's optional APT packages must fail this
# behavior check even though sd remains present in the summary manifest.
assert_contains "$output" 'apt-get install -y sd'

# Regression guarded: extension groups remain opt-in.
output=$(sh "$INSTALLER" --dry-run --os macos extension dev 2>&1)
assert_contains "$output" 'uv'
assert_contains "$output" 'fnm'
assert_not_contains "$output" 'codex'

output=$(sh "$INSTALLER" --dry-run --os macos extension ai 2>&1)
assert_contains "$output" '@openai/codex'
assert_contains "$output" '@anthropic-ai/claude-code'
assert_contains "$output" 'https://omp.sh/install'
assert_contains "$output" 'brew install herdr'

output=$(sh "$INSTALLER" --dry-run --os linux extension ai 2>&1)
assert_contains "$output" 'https://herdr.dev/install.sh'

output=$(sh "$INSTALLER" --dry-run --os linux extension server 2>&1)
assert_contains "$output" 'openssh-server'
assert_contains "$output" 'does not explicitly enable or start services or modify firewall rules'
assert_contains "$output" 'Debian package defaults may still enable or start services.'

# Activating the Linux-only server summary before its platform guard must fail:
# unsupported macOS runs report only the skip, not a successful Linux plan.
output=$(sh "$INSTALLER" --dry-run --os macos extension server 2>&1)
assert_contains "$output" 'SKIP: the server extension only applies to Linux.'
assert_not_contains "$output" 'Installation summary'
assert_not_contains "$output" 'Planned:'
assert_not_contains "$output" 'Installation completed.'

# Every Debian-supported profile and extension reports its command manifest.
output=$(sh "$INSTALLER" --dry-run --os linux minimal 2>&1)
assert_contains "$output" 'Installation summary'
assert_contains "$output" 'Planned:'
assert_contains "$output" '  - Zsh'
assert_contains "$output" '  - fd'
assert_contains "$output" '  - bat'
assert_contains "$output" 'Installation completed.'

output=$(sh "$INSTALLER" --dry-run --os linux full 2>&1)
assert_contains "$output" '  - Zsh'
assert_contains "$output" '  - SQLite'
assert_contains "$output" '  - Codex Security'

output=$(sh "$INSTALLER" --dry-run --os linux extension dev 2>&1)
assert_contains "$output" '  - Python'
assert_contains "$output" '  - uv'
assert_contains "$output" '  - Node.js'

output=$(sh "$INSTALLER" --dry-run --os linux extension ai 2>&1)
assert_contains "$output" '  - Codex CLI'
assert_contains "$output" '  - Claude Code'
assert_contains "$output" '  - Oh My Pi'
assert_contains "$output" '  - Herdr'

output=$(sh "$INSTALLER" --dry-run --os linux extension server 2>&1)
assert_contains "$output" '  - OpenSSH Server'
assert_contains "$output" '  - Docker'
assert_contains "$output" 'docker-compose-v2'

# A required-package failure retains the APT status and renders the failure
# summary without contacting the network.
failure_root="$test_tmp/failure-root"
mkdir -p "$failure_root/bin" "$failure_root/lib" "$failure_root/fake-bin"
cp "$INSTALLER" "$failure_root/bin/dotfiles-install"
cp -R "$LIB_ROOT" "$failure_root/lib/bombwcc-dotfiles"
printf '#!/bin/sh\nexit 23\n' > "$failure_root/fake-bin/apt-get"
printf '#!/bin/sh\nexec "$@"\n' > "$failure_root/fake-bin/sudo"
printf 'ID=debian\nVERSION_ID="12"\n' > "$failure_root/debian-release"
chmod +x "$failure_root/fake-bin/apt-get" "$failure_root/fake-bin/sudo"

if output=$(PATH="$failure_root/fake-bin:/usr/bin:/bin" \
  DOTFILES_OS_RELEASE_FILE="$failure_root/debian-release" \
  sh "$failure_root/bin/dotfiles-install" --os linux minimal 2>&1); then
  printf 'FAIL: required APT failure unexpectedly succeeded\n' >&2
  failures=$((failures + 1))
else
  status=$?
  assert_equals "$status" 23
  assert_contains "$output" 'Installation did not complete.'
fi

# Regression guarded: the macOS extension installs the Rime frontend.
output=$(sh "$INSTALLER" --dry-run --os macos extension mac 2>&1)
assert_contains "$output" 'squirrel'
assert_contains "$output" 'font-meslo-lg-nerd-font'
assert_contains "$output" 'font-noto-serif-cjk-sc'

# Regression guarded: repair/profile state was removed; rerun a profile instead.
if output=$(sh "$INSTALLER" --dry-run --os macos repair 2>&1); then
  printf 'FAIL: repair command unexpectedly succeeded\n' >&2
  failures=$((failures + 1))
else
  assert_contains "$output" 'Unknown command: repair'
fi
assert_not_contains "$(cat "$INSTALLER")" 'install-profile'

# Regression guarded: one unavailable optional Homebrew formula must not stop
# later full-profile tools from being attempted.
output=$(
  sh -c '
    . "$1"
    DRY_RUN=0
    brew() {
      [ "$1" = install ] || return 0
      [ "$2" = broken ] && return 1
      printf "installed:%s\n" "$2"
    }
    brew_optional broken working
  ' sh "$LIB_ROOT/common.sh" 2>&1 || true
)
assert_contains "$output" 'SKIP: Homebrew formula broken failed to install.'
assert_contains "$output" 'installed:working'

# Summary uses the command manifest to distinguish ready and missing tools.
fake_bin="$test_tmp/bin"
mkdir -p "$fake_bin"
printf '#!/bin/sh\nprintf "ready-tool 1.2.3\\n"\n' > "$fake_bin/ready-tool"
printf '#!/bin/sh\nprintf "probe failed loudly\\n"\nexit 19\n' > "$fake_bin/failing-version"
printf '#!/bin/sh\nawk '\''BEGIN { printf "noisy-tool 9.8.7 "; for (i = 0; i < 400; i++) printf "x"; printf "\\nignored detail\\n" }'\''\n' > "$fake_bin/noisy-version"
printf '#!/bin/sh\ntrap '\''exit 141'\'' 13\ni=0\nwhile [ "$i" -lt 2000 ]; do\n  printf "streaming-noise-012345678901234567890123456789012345678901234567890123456789\\n"\n  i=$((i + 1))\ndone\n: > "$STREAM_MARKER"\n' > "$fake_bin/streaming-version"
chmod +x "$fake_bin/ready-tool"
chmod +x "$fake_bin/failing-version" "$fake_bin/noisy-version" "$fake_bin/streaming-version"

output=$(
  PATH="$fake_bin:/usr/bin:/bin" sh -c '
    . "$1"
    DRY_RUN=0
    summary_reset
    summary_add "Ready Tool" ready-tool --version
    summary_add "Missing Tool" missing-tool --version
    summary_render 0
  ' sh "$LIB_ROOT/common.sh"
)
assert_contains "$output" 'Installation summary'
assert_contains "$output" 'Ready:'
assert_contains "$output" 'Ready Tool — ready-tool 1.2.3'
assert_contains "$output" 'Missing:'
assert_contains "$output" 'Missing Tool'
assert_contains "$output" 'Installation completed.'

# Treat version probes as best-effort metadata: a failing command contributes
# no error text, and a successful but noisy command is bounded to one short line.
output=$(
  PATH="$fake_bin:/usr/bin:/bin" sh -c '. "$1"; summary_version failing-version --version' \
    sh "$LIB_ROOT/common.sh"
)
assert_equals "$output" ''

output=$(
  PATH="$fake_bin:/usr/bin:/bin" sh -c '. "$1"; summary_version noisy-version --version' \
    sh "$LIB_ROOT/common.sh"
)
assert_contains "$output" 'noisy-tool 9.8.7'
assert_not_contains "$output" 'ignored detail'
if [ "${#output}" -gt 200 ]; then
  printf 'FAIL: expected noisy version output to be at most 200 characters, got %s\n' "${#output}" >&2
  failures=$((failures + 1))
fi

# Draining a streaming probe to EOF must fail this check: once the summary has
# enough metadata, it closes the stream and treats the interrupted probe as
# unavailable rather than waiting for or displaying its unverified output.
stream_marker="$test_tmp/stream-consumed"
output=$(
  PATH="$fake_bin:/usr/bin:/bin" STREAM_MARKER="$stream_marker" \
    sh -c '. "$1"; summary_version streaming-version --version' sh "$LIB_ROOT/common.sh"
)
assert_equals "$output" ''
if [ -e "$stream_marker" ]; then
  printf 'FAIL: expected streaming version probe to stop before consuming its tail\n' >&2
  failures=$((failures + 1))
fi

output=$(
  sh -c '. "$1"; DRY_RUN=1; summary_reset; summary_add "Git" git --version; summary_render 0' \
    sh "$LIB_ROOT/common.sh"
)
assert_contains "$output" 'Planned:'
assert_not_contains "$output" 'Ready:'

if output=$(sh -c '. "$1"; DRY_RUN=0; summary_reset; summary_add "Git" git --version; summary_render 7; exit 7' \
  sh "$LIB_ROOT/common.sh" 2>&1); then
  printf 'FAIL: summary failure fixture unexpectedly succeeded\n' >&2
  failures=$((failures + 1))
else
  assert_contains "$output" 'Installation did not complete.'
fi

if [ "$failures" -ne 0 ]; then
  exit 1
fi

printf 'All dotfiles-install tests passed.\n'
