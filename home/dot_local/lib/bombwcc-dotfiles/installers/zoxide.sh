install_zoxide_linux() {
  have zoxide && [ "$DRY_RUN" -eq 0 ] && return
  if [ "$DRY_RUN" -eq 1 ]; then
    say '+ install zoxide from the SHA-256 verified official release into ~/.local/bin'
    return
  fi

  arch=$(dpkg --print-architecture)
  case "$arch" in
    amd64) release_arch=x86_64 ;;
    arm64) release_arch=aarch64 ;;
    *) say "SKIP: unsupported zoxide architecture: $arch"; return ;;
  esac

  # The upstream install script is served from the main branch; the release
  # archive is pinned to a published release and verified before use.
  work_dir=$(mktemp -d "${TMPDIR:-/tmp}/zoxide.XXXXXX")
  if github_release_download ajeetdsouza/zoxide "^zoxide-[0-9.]+-${release_arch}-unknown-linux-musl\\.tar\\.gz\$" "$work_dir/zoxide.tar.gz" \
    && tar -xzf "$work_dir/zoxide.tar.gz" -C "$work_dir" \
    && zoxide_bin=$(find "$work_dir" -type f -name zoxide | sed -n 1p) \
    && [ -n "$zoxide_bin" ] \
    && mkdir -p "$HOME/.local/bin" \
    && install -m 0755 "$zoxide_bin" "$HOME/.local/bin/zoxide"; then
    :
  else
    say 'SKIP: zoxide could not be installed from a verified release.'
  fi
  rm -rf "$work_dir"
}
