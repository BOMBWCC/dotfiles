if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons=auto --group-directories-first'
  alias ll='eza -lah --icons=auto --group-directories-first --git'
  alias la='eza -a --icons=auto --group-directories-first'
  alias tree='eza --tree --icons=auto'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  alias less='bat'
fi

if command -v procs >/dev/null 2>&1; then
  alias psa='procs'
fi
