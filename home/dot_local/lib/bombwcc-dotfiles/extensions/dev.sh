install_extension_dev() {
  if [ "$OS_NAME" = macos ]; then
    brew_formulae python uv fnm rust tree-sitter
    run fnm install --lts
    run fnm default lts-latest
    return
  fi
  apt_update
  apt_packages build-essential python3 python3-pip curl
  install_uv_linux
  install_fnm_linux
  install_rustup_linux
  say 'NOTE: reopen Zsh, then rerun: dotfiles-install extension dev'
  if have fnm || [ "$DRY_RUN" -eq 1 ]; then
    run fnm install --lts
    run fnm default lts-latest
  fi
  if have npm || [ "$DRY_RUN" -eq 1 ]; then run npm install -g tree-sitter-cli; fi
}
