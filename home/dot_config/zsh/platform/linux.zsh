# A terminal whose terminfo entry is missing on this host (for example
# xterm-ghostty over SSH when Ghostty could not install it) leaves zsh unable
# to move the cursor, so every keystroke redraw is appended and typed text
# appears doubled. Fall back to an entry every Linux host provides.
zmodload zsh/terminfo 2>/dev/null
if (( ! ${+terminfo[cub1]} )); then
  export TERM=xterm-256color
fi

# SSH from macOS forwards LC_CTYPE=UTF-8, which is not a Linux locale name, and
# a fresh VPS may have no locale configured at all. zsh then falls back to the
# C locale and measures each multibyte prompt glyph as several columns, so
# typed text is redrawn at the wrong position. C.UTF-8 ships with glibc.
if [[ "$(locale charmap 2>/dev/null)" != UTF-8 ]]; then
  unset LC_ALL LC_CTYPE
  export LANG=C.UTF-8
fi
