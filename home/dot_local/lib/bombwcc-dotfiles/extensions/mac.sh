install_extension_mac() {
  if [ "$OS_NAME" != macos ]; then
    say 'SKIP: the mac extension only applies to macOS.'
    return
  fi
  brew_casks font-meslo-lg-nerd-font font-noto-serif-cjk-sc ghostty docker steipete/tap/codexbar
  if [ ! -d '/Library/Input Methods/Squirrel.app' ] || [ "$DRY_RUN" -eq 1 ]; then brew_casks squirrel-app; fi
  say 'NOTE: after applying Rime configuration, redeploy Squirrel from its input-method menu.'
}
