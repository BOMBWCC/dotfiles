install_starship_linux() {
  have starship && [ "$DRY_RUN" -eq 0 ] && return
  run_shell 'curl -fsSL https://starship.rs/install.sh | sh -s -- --yes'
}
