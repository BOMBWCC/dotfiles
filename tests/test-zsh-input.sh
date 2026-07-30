#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
INPUT_CONFIG="$REPO_ROOT/home/dot_config/zsh/plugins/input.zsh"

output=$(
  zsh -f -c '
    zinit() { print -r -- "$*"; }
    source "$1"
  ' zsh "$INPUT_CONFIG"
)

case "$output" in
  *'zdharma-continuum/fast-syntax-highlighting'*) ;;
  *)
    printf 'FAIL: expected fast-syntax-highlighting to remain enabled\n' >&2
    exit 1
    ;;
esac

case "$output$(cat "$INPUT_CONFIG")" in
  *'zsh-vi-mode'*|*'ZVM_'*)
    printf 'FAIL: zsh-vi-mode configuration is still present\n' >&2
    exit 1
    ;;
esac

printf 'All Zsh input tests passed.\n'
