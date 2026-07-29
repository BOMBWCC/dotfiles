if (( $+functions[zinit] )); then
  zvm_config() {
    ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT

    # Keep cursor appearance portable across terminal emulators and VPS hosts.
    # This preserves the current Ghostty behavior: a blinking beam in all modes.
    ZVM_CURSOR_STYLE_ENABLED=true
    ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
    ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
    ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
    ZVM_VISUAL_LINE_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
    ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
  }

  zinit ice depth=1
  zinit light jeffreytse/zsh-vi-mode

  # Syntax highlighting should be the last plugin that changes line display.
  zinit light zdharma-continuum/fast-syntax-highlighting
fi
