install_full_macos() {
  install_minimal_macos
  brew_formulae sqlite sevenzip yq sd broot yazi lazygit git-delta gh direnv xh gping dog mdcat tealdeer ffmpeg yt-dlp
  install_codex_security
}

install_full_linux() {
  install_minimal_linux
  apt_optional sqlite3 p7zip-full yq broot yazi lazygit git-delta gh direnv xh gping dog mdcat tealdeer ffmpeg yt-dlp
  install_codex_security
  say 'NOTE: tools unavailable from APT are skipped and reported above.'
}

install_full() {
  case "$OS_NAME" in
    macos) install_full_macos ;;
    linux) install_full_linux ;;
  esac
}
