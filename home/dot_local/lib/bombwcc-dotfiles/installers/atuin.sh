install_atuin_linux() {
  have atuin && [ "$DRY_RUN" -eq 0 ] && return
  if [ "$DRY_RUN" -eq 1 ]; then
    say '+ run the SHA-256 verified Atuin release installer into ~/.local/bin'
    return
  fi

  installer=$(mktemp "${TMPDIR:-/tmp}/atuin-installer.XXXXXX")
  if github_release_download atuinsh/atuin '^atuin-installer\.sh$' "$installer"; then
    ATUIN_INSTALL_DIR="$HOME/.local/bin" ATUIN_NO_MODIFY_PATH=1 sh "$installer" || {
      rm -f "$installer"
      return 1
    }
  else
    say 'SKIP: Atuin could not be installed from a verified release.'
  fi
  rm -f "$installer"
}
