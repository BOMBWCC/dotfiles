# Homebrew OpenJDK 17 (Apple Silicon and Intel prefixes).
for java_home in \
  /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
  /usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home; do
  if [[ -d "$java_home" ]]; then
    export JAVA_HOME="$java_home"
    path=("$JAVA_HOME/bin" $path)
    break
  fi
done
unset java_home

# Use the macOS clipboard for zsh-vi-mode yank/delete operations.
ZVM_SYSTEM_CLIPBOARD_ENABLED=true

# Route SSH and Git authentication through the Bitwarden desktop SSH agent.
# This is the macOS App Store socket; it contains no private key material.
export SSH_AUTH_SOCK="$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"

# This Mac is the development workstation.
ZSH_ENABLE_DEV=1
ZSH_ENABLE_AI=1
