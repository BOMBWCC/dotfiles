#!/bin/sh
set -eu

REPO=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

docker run --rm \
  -v "$REPO:/repo:ro" \
  -w /repo \
  debian:12 \
  sh -eu -c '
    apt-get update >/dev/null
    apt-get install -y ca-certificates dash >/dev/null

    output=$(sh home/dot_local/bin/executable_dotfiles-install --dry-run minimal)
    printf "%s\n" "$output"
    printf "%s\n" "$output" | grep -F "Installation summary" >/dev/null
    printf "%s\n" "$output" | grep -F "Planned:" >/dev/null
    printf "%s\n" "$output" | grep -F "apt-get install" >/dev/null

    . home/dot_local/lib/bombwcc-dotfiles/common.sh
    detect_linux_distro /etc/os-release
    [ "$DISTRO_NAME" = debian ]
    [ "$DISTRO_VERSION" = 12 ]

    for package in zsh git curl wget unzip nano jq ripgrep rsync openssh-client tmux bat fd-find; do
      apt-cache show "$package" >/dev/null
    done
  '
