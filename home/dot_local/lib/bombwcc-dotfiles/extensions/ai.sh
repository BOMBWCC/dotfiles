summary_manifest_ai() {
  summary_add 'Codex CLI' codex --version
  summary_add 'Claude Code' claude --version
  summary_add 'Oh My Pi' omp --version
  summary_add 'Herdr' herdr --version
}

install_extension_ai() {
  if ! have npm && [ "$DRY_RUN" -eq 0 ]; then
    say 'Node.js/npm is required. Run: dotfiles-install extension dev' >&2
    exit 1
  fi
  run npm install -g @openai/codex @anthropic-ai/claude-code
  install_oh_my_pi
  install_herdr
  if [ "$OS_NAME" = macos ]; then brew_casks steipete/tap/codexbar; fi
  say 'NOTE: gh skill is supplied by a compatible GitHub CLI installation.'
  say 'Open a new Zsh session, or run: exec zsh'
}
