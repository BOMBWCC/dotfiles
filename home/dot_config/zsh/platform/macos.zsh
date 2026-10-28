# Homebrew OpenJDK, preferring 21 over 17 (Apple Silicon and Intel prefixes).
for java_home in \
  /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home \
  /usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home \
  /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
  /usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home; do
  if [[ -d "$java_home" ]]; then
    export JAVA_HOME="$java_home"
    path=("$JAVA_HOME/bin" $path)
    break
  fi
done
unset java_home

# Route SSH and Git authentication through the Bitwarden desktop SSH agent.
# This is the macOS App Store socket; it contains no private key material.
# Check the app container rather than the socket so shells opened before
# Bitwarden starts still use the agent, while machines without Bitwarden keep
# the system agent.
if [[ -d "$HOME/Library/Containers/com.bitwarden.desktop/Data" ]]; then
  export SSH_AUTH_SOCK="$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"
fi

# This Mac is the development workstation.
ZSH_ENABLE_DEV=1
ZSH_ENABLE_AI=1
