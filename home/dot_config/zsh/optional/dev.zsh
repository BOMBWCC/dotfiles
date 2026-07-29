path=(
  "$HOME/.cargo/bin"
  $path
)

# Optional environment file created by tools such as uv.
[[ -r "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi
