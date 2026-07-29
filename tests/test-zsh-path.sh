#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PATH_CONFIG="$REPO_ROOT/home/dot_config/zsh/common/path.zsh"

output=$(
  HOME=/tmp/bombwcc-path-test-home \
    zsh -f -c '
      path=(/usr/bin /bin)
      load_path_config() {
        source "$1"
      }
      load_path_config "$1"
      print -r -- "${path[1]}"
      print -r -- "${path[2]}"
    ' zsh "$PATH_CONFIG"
)

expected=$(printf '%s\n' \
  '/tmp/bombwcc-path-test-home/bin' \
  '/tmp/bombwcc-path-test-home/.local/bin')

if [ "$output" != "$expected" ]; then
  printf 'FAIL: expected persistent user bin paths after function-scoped source\n' >&2
  printf 'expected:\n%s\nactual:\n%s\n' "$expected" "$output" >&2
  exit 1
fi

printf 'All Zsh PATH tests passed.\n'
