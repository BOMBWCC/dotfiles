codex_security_node_supported() {
  have node || return 1
  version=$(node -p 'process.versions.node' 2>/dev/null) || return 1
  major=${version%%.*}
  remainder=${version#*.}
  minor=${remainder%%.*}

  case "$major" in
    22) [ "$minor" -ge 13 ] ;;
    24|26) return 0 ;;
    *) return 1 ;;
  esac
}

codex_security_python_supported() {
  have python3 || return 1
  version=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null) || return 1
  major=${version%%.*}
  minor=${version#*.}

  [ "$major" -gt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -ge 10 ]; }
}

activate_fnm_runtime() {
  export PATH="$HOME/.local/share/fnm:$PATH"
  have fnm || return 1
  eval "$(fnm env --shell bash)"
}

ensure_codex_security_runtime() {
  if codex_security_node_supported && have npm && codex_security_python_supported; then
    return
  fi

  if [ "$OS_NAME" = macos ]; then
    brew_formulae python fnm
  else
    apt_packages python3 curl
    install_fnm_linux
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    run fnm install --lts
    run fnm default lts-latest
    return
  fi

  activate_fnm_runtime || {
    say 'fnm could not be activated for Codex Security.' >&2
    exit 1
  }
  run fnm install --lts
  run fnm default lts-latest
  run fnm use lts-latest

  codex_security_node_supported || {
    say 'Codex Security requires Node.js 22.13+, 24.x, or 26.x.' >&2
    exit 1
  }
  codex_security_python_supported || {
    say 'Codex Security requires Python 3.10 or later.' >&2
    exit 1
  }
}

install_codex_security() {
  ensure_codex_security_runtime
  run npm install -g @openai/codex-security
}
