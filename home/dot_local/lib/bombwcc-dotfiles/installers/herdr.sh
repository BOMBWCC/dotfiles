install_herdr() {
  if have herdr && [ "$DRY_RUN" -eq 0 ]; then
    say 'SKIP: Herdr is already installed.'
    return
  fi

  if [ "$OS_NAME" = macos ]; then
    brew_formulae herdr
  else
    run_shell 'curl -fsSL https://herdr.dev/install.sh | sh'
  fi
}
