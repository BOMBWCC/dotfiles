install_starship_linux() {
  have starship && [ "$DRY_RUN" -eq 0 ] && return
  run_remote_script https://starship.rs/install.sh sh -s -- --yes
}
