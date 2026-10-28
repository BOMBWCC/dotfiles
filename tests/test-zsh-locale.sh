#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
LINUX_CONFIG="$REPO_ROOT/home/dot_config/zsh/platform/linux.zsh"

[ "$(uname -s)" = Linux ] || {
  printf 'SKIP: Linux locale test requires Linux.\n'
  exit 0
}

# Prints the zsh character set and the width zsh measures for the prompt arrow.
measure() {
  env -i PATH=/usr/bin:/bin "$@" zsh -f -c '
    source "$1"
    print -r -- "$(locale charmap 2>/dev/null)|${(m)#${:-❯}}|${LC_CTYPE-unset}"
  ' zsh "$LINUX_CONFIG"
}

# Regression guarded: macOS SSH forwards LC_CTYPE=UTF-8, an invalid Linux
# locale; zsh must still measure the one-column prompt arrow as one column.
actual=$(measure LC_CTYPE=UTF-8)
if [ "$actual" != 'UTF-8|1|unset' ]; then
  printf 'FAIL: forwarded macOS LC_CTYPE was not repaired: %s\n' "$actual" >&2
  exit 1
fi

actual=$(measure)
if [ "$actual" != 'UTF-8|1|unset' ]; then
  printf 'FAIL: missing locale was not repaired: %s\n' "$actual" >&2
  exit 1
fi

# A valid UTF-8 locale chosen by the user is left untouched.
actual=$(measure LANG=C.UTF-8 LC_CTYPE=C.UTF-8)
if [ "$actual" != 'UTF-8|1|C.UTF-8' ]; then
  printf 'FAIL: valid UTF-8 locale was changed: %s\n' "$actual" >&2
  exit 1
fi

printf 'All Zsh locale tests passed.\n'
