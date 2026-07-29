if (( $+functions[zinit] )); then
  # Completion definitions must be added to fpath before compinit runs.
  zinit light zsh-users/zsh-completions
fi

autoload -Uz compinit
compinit

zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'

# fzf-tab wraps completion widgets, so load it after compinit.
if (( $+functions[zinit] )) && command -v fzf >/dev/null 2>&1; then
  zinit light Aloxaf/fzf-tab
fi

if command -v eza >/dev/null 2>&1; then
  zstyle ':fzf-tab:complete:cd:*' \
    fzf-preview 'eza -1 --color=always "$realpath"'
fi
