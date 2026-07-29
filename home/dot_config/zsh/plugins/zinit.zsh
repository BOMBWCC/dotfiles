ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
  print -P "%F{yellow}Installing Zinit...%f"
  command mkdir -p "${ZINIT_HOME:h}"
  command git clone \
    https://github.com/zdharma-continuum/zinit.git \
    "$ZINIT_HOME"
fi

if [[ -r "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"
else
  print -P "%F{red}Zinit is unavailable; plugin modules were skipped.%f"
fi
