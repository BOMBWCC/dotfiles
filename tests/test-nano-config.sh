#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEMPLATE='{{ template "bombwcc-gruvbox.nanorc.tmpl" . }}'

render() {
  chezmoi --source "$REPO_ROOT" \
    --override-data "{\"chezmoi\":{\"os\":\"$1\"}}" \
    execute-template "$TEMPLATE"
}

assert_contains() {
  output=$1
  expected=$2
  case "$output" in
    *"$expected"*) ;;
    *)
      printf 'FAIL: expected rendered Nano config to contain: %s\n' "$expected" >&2
      exit 1
      ;;
  esac
}

linux_output=$(render linux)
assert_contains "$linux_output" 'extendsyntax sh '
assert_contains "$linux_output" 'extendsyntax rust '
assert_contains "$linux_output" 'extendsyntax html '
assert_contains "$linux_output" 'extendsyntax patch '

macos_output=$(render darwin)
assert_contains "$macos_output" 'extendsyntax ZSH '
assert_contains "$macos_output" 'extendsyntax Rust '
assert_contains "$macos_output" 'extendsyntax HTML '
assert_contains "$macos_output" 'extendsyntax Patch '

printf 'All Nano config tests passed.\n'
