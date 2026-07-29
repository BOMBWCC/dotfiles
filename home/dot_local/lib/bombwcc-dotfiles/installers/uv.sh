install_uv_linux() {
  have uv && [ "$DRY_RUN" -eq 0 ] && return
  run_shell 'curl -LsSf https://astral.sh/uv/install.sh | sh'
}
