if (( $+functions[zinit] )); then
  zinit light zsh-users/zsh-autosuggestions

  if command -v atuin >/dev/null 2>&1; then
    # Keep arrow-key history navigation; use Ctrl-R for Atuin search.
    eval "$(atuin init zsh --disable-up-arrow --disable-ai)"
  fi

  # Syntax highlighting should be the last plugin that changes line display.
  zinit light zdharma-continuum/fast-syntax-highlighting
fi
