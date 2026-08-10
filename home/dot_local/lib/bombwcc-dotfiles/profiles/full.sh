summary_manifest_full() {
  summary_manifest_minimal
  summary_add 'SQLite' sqlite3 --version
  summary_add '7-Zip' 7z --help
  summary_add 'yq' yq --version
  summary_add 'sd' sd --version
  summary_add 'broot' broot --version
  summary_add 'Yazi' yazi --version
  summary_add 'lazygit' lazygit --version
  summary_add 'delta' delta --version
  summary_add 'GitHub CLI' gh --version
  summary_add 'direnv' direnv --version
  summary_add 'xh' xh --version
  summary_add 'gping' gping --version
  if [ "$OS_NAME" = macos ]; then
    summary_add 'doggo' doggo --version
  else
    summary_add 'dog' dog --version
  fi
  summary_add 'mdcat' mdcat --version
  summary_add 'tealdeer' tldr --version
  summary_add 'FFmpeg' ffmpeg --version
  summary_add 'yt-dlp' yt-dlp --version
  summary_add 'Codex Security' codex-security --version
}

install_full_macos() {
  install_minimal_macos
  brew_optional sqlite sevenzip yq sd broot yazi lazygit git-delta gh direnv xh gping doggo mdcat tealdeer ffmpeg yt-dlp
  install_codex_security
}

install_full_linux() {
  install_minimal_linux
  apt_optional sqlite3 p7zip-full yq sd broot yazi lazygit git-delta gh direnv xh gping dog mdcat tealdeer ffmpeg yt-dlp
  install_codex_security
  say 'NOTE: tools unavailable from APT are skipped and reported above.'
}

install_full() {
  case "$OS_NAME" in
    macos) install_full_macos ;;
    linux) install_full_linux ;;
  esac
}
