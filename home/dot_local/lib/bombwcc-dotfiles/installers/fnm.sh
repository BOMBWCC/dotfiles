install_fnm_linux() {
  have fnm && [ "$DRY_RUN" -eq 0 ] && return
  run_shell 'curl -fsSL https://fnm.vercel.app/install | bash'
}
