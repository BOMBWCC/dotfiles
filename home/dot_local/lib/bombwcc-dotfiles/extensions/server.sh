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
