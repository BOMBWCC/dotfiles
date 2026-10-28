#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MACOS_CONFIG="$REPO_ROOT/home/dot_config/zsh/platform/macos.zsh"
fixture_home=$(mktemp -d "${TMPDIR:-/tmp}/ssh-agent-test.XXXXXX")
trap 'rm -rf "$fixture_home"' EXIT HUP INT TERM

selected_socket() {
  HOME="$fixture_home" SSH_AUTH_SOCK=/tmp/system-agent.sock zsh -f -c '
    path=(/usr/bin /bin)
    source "$1"
    print -r -- "$SSH_AUTH_SOCK"
  ' zsh "$MACOS_CONFIG"
}

# Regression guarded: without Bitwarden, the system SSH agent stays in use.
actual=$(selected_socket)
if [ "$actual" != /tmp/system-agent.sock ]; then
  printf 'FAIL: expected the system agent without Bitwarden, got: %s\n' "$actual" >&2
  exit 1
fi

# With Bitwarden installed, SSH uses its agent socket.
bitwarden_data="$fixture_home/Library/Containers/com.bitwarden.desktop/Data"
mkdir -p "$bitwarden_data"
actual=$(selected_socket)
if [ "$actual" != "$bitwarden_data/.bitwarden-ssh-agent.sock" ]; then
  printf 'FAIL: expected the Bitwarden agent socket, got: %s\n' "$actual" >&2
  exit 1
fi

printf 'All SSH agent tests passed.\n'
