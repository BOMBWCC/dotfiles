# Debian 12 Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Debian 12 a verified installer target for all non-macOS profiles and extensions, with an English post-install readiness summary.

**Architecture:** Extend the shared POSIX shell library with explicit Debian/Ubuntu detection and a manifest-driven summary renderer. Keep package installation in the existing profile and extension modules, where each module also declares the commands it promises. Verify distribution behavior with shell regression tests and an official `debian:12` container.

**Tech Stack:** POSIX `sh`, Chezmoi source layout, APT, Docker, shell regression tests.

## Global Constraints

- Support `minimal`, `full`, `extension dev`, `extension ai`, and `extension server` on Debian 12.
- Do not add backports, third-party APT repositories, Docker repositories, or firewall rules.
- Only explicit `debian` and `ubuntu` `/etc/os-release` identifiers are supported during automatic Linux detection.
- Preserve `--os linux` as a portable dry-run override that bypasses host distribution detection.
- Required package failures remain fatal; unavailable optional packages remain non-fatal.
- All summary text is English.
- Preserve the original exit status when rendering a failure summary.
- Keep the installer POSIX `sh` compatible and add no parsing dependency.

## File map

- Modify `home/dot_local/lib/bombwcc-dotfiles/common.sh`: distribution detection, APT support validation, summary manifest API, and summary rendering.
- Modify `home/dot_local/bin/executable_dotfiles-install`: platform validation, manifest selection, and one exit-summary hook.
- Modify `home/dot_local/lib/bombwcc-dotfiles/profiles/minimal.sh`: minimal manifests and Debian command mappings.
- Modify `home/dot_local/lib/bombwcc-dotfiles/profiles/full.sh`: combined full manifests.
- Modify `home/dot_local/lib/bombwcc-dotfiles/extensions/dev.sh`: development manifests.
- Modify `home/dot_local/lib/bombwcc-dotfiles/extensions/ai.sh`: AI manifests.
- Modify `home/dot_local/lib/bombwcc-dotfiles/extensions/server.sh`: server manifests.
- Modify `tests/test-dotfiles-install.sh`: shell regression coverage for detection, manifests, summaries, and failures.
- Create `tests/test-debian-12-install.sh`: Docker-based Debian 12 integration verification.
- Modify `README.md`: verified Debian 12 scope, repository policy, and summary semantics.

---

### Task 1: Detect and validate Debian/Ubuntu explicitly

**Files:**
- Modify: `tests/test-dotfiles-install.sh`
- Modify: `home/dot_local/lib/bombwcc-dotfiles/common.sh`
- Modify: `home/dot_local/bin/executable_dotfiles-install`

**Interfaces:**
- Produces: `detect_linux_distro [os_release_file]`, which sets global `DISTRO_NAME` and `DISTRO_VERSION`.
- Produces: `validate_platform`, which returns success for macOS, explicit `--os linux`, Debian, and Ubuntu; otherwise prints a specific error and returns non-zero.
- Consumes: existing globals `OS_NAME` and `OS_OVERRIDE`.

- [ ] **Step 1: Add failing distribution-detection tests**

Add temporary os-release fixtures and assertions to `tests/test-dotfiles-install.sh`:

```sh
assert_equals() {
  actual=$1
  expected=$2
  if [ "$actual" != "$expected" ]; then
    printf 'FAIL: expected <%s>, got <%s>\n' "$expected" "$actual" >&2
    failures=$((failures + 1))
  fi
}

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT HUP INT TERM

printf 'ID=debian\nVERSION_ID="12"\n' > "$test_tmp/debian-release"
output=$(
  sh -c '. "$1"; detect_linux_distro "$2"; printf "%s|%s\n" "$DISTRO_NAME" "$DISTRO_VERSION"' \
    sh "$LIB_ROOT/common.sh" "$test_tmp/debian-release"
)
assert_equals "$output" 'debian|12'

printf 'ID=ubuntu\nVERSION_ID="24.04"\n' > "$test_tmp/ubuntu-release"
output=$(
  sh -c '. "$1"; detect_linux_distro "$2"; printf "%s|%s\n" "$DISTRO_NAME" "$DISTRO_VERSION"' \
    sh "$LIB_ROOT/common.sh" "$test_tmp/ubuntu-release"
)
assert_equals "$output" 'ubuntu|24.04'

printf 'ID=fedora\nVERSION_ID="42"\n' > "$test_tmp/fedora-release"
if output=$(sh -c '. "$1"; OS_NAME=linux; OS_OVERRIDE=""; DOTFILES_OS_RELEASE_FILE=$2; validate_platform' \
  sh "$LIB_ROOT/common.sh" "$test_tmp/fedora-release" 2>&1); then
  printf 'FAIL: Fedora platform validation unexpectedly succeeded\n' >&2
  failures=$((failures + 1))
else
  assert_contains "$output" 'Unsupported Linux distribution: fedora'
fi

output=$(sh "$INSTALLER" --dry-run --os linux minimal 2>&1)
assert_contains "$output" 'apt-get install'
```

