#!/bin/sh
set -eu

[ "$(uname -s)" = Darwin ] || {
  printf 'SKIP: Java home test requires macOS.\n'
  exit 0
}

JAVA_21_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
[ -d "$JAVA_21_HOME" ] || {
  printf 'SKIP: Homebrew Java 21 is not installed.\n'
  exit 0
}

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MACOS_CONFIG="$REPO_ROOT/home/dot_config/zsh/platform/macos.zsh"

selected_home=$(
  zsh -f -c '
    path=(/usr/bin /bin)
    source "$1"
    print -r -- "$JAVA_HOME"
  ' zsh "$MACOS_CONFIG"
)

if [ "$selected_home" != "$JAVA_21_HOME" ]; then
  printf 'FAIL: expected Java 21 to be the selected macOS JDK\n' >&2
  printf 'expected: %s\nactual: %s\n' "$JAVA_21_HOME" "$selected_home" >&2
  exit 1
fi

version=$($selected_home/bin/java -version 2>&1 | head -1)
case "$version" in
  'openjdk version "21.'*) ;;
  *) printf 'FAIL: expected Java 21, got: %s\n' "$version" >&2; exit 1 ;;
esac

printf 'All Java home tests passed.\n'
