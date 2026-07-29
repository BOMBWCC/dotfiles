#!/bin/sh
set -eu

PAGER_SCRIPT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)/home/dot_local/bin/executable_git-diff-pager"
fixture_dir=$(mktemp -d "${TMPDIR:-/tmp}/git-pager-test.XXXXXX")
trap 'rm -rf "$fixture_dir"' EXIT HUP INT TERM

make_command() {
  command_name=$1
  label=$2
  printf '#!/bin/sh\nprintf "%s:%%s\\n" "$*"\ncat\n' "$label" >"$fixture_dir/$command_name"
  chmod +x "$fixture_dir/$command_name"
}

make_command delta delta
make_command bat bat
make_command less less

# Regression guarded: delta is preferred and receives Git's filter arguments.
output=$(printf 'patch\n' | PATH="$fixture_dir:/usr/bin:/bin" sh "$PAGER_SCRIPT" --color-only)
case "$output" in
  'delta:--color-only
patch') ;;
  *) printf 'FAIL: delta was not selected: %s\n' "$output" >&2; exit 1 ;;
esac

rm "$fixture_dir/delta"

# Regression guarded: minimal installations without delta still render via bat.
output=$(printf 'patch\n' | PATH="$fixture_dir:/usr/bin:/bin" sh "$PAGER_SCRIPT" --color-only)
case "$output" in
  'bat:--paging=always --style=plain --color=always
patch') ;;
  *) printf 'FAIL: bat fallback was not selected: %s\n' "$output" >&2; exit 1 ;;
esac

printf 'All git-diff-pager tests passed.\n'
