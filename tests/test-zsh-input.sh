#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
INPUT_CONFIG="$REPO_ROOT/home/dot_config/zsh/plugins/input.zsh"

output=$(
  zsh -f -c '
    zinit() { :; }
    source "$1"
    zvm_config
    print -r -- "${ZVM_KEYTIMEOUT:-unset}"
  ' zsh "$INPUT_CONFIG"
)

if [ "$output" != '0.4' ]; then
  printf 'FAIL: expected ZVM_KEYTIMEOUT=0.4, got %s\n' "$output" >&2
  exit 1
fi

printf 'All Zsh input tests passed.\n'
