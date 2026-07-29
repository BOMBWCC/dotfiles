# Zsh keeps PATH and the `path` array in sync. `-U` removes duplicates.
typeset -U path PATH
path=(
  "$HOME/.local/bin"
  $path
)
