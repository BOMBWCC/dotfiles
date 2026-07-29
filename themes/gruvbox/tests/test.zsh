#!/usr/bin/env zsh

# Comment: ordinary comment
## Comment: secondary comment

export PROJECT_NAME="dotfiles"
local count=42
local ratio=3.14
local enabled=true
local escaped="first line\nsecond line\tindented"

alias ll='eza -la'

hello_world() {
  local target="$1"

  if [[ -d "$HOME/.config" && "$target" =~ '^prod-[0-9]+$' ]]; then
    echo "config exists: ${PROJECT_NAME}"
    git status --short
    docker compose ps
    eza -la ~/Documents/*.md
  else
    printf '%s\n' "not found: $target" >&2
  fi
}

for item in one two three; do
  count=$((count + 1))
  print -- "$count: $item"
done

local nested=$((1 + (2 * (3 + 4))))
ll ~/Documents
hello_world "prod-123"
not_a_real_command --unknown /missing/path

# These lines are for static highlighting previews; do not run this function.
history_preview() {
  !!
  !$
}
