install_atuin_linux() {
  have atuin && [ "$DRY_RUN" -eq 0 ] && return
  run_shell 'curl -fsSL https://github.com/atuinsh/atuin/releases/latest/download/atuin-installer.sh | ATUIN_INSTALL_DIR="$HOME/.local/bin" ATUIN_NO_MODIFY_PATH=1 sh'
}
