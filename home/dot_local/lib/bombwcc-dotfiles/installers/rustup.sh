install_rustup_linux() {
  have cargo && [ "$DRY_RUN" -eq 0 ] && return
  run_shell "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
}
