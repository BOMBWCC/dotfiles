install_extension_ai() {
  if ! have npm && [ "$DRY_RUN" -eq 0 ]; then
    say 'Node.js/npm is required. Run: dotfiles-install extension dev' >&2
    exit 1
  fi
  run npm install -g @openai/codex @anthropic-ai/claude-code
  if [ "$OS_NAME" = macos ]; then brew_casks steipete/tap/codexbar; fi
  say 'NOTE: Oh My Pi and CAUT remain manual until their verified package sources are recorded.'
  say 'NOTE: gh skill is supplied by a compatible GitHub CLI installation.'
}
