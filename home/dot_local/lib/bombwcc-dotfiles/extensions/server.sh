summary_manifest_server() {
  summary_add 'OpenSSH Server' /usr/sbin/sshd -V
  summary_add 'vnStat' vnstat --version
  summary_add 'fail2ban' fail2ban-client --version
  summary_add 'UFW' ufw --version
  summary_add 'Docker' docker --version
}

install_extension_server() {
  if [ "$OS_NAME" != linux ]; then
    say 'SKIP: the server extension only applies to Linux.'
    return
  fi
  apt_update
  apt_packages openssh-server vnstat fail2ban ufw
  apt_optional docker.io docker-compose-v2 docker-buildx
  say 'NOTE: firewall rules and service enablement are intentionally not changed automatically.'
}
