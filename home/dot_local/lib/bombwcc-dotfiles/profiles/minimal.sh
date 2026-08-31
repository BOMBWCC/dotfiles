create_debian_command_links() {
  run mkdir -p "$HOME/.local/bin"
  if have batcat && ! have bat; then run ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"; fi
  if have fdfind && ! have fd; then run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"; fi
}

summary_manifest_minimal() {
  summary_add 'Zsh' zsh --version
  summary_add 'Git' git --version
  summary_add 'curl' curl --version
  summary_add 'wget' wget --version
  summary_add 'Nano' nano --version
  summary_add 'jq' jq --version
  summary_add 'ripgrep' rg --version
  summary_add 'rsync' rsync --version
  summary_add 'OpenSSH Client' ssh -V
  if [ "$OS_NAME" = linux ]; then summary_add 'tmux' tmux -V; fi
  summary_add 'Starship' starship --version
  summary_add 'btop' btop --version
  summary_add 'fastfetch' fastfetch --version
  summary_add 'eza' eza --version
  summary_add 'bat' bat --version
  summary_add 'fd' fd --version
  summary_add 'procs' procs --version
  summary_add 'zoxide' zoxide --version
  summary_add 'fzf' fzf --version
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
  apt_optional btop bat fd-find procs fzf
  install_eza_linux
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
