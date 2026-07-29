# These modules are sourced from a helper function, so the synced arrays must
# be declared globally. `-U` removes duplicates while preserving order.
typeset -gU path PATH
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  $path
)