- [ ] **Step 2: Run the test and verify the new assertions fail**

Run: `sh tests/test-dotfiles-install.sh`

Expected: FAIL because `detect_linux_distro` and `validate_platform` are undefined, while the pre-existing assertions remain green.

- [ ] **Step 3: Implement explicit Linux distribution detection**

Add to `common.sh`:

```sh
detect_linux_distro() {
  release_file=${1:-${DOTFILES_OS_RELEASE_FILE:-/etc/os-release}}
  [ -r "$release_file" ] || {
    say "Unsupported Linux system: cannot read $release_file" >&2
    return 1
  }

  DISTRO_NAME=""
  DISTRO_VERSION=""
  while IFS='=' read -r key value; do
    value=${value#\"}
    value=${value%\"}
    case "$key" in
      ID) DISTRO_NAME=$value ;;
      VERSION_ID) DISTRO_VERSION=$value ;;
    esac
  done < "$release_file"

  [ -n "$DISTRO_NAME" ] || {
    say "Unsupported Linux system: ID is missing from $release_file" >&2
    return 1
  }
}

validate_platform() {
  [ "$OS_NAME" = macos ] && return 0
  if [ "$OS_NAME" = linux ] && [ "$OS_OVERRIDE" = linux ]; then
    DISTRO_NAME=apt-compatible
    DISTRO_VERSION=""
    return 0
  fi
  [ "$OS_NAME" = linux ] || return 0
  detect_linux_distro || return 1
  case "$DISTRO_NAME" in
    debian|ubuntu) return 0 ;;
    *) say "Unsupported Linux distribution: $DISTRO_NAME" >&2; return 1 ;;
  esac
}
```

Call `validate_platform` immediately after `OS_NAME=$(detect_os)` in the entry point.

- [ ] **Step 4: Run detection and existing regression tests**

Run: `sh tests/test-dotfiles-install.sh`

Expected: `All dotfiles-install tests passed.`

Run: `sh -n home/dot_local/bin/executable_dotfiles-install home/dot_local/lib/bombwcc-dotfiles/common.sh`

Expected: exit 0 with no output.

- [ ] **Step 5: Commit the platform boundary**

```sh
git add tests/test-dotfiles-install.sh \
  home/dot_local/lib/bombwcc-dotfiles/common.sh \
  home/dot_local/bin/executable_dotfiles-install
git commit -m "Support Debian and Ubuntu detection"
```

---

### Task 2: Add a manifest-driven installation summary

**Files:**
- Modify: `tests/test-dotfiles-install.sh`
- Modify: `home/dot_local/lib/bombwcc-dotfiles/common.sh`
- Modify: `home/dot_local/bin/executable_dotfiles-install`

**Interfaces:**
- Produces: `summary_reset`, `summary_add LABEL COMMAND [VERSION_FLAG]`, `summary_render STATUS`, and `summary_on_exit`.
- Data format: newline-separated `label|command|version_flag` records in `SUMMARY_ITEMS`.
- Consumes: `DRY_RUN`; `summary_on_exit` receives the shell's original status through `$?`.

- [ ] **Step 1: Add failing summary unit tests**

Append controlled command fixtures to `tests/test-dotfiles-install.sh`:

