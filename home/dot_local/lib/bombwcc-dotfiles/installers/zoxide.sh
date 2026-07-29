install_zoxide_linux() {
  have zoxide && [ "$DRY_RUN" -eq 0 ] && return
  run_shell 'curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh'
}
