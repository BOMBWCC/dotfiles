install_eza_linux() {
  have eza && [ "$DRY_RUN" -eq 0 ] && return
  if [ "$DRY_RUN" -eq 1 ]; then
    say '+ install eza from APT when available, otherwise official eza release'
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

  archive=$(mktemp "${TMPDIR:-/tmp}/eza.XXXXXX.tar.gz")
  extract_dir=$(mktemp -d "${TMPDIR:-/tmp}/eza.XXXXXX")
  curl -fL "https://github.com/eza-community/eza/releases/latest/download/eza_${release_arch}-unknown-linux-gnu.tar.gz" -o "$archive"
  tar -xzf "$archive" -C "$extract_dir"
  as_root install -m 0755 "$extract_dir/eza" /usr/local/bin/eza
  rm -f "$archive"
  rm -rf "$extract_dir"
}