```sh
fake_bin="$test_tmp/bin"
mkdir -p "$fake_bin"
printf '#!/bin/sh\nprintf "ready-tool 1.2.3\\n"\n' > "$fake_bin/ready-tool"
chmod +x "$fake_bin/ready-tool"

output=$(
  PATH="$fake_bin:/usr/bin:/bin" sh -c '
    . "$1"
    DRY_RUN=0
    summary_reset
    summary_add "Ready Tool" ready-tool --version
    summary_add "Missing Tool" missing-tool --version
    summary_render 0
  ' sh "$LIB_ROOT/common.sh"
)
assert_contains "$output" 'Installation summary'
assert_contains "$output" 'Ready:'
assert_contains "$output" 'Ready Tool — ready-tool 1.2.3'
assert_contains "$output" 'Missing:'
assert_contains "$output" 'Missing Tool'
assert_contains "$output" 'Installation completed.'

output=$(
  sh -c '. "$1"; DRY_RUN=1; summary_reset; summary_add "Git" git --version; summary_render 0' \
    sh "$LIB_ROOT/common.sh"
)
assert_contains "$output" 'Planned:'
assert_not_contains "$output" 'Ready:'

if output=$(sh -c '. "$1"; DRY_RUN=0; summary_reset; summary_add "Git" git --version; summary_render 7; exit 7' \
  sh "$LIB_ROOT/common.sh" 2>&1); then
  printf 'FAIL: summary failure fixture unexpectedly succeeded\n' >&2
  failures=$((failures + 1))
else
  assert_contains "$output" 'Installation did not complete.'
fi
```

- [ ] **Step 2: Run the tests and verify failure for missing summary functions**

Run: `sh tests/test-dotfiles-install.sh`

Expected: FAIL because `summary_reset`, `summary_add`, and `summary_render` do not exist.

- [ ] **Step 3: Implement the minimal summary API in `common.sh`**

Implement records without arrays so the code remains POSIX-compatible:

```sh
summary_reset() {
  SUMMARY_ITEMS=""
  SUMMARY_ACTIVE=0
}

summary_add() {
  record="$1|$2|${3:-}"
  if [ -n "$SUMMARY_ITEMS" ]; then
    SUMMARY_ITEMS="$SUMMARY_ITEMS
$record"
  else
    SUMMARY_ITEMS=$record
  fi
}

summary_version() {
  command_name=$1
  version_flag=$2
  [ -n "$version_flag" ] || return 0
  "$command_name" "$version_flag" 2>&1 | sed -n '1p'
}

summary_render() {
  original_status=$1
  [ -n "${SUMMARY_ITEMS:-}" ] || return 0
  say ''
  say 'Installation summary'

  if [ "$DRY_RUN" -eq 1 ]; then
    say 'Planned:'
    printf '%s\n' "$SUMMARY_ITEMS" | while IFS='|' read -r label command_name version_flag; do
      [ -n "$label" ] && say "  - $label"
    done
  else
    say 'Ready:'
    printf '%s\n' "$SUMMARY_ITEMS" | while IFS='|' read -r label command_name version_flag; do
      if have "$command_name"; then
        version=$(summary_version "$command_name" "$version_flag" || true)
        if [ -n "$version" ]; then say "  - $label — $version"; else say "  - $label"; fi
      fi
    done
    say 'Missing:'
    printf '%s\n' "$SUMMARY_ITEMS" | while IFS='|' read -r label command_name version_flag; do
      have "$command_name" || say "  - $label"
    done
  fi

  if [ "$original_status" -eq 0 ]; then
    say 'Installation completed.'
  else
    say 'Installation did not complete.'
  fi
}

summary_on_exit() {
  original_status=$?
  trap - 0
  set +e
  if [ "${SUMMARY_ACTIVE:-0}" -eq 1 ]; then summary_render "$original_status"; fi
  exit "$original_status"
}
```

Initialize with `summary_reset` after modules load. Install `trap summary_on_exit 0` only after valid command arguments, platform validation, and a non-empty manifest have been selected.

- [ ] **Step 4: Run summary tests and syntax checks**

Run: `sh tests/test-dotfiles-install.sh`

Expected: `All dotfiles-install tests passed.`

Run: `sh -n home/dot_local/bin/executable_dotfiles-install home/dot_local/lib/bombwcc-dotfiles/common.sh`

Expected: exit 0.

- [ ] **Step 5: Commit the summary framework**

```sh
git add tests/test-dotfiles-install.sh \
  home/dot_local/lib/bombwcc-dotfiles/common.sh \
  home/dot_local/bin/executable_dotfiles-install
git commit -m "Add installer readiness summary"
```

---

### Task 3: Declare manifests for every supported profile and extension

**Files:**
- Modify: `tests/test-dotfiles-install.sh`
- Modify: `home/dot_local/bin/executable_dotfiles-install`
- Modify: `home/dot_local/lib/bombwcc-dotfiles/profiles/minimal.sh`
- Modify: `home/dot_local/lib/bombwcc-dotfiles/profiles/full.sh`
- Modify: `home/dot_local/lib/bombwcc-dotfiles/extensions/dev.sh`
- Modify: `home/dot_local/lib/bombwcc-dotfiles/extensions/ai.sh`
- Modify: `home/dot_local/lib/bombwcc-dotfiles/extensions/server.sh`

