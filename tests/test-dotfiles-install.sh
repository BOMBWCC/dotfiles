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
assert_contains "$output" '@openai/codex-security'
assert_not_contains "$output" 'tmux'

output=$(sh "$INSTALLER" --dry-run --os linux full 2>&1)
assert_contains "$output" '@openai/codex-security'

# Regression guarded: extension groups remain opt-in.
output=$(sh "$INSTALLER" --dry-run --os macos extension dev 2>&1)
assert_contains "$output" 'uv'
assert_contains "$output" 'fnm'
assert_not_contains "$output" 'codex'

output=$(sh "$INSTALLER" --dry-run --os macos extension ai 2>&1)
assert_contains "$output" '@openai/codex'
assert_contains "$output" '@anthropic-ai/claude-code'
assert_contains "$output" 'https://omp.sh/install'

output=$(sh "$INSTALLER" --dry-run --os linux extension server 2>&1)
assert_contains "$output" 'openssh-server'

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

if [ "$failures" -ne 0 ]; then
  exit 1
fi

printf 'All dotfiles-install tests passed.\n'
