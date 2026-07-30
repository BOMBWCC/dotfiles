create_debian_command_links() {
  run mkdir -p "$HOME/.local/bin"
  if have batcat && ! have bat; then run ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"; fi
  if have fdfind && ! have fd; then run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"; fi
}

rebuild_bat_cache() {
  if [ "$DRY_RUN" -eq 1 ] || have bat; then
    run bat cache --build
  fi
}

install_minimal_macos() {
  brew_formulae git wget nano jq ripgrep starship btop fastfetch eza bat fd procs zoxide fzf
  rebuild_bat_cache
}

install_minimal_linux() {
  apt_update
  apt_packages ca-certificates zsh git curl wget unzip nano jq ripgrep rsync openssh-client tmux
  apt_optional btop bat fd-find eza procs fzf
  create_debian_command_links
  rebuild_bat_cache
  install_starship_linux
  install_zoxide_linux
  install_fastfetch_linux
}

install_minimal() {
  case "$OS_NAME" in
    macos) install_minimal_macos ;;
    linux) install_minimal_linux ;;
  esac
}
