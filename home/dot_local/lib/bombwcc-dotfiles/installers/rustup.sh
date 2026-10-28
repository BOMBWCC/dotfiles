install_rustup_linux() {
  have cargo && [ "$DRY_RUN" -eq 0 ] && return
  run_remote_script https://sh.rustup.rs sh -s -- -y
}
