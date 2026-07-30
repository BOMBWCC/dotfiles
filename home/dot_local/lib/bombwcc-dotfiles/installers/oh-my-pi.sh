install_oh_my_pi() {
  if have omp && [ "$DRY_RUN" -eq 0 ]; then
    say 'SKIP: Oh My Pi is already installed.'
    return
  fi

  run_shell 'curl -fsSL https://omp.sh/install | sh'
}