**Interfaces:**
- Produces: `summary_manifest_minimal`, `summary_manifest_full`, `summary_manifest_dev`, `summary_manifest_ai`, and `summary_manifest_server`.
- Each manifest calls `summary_add LABEL COMMAND --version` for commands promised on the active platform.
- Consumes: `OS_NAME`, `summary_reset`, and `summary_add`.

- [ ] **Step 1: Add failing manifest and entry-point tests**

Add assertions that call each dry-run and inspect its final `Planned` block:

```sh
output=$(sh "$INSTALLER" --dry-run --os linux minimal 2>&1)
assert_contains "$output" 'Installation summary'
assert_contains "$output" 'Planned:'
assert_contains "$output" '  - Zsh'
assert_contains "$output" '  - fd'
assert_contains "$output" '  - bat'
assert_contains "$output" 'Installation completed.'

output=$(sh "$INSTALLER" --dry-run --os linux full 2>&1)
assert_contains "$output" '  - Zsh'
assert_contains "$output" '  - SQLite'
assert_contains "$output" '  - Codex Security'

output=$(sh "$INSTALLER" --dry-run --os linux extension dev 2>&1)
assert_contains "$output" '  - Python'
assert_contains "$output" '  - uv'
assert_contains "$output" '  - Node.js'

output=$(sh "$INSTALLER" --dry-run --os linux extension ai 2>&1)
assert_contains "$output" '  - Codex CLI'
assert_contains "$output" '  - Claude Code'
assert_contains "$output" '  - Oh My Pi'

output=$(sh "$INSTALLER" --dry-run --os linux extension server 2>&1)
assert_contains "$output" '  - OpenSSH Server'
assert_contains "$output" '  - Docker'
assert_contains "$output" 'docker-compose-v2'
```

Add this failure-path fixture, which prevents network access and preserves the fake APT status:

```sh
failure_root="$test_tmp/failure-root"
mkdir -p "$failure_root/bin" "$failure_root/lib" "$failure_root/fake-bin"
cp "$INSTALLER" "$failure_root/bin/dotfiles-install"
cp -R "$LIB_ROOT" "$failure_root/lib/bombwcc-dotfiles"
printf '#!/bin/sh\nexit 23\n' > "$failure_root/fake-bin/apt-get"
printf '#!/bin/sh\nexec "$@"\n' > "$failure_root/fake-bin/sudo"
chmod +x "$failure_root/fake-bin/apt-get" "$failure_root/fake-bin/sudo"

if output=$(PATH="$failure_root/fake-bin:/usr/bin:/bin" \
  sh "$failure_root/bin/dotfiles-install" --os linux minimal 2>&1); then
  printf 'FAIL: required APT failure unexpectedly succeeded\n' >&2
  failures=$((failures + 1))
else
  status=$?
  assert_equals "$status" 23
  assert_contains "$output" 'Installation did not complete.'
fi
```

- [ ] **Step 2: Run tests and verify manifest assertions fail**

Run: `sh tests/test-dotfiles-install.sh`

Expected: FAIL because no selected command registers summary items or activates the exit hook.

- [ ] **Step 3: Implement platform-specific manifest functions**

Add functions beside their installers. The Linux minimal manifest contains:

```sh
summary_manifest_minimal() {
  summary_add 'Zsh' zsh --version
  summary_add 'Git' git --version
  summary_add 'curl' curl --version
  summary_add 'wget' wget --version
  summary_add 'Nano' nano --version
  summary_add 'jq' jq --version
  summary_add 'ripgrep' rg --version
  summary_add 'rsync' rsync --version
  summary_add 'OpenSSH Client' ssh -V
  if [ "$OS_NAME" = linux ]; then summary_add 'tmux' tmux -V; fi
  summary_add 'Starship' starship --version
  summary_add 'btop' btop --version
  summary_add 'fastfetch' fastfetch --version
  summary_add 'eza' eza --version
  summary_add 'bat' bat --version
  summary_add 'fd' fd --version
  summary_add 'procs' procs --version
  summary_add 'zoxide' zoxide --version
  summary_add 'fzf' fzf --version
}
```

Add these explicit manifest functions:

