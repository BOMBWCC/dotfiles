# These modules are sourced from a helper function, so the synced arrays must
# be declared globally. `-U` removes duplicates while preserving order.
typeset -gU path PATH
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/.local/share/fnm"
  "$HOME/.cargo/bin"
  "$HOME/.bun/bin"
  $path
)

# fnm owns Node.js and npm-global CLI locations. Activate it whenever it is
# installed so optional CLIs such as codex and claude work in the minimal shell
# configuration too.
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# Support an existing user-level npm prefix without requiring it.
if [[ -d "$HOME/.npm-global/bin" ]]; then
  path=("$HOME/.npm-global/bin" $path)
fi

# npm may be provided by fnm, Hermes, or another user-level runtime. Include
# its actual global binary directory instead of assuming a fixed prefix.
if command -v npm >/dev/null 2>&1; then
  npm_global_prefix="$(npm config get prefix 2>/dev/null)"
  [[ -n "$npm_global_prefix" ]] && path=("$npm_global_prefix/bin" $path)
  unset npm_global_prefix
fi
