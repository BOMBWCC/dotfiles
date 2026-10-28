install_uv_linux() {
  have uv && [ "$DRY_RUN" -eq 0 ] && return
  run_remote_script https://astral.sh/uv/install.sh sh
}