```sh
summary_manifest_full() {
  summary_manifest_minimal
  summary_add 'SQLite' sqlite3 --version
  summary_add '7-Zip' 7z --help
  summary_add 'yq' yq --version
  summary_add 'sd' sd --version
  summary_add 'broot' broot --version
  summary_add 'Yazi' yazi --version
  summary_add 'lazygit' lazygit --version
  summary_add 'delta' delta --version
  summary_add 'GitHub CLI' gh --version
  summary_add 'direnv' direnv --version
  summary_add 'xh' xh --version
  summary_add 'gping' gping --version
  if [ "$OS_NAME" = macos ]; then
    summary_add 'doggo' doggo --version
  else
    summary_add 'dog' dog --version
  fi
  summary_add 'mdcat' mdcat --version
  summary_add 'tealdeer' tldr --version
  summary_add 'FFmpeg' ffmpeg --version
  summary_add 'yt-dlp' yt-dlp --version
  summary_add 'Codex Security' codex-security --version
}

summary_manifest_dev() {
  summary_add 'Python' python3 --version
  summary_add 'uv' uv --version
  summary_add 'fnm' fnm --version
  summary_add 'Node.js' node --version
  summary_add 'npm' npm --version
  summary_add 'Rust/Cargo' cargo --version
  summary_add 'tree-sitter' tree-sitter --version
}

summary_manifest_ai() {
  summary_add 'Codex CLI' codex --version
  summary_add 'Claude Code' claude --version
  summary_add 'Oh My Pi' omp --version
}

summary_manifest_server() {
  summary_add 'OpenSSH Server' /usr/sbin/sshd -V
  summary_add 'vnStat' vnstat --version
  summary_add 'fail2ban' fail2ban-client --version
  summary_add 'UFW' ufw --version
  summary_add 'Docker' docker --version
}
```

Docker Compose and Buildx are subcommands rather than independent commands. Keep their availability in the immediate APT `SKIP`/install output and list `Docker` once in the final command-readiness summary. Do not use `eval` for probes.

- [ ] **Step 4: Select and activate manifests in the entry point**

Add one entry-point helper:

```sh
activate_summary() {
  summary_reset
  "$1"
  SUMMARY_ACTIVE=1
  trap summary_on_exit 0
}
```

After validating each command's argument count, call the exact manifest before installation:

```sh
minimal) activate_summary summary_manifest_minimal; install_minimal ;;
full) activate_summary summary_manifest_full; install_full ;;
dev) activate_summary summary_manifest_dev; install_extension_dev ;;
ai) activate_summary summary_manifest_ai; install_extension_ai ;;
server) activate_summary summary_manifest_server; install_extension_server ;;
```

Keep `mac` on the existing install path without a summary because it is outside this Debian support scope. Validate all arguments before `activate_summary` so usage errors do not print a summary.

- [ ] **Step 5: Run the complete shell suite**

Run: `sh tests/test-dotfiles-install.sh`

Expected: `All dotfiles-install tests passed.` including the non-zero failure fixture.

Run: `sh -n home/dot_local/bin/executable_dotfiles-install home/dot_local/lib/bombwcc-dotfiles/common.sh home/dot_local/lib/bombwcc-dotfiles/profiles/*.sh home/dot_local/lib/bombwcc-dotfiles/extensions/*.sh`

Expected: exit 0.

- [ ] **Step 6: Commit manifests and entry-point integration**

```sh
git add tests/test-dotfiles-install.sh \
  home/dot_local/bin/executable_dotfiles-install \
  home/dot_local/lib/bombwcc-dotfiles/profiles/minimal.sh \
  home/dot_local/lib/bombwcc-dotfiles/profiles/full.sh \
  home/dot_local/lib/bombwcc-dotfiles/extensions/dev.sh \
  home/dot_local/lib/bombwcc-dotfiles/extensions/ai.sh \
  home/dot_local/lib/bombwcc-dotfiles/extensions/server.sh
git commit -m "Report profile installation results"
```

---

### Task 4: Verify Debian 12 in Docker and document the support contract

**Files:**
- Create: `tests/test-debian-12-install.sh`
- Modify: `README.md`

**Interfaces:**
- Produces: `tests/test-debian-12-install.sh`, an opt-in integration command requiring Docker and network access.
- Consumes: repository root mounted read-only at `/repo` inside `debian:12`.

- [ ] **Step 1: Add the Debian integration script**

Create `tests/test-debian-12-install.sh` with checks that expect the new detection and summary behavior:

