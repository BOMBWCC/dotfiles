install_eza_linux() {
  have eza && [ "$DRY_RUN" -eq 0 ] && return
  if [ "$DRY_RUN" -eq 1 ]; then
    say '+ install eza from APT when available, otherwise the SHA-256 verified official eza release'
    return
  fi

  if apt-cache show eza >/dev/null 2>&1; then
    apt_packages eza
    return
  fi

  arch=$(dpkg --print-architecture)
  case "$arch" in
    amd64) release_arch=x86_64 ;;
    arm64) release_arch=aarch64 ;;
    *) say "SKIP: unsupported eza architecture: $arch"; return ;;
  esac

  work_dir=$(mktemp -d "${TMPDIR:-/tmp}/eza.XXXXXX")
  if github_release_download eza-community/eza "^eza_${release_arch}-unknown-linux-gnu\\.tar\\.gz\$" "$work_dir/eza.tar.gz" \
    && tar -xzf "$work_dir/eza.tar.gz" -C "$work_dir" \
    && as_root install -m 0755 "$work_dir/eza" /usr/local/bin/eza; then
    :
  else
    say 'SKIP: eza could not be installed from a verified release.'
  fi
  rm -rf "$work_dir"
}
