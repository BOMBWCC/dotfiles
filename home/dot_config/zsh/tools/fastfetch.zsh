# Show fastfetch once, before the first prompt of each terminal session.
_fastfetch_once() {
  if [[ -z "${FASTFETCH_SHOWN:-}" ]] \
    && command -v fastfetch >/dev/null 2>&1; then
    export FASTFETCH_SHOWN=1
    fastfetch
  fi

  precmd_functions=(${precmd_functions:#_fastfetch_once})
}

precmd_functions+=(_fastfetch_once)