```sh
#!/bin/sh
set -eu

REPO=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

docker run --rm \
  -v "$REPO:/repo:ro" \
  -w /repo \
  debian:12 \
  sh -eu -c '
    apt-get update >/dev/null
    apt-get install -y ca-certificates dash >/dev/null

    output=$(sh home/dot_local/bin/executable_dotfiles-install --dry-run minimal)
    printf "%s\n" "$output"
    printf "%s\n" "$output" | grep -F "Installation summary" >/dev/null
    printf "%s\n" "$output" | grep -F "Planned:" >/dev/null
    printf "%s\n" "$output" | grep -F "apt-get install" >/dev/null

    . home/dot_local/lib/bombwcc-dotfiles/common.sh
    detect_linux_distro /etc/os-release
    [ "$DISTRO_NAME" = debian ]
    [ "$DISTRO_VERSION" = 12 ]

    for package in zsh git curl wget unzip nano jq ripgrep rsync openssh-client tmux bat fd-find; do
      apt-cache show "$package" >/dev/null
    done
  '
```

Make it executable through Chezmoi/Git: `chmod +x tests/test-debian-12-install.sh`.

- [ ] **Step 2: Run the integration verification**

Run: `sh tests/test-debian-12-install.sh`

Expected: exit 0 after Tasks 1–3. This is an environment-level verification layered on top of the failing unit/regression tests already observed before each production change.

- [ ] **Step 3: Update README with exact Debian 12 behavior**

Update the opening support statement and installer sections to say:

```markdown
支持 macOS、Ubuntu 和 Debian 12。Linux 安装器会读取 `/etc/os-release`；
其他 Linux 发行版会在修改软件包前明确退出。
```

Document that Debian 12 uses configured APT repositories only, optional packages may be skipped, no backports or third-party repositories are added, and server extensions do not enable services or modify firewall rules. Add a summary legend:

```text
Ready    command is available after the run
Missing  command is still unavailable
Planned  dry-run installation plan; no readiness claim
SKIP     optional package or platform action was not performed
```

Add `sh tests/test-debian-12-install.sh` to the test section and label it as requiring Docker and network access.

- [ ] **Step 4: Run all local and Debian verification**

Run:

```sh
sh tests/test-dotfiles-install.sh
sh tests/test-git-pager.sh
sh tests/test-nano-config.sh
sh -n home/dot_local/bin/executable_dotfiles-install \
  home/dot_local/lib/bombwcc-dotfiles/common.sh \
  home/dot_local/lib/bombwcc-dotfiles/installers/*.sh \
  home/dot_local/lib/bombwcc-dotfiles/profiles/*.sh \
  home/dot_local/lib/bombwcc-dotfiles/extensions/*.sh
chezmoi --source "$PWD" managed >/dev/null
chezmoi --source "$PWD" apply --dry-run --verbose
sh tests/test-debian-12-install.sh
git diff --check
```

Expected: every command exits 0; shell tests print their pass messages; Chezmoi dry-run reports no rendering error; Debian container assertions produce the planned summary; `git diff --check` is silent.

- [ ] **Step 5: Commit integration verification and documentation**

```sh
git add tests/test-debian-12-install.sh README.md
git commit -m "Verify Debian 12 installer support"
```

---

### Task 5: Final requirements audit

**Files:**
- Review: `docs/superpowers/specs/2026-08-10-debian-12-compatibility-design.md`
- Review: `docs/superpowers/specs/2026-07-29-installation-summary-design.md`
- Review: all files changed in Tasks 1–4.

**Interfaces:**
- Consumes: all preceding task deliverables.
- Produces: a clean, evidence-backed implementation ready for branch handoff.

- [ ] **Step 1: Compare implementation against both approved specs**

Check each requirement explicitly: Debian 12 platform recognition, Ubuntu preservation, unsupported Linux rejection, no repository/firewall mutation, required/optional behavior, all five command manifests, English summary, original failure status, dry-run semantics, Docker verification, and README coverage.

- [ ] **Step 2: Run the full verification commands again from a clean shell**

Run the complete command block from Task 4 Step 4 without omitting the Docker test.

Expected: all commands exit 0 with no test failures or syntax errors.

- [ ] **Step 3: Inspect the final repository state**

Run:

```sh
git status --short --branch
git log -6 --oneline --decorate
git diff HEAD~4..HEAD --check
```

Expected: no uncommitted implementation files, four focused implementation commits after the plan/spec commits, and no whitespace errors.
