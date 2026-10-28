install_fastfetch_linux() {
  have fastfetch && [ "$DRY_RUN" -eq 0 ] && return
  if [ "$DRY_RUN" -eq 1 ]; then
    say '+ install fastfetch from APT when available, otherwise the SHA-256 verified release package'
    return
  fi

  if apt-cache show fastfetch >/dev/null 2>&1; then
    apt_packages fastfetch
    return
  fi

  arch=$(dpkg --print-architecture)
  case "$arch" in
    amd64) release_arch=amd64 ;;
    arm64) release_arch=aarch64 ;;
    *) say "SKIP: unsupported fastfetch architecture: $arch"; return ;;
  esac

  work_dir=$(mktemp -d "${TMPDIR:-/tmp}/fastfetch.XXXXXX")
  # The package runs maintainer scripts as root, so it is installed only after
  # its digest matches the one GitHub publishes for the release asset.
  if github_release_download fastfetch-cli/fastfetch "^fastfetch-linux-${release_arch}\\.deb\$" "$work_dir/fastfetch.deb" \
    && chmod 0755 "$work_dir" && chmod 0644 "$work_dir/fastfetch.deb" \
    && as_root apt-get install -y "$work_dir/fastfetch.deb"; then
    :
  else
    say 'SKIP: fastfetch could not be installed from a verified release.'
  fi
  rm -rf "$work_dir"
}
