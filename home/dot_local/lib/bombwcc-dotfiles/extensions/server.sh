SSH_HARDENING_FILE=/etc/ssh/sshd_config.d/10-bombwcc-hardening.conf

summary_manifest_server() {
  summary_add 'OpenSSH Server' /usr/sbin/sshd -V
  summary_add 'vnStat' vnstat --version
  summary_add 'fail2ban' fail2ban-client --version
  summary_add 'UFW' ufw --version
  summary_add 'Docker' docker --version
}

ssh_authorized_key_present() {
  [ -r "$HOME/.ssh/authorized_keys" ] \
    && grep -Eq '^[[:space:]]*[^#[:space:]]' "$HOME/.ssh/authorized_keys"
}

# Debian and Ubuntu start sshd as soon as openssh-server is installed, with
# password logins enabled. Write the drop-in first so that sshd never starts
# with them, but only when key login is already possible for this account.
install_ssh_hardening() {
  if [ "${DOTFILES_SKIP_SSH_HARDENING:-0}" = 1 ]; then
    say 'SKIP: SSH hardening was disabled with DOTFILES_SKIP_SSH_HARDENING=1.'
    return
  fi
  if [ "$DRY_RUN" -eq 0 ] && ! ssh_authorized_key_present; then
    say "WARNING: $HOME/.ssh/authorized_keys has no public key, so SSH password login was left enabled."
    say 'WARNING: add a key and rerun: dotfiles-install extension server'
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    say "+ write $SSH_HARDENING_FILE (PasswordAuthentication no, KbdInteractiveAuthentication no, PermitRootLogin prohibit-password)"
    return
  fi

  hardening_source=$(mktemp "${TMPDIR:-/tmp}/sshd-hardening.XXXXXX")
  cat > "$hardening_source" <<'CONF'
# Managed by dotfiles-install extension server.
# Remove this file and reload ssh to restore the distribution defaults.
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
CONF
  as_root mkdir -p "${SSH_HARDENING_FILE%/*}"
  as_root install -m 0644 "$hardening_source" "$SSH_HARDENING_FILE"
  rm -f "$hardening_source"
}

verify_ssh_hardening() {
  [ "$DRY_RUN" -eq 0 ] && [ -f "$SSH_HARDENING_FILE" ] || return 0
  if as_root /usr/sbin/sshd -t; then
    say "NOTE: SSH password login is disabled by $SSH_HARDENING_FILE."
    say 'NOTE: if sshd was already running, apply it with: sudo systemctl reload ssh'
  else
    as_root rm -f "$SSH_HARDENING_FILE"
    say 'WARNING: sshd rejected the hardening drop-in, so it was removed.' >&2
  fi
}

install_extension_server() {
  if [ "$OS_NAME" != linux ]; then
    say 'SKIP: the server extension only applies to Linux.'
    return
  fi
  install_ssh_hardening
  apt_update
  apt_packages openssh-server vnstat fail2ban ufw
  verify_ssh_hardening
  apt_optional docker.io docker-compose-v2 docker-buildx
  say 'NOTE: this installer does not explicitly enable or start services or modify firewall rules; Debian package defaults may still enable or start services.'
  say 'NOTE: UFW is installed but not enabled. Allow SSH before enabling it: sudo ufw allow OpenSSH && sudo ufw enable'
  say 'NOTE: ports published by Docker containers bypass UFW rules; bind them to 127.0.0.1 unless they must be public.'
}
