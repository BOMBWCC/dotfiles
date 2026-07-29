install_fastfetch_linux() {
  have fastfetch && [ "$DRY_RUN" -eq 0 ] && return
  if [ "$DRY_RUN" -eq 1 ]; then
    say '+ install fastfetch release package'
    return
  fi
  arch=$(dpkg --print-architecture)
  case "$arch" in
    amd64) release_arch=amd64 ;;
    arm64) release_arch=aarch64 ;;
    *) say "SKIP: unsupported fastfetch architecture: $arch"; return ;;
  esac
  package_file=$(mktemp "${TMPDIR:-/tmp}/fastfetch.XXXXXX.deb")
  curl -fL "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-${release_arch}.deb" -o "$package_file"
  as_root apt-get install -y "$package_file"
  rm -f "$package_file"
}
