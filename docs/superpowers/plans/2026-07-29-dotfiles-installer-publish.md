# Dotfiles Installer and Initial Publish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modularize the Chezmoi installer, document the supported profiles, clean repository metadata, verify the project, and publish it to `BOMBWCC/dotfiles`.

**Architecture:** Keep `~/.local/bin/dotfiles-install` as a thin POSIX shell dispatcher. Load shared functions, profile definitions, dedicated installers, and opt-in extensions from `~/.local/lib/bombwcc-dotfiles` using a path relative to the entry point.

**Tech Stack:** POSIX shell, Chezmoi, APT, Homebrew, Git, GitHub SSH.

## Global Constraints

- `full` always includes `minimal`.
- `minimal`, `full`, and extensions are safe to rerun.
- Remove `repair` and install-profile state.
- Zinit manages only Zsh plugins; ordinary CLI tools use platform package managers.
- Extensions retain their current implemented contents and remain opt-in.
- README documents only current behavior.
- Push the reviewed initial repository directly to the empty remote `main` branch.

---

### Task 1: Lock the public installer behavior with tests

**Files:**
- Modify: `tests/test-dotfiles-install.sh`

**Interfaces:**
- Consumes: `home/dot_local/bin/executable_dotfiles-install`
- Produces: regression expectations for modular loading, repeatable profiles, and absence of `repair`

- [ ] Add assertions that `minimal`, `full`, and each extension dry-run dispatch on both supported platforms where applicable.
- [ ] Assert `full` contains minimal tools and full-only tools.
- [ ] Assert `repair` returns usage failure and no install-profile file is referenced.
- [ ] Run `sh tests/test-dotfiles-install.sh` and verify the new repair assertion fails against the old entry point.
- [ ] Commit the test change with `git commit -m "Test modular installer interface"`.

### Task 2: Split the installer into focused modules

**Files:**
- Modify: `home/dot_local/bin/executable_dotfiles-install`
- Create: `home/dot_local/lib/bombwcc-dotfiles/common.sh`
- Create: `home/dot_local/lib/bombwcc-dotfiles/installers/{fastfetch,fnm,rustup,starship,uv,zoxide}.sh`
- Create: `home/dot_local/lib/bombwcc-dotfiles/profiles/{minimal,full}.sh`
- Create: `home/dot_local/lib/bombwcc-dotfiles/extensions/{ai,dev,mac,server}.sh`

**Interfaces:**
- Produces: `detect_os`, `install_minimal`, `install_full`, `install_extension`, package-manager helpers, and dedicated installer functions
- Entry point sources every module from `../lib/bombwcc-dotfiles` relative to its own directory

- [ ] Move logging, dry-run, OS detection, privilege, APT, and Homebrew helpers into `common.sh`.
- [ ] Move non-package-manager installation procedures into one installer file per tool.
- [ ] Move minimal and full package declarations into profile modules; make `install_full` invoke `install_minimal` first.
- [ ] Move current dev, AI, server, and macOS contents into extension modules.
- [ ] Reduce the entry point to module loading, argument parsing, and dispatch; remove state and repair code.
- [ ] Run `sh -n` over the entry point and all module files.
- [ ] Run both test scripts and verify they pass.
- [ ] Commit with `git commit -m "Modularize dotfiles installer"`.

### Task 3: Create project documentation and repository hygiene

**Files:**
- Create: `README.md`
- Modify: `.gitignore`
- Delete: `list.md`
- Delete: all `.DS_Store` files under the repository

**Interfaces:**
- README exposes Chezmoi bootstrap, install profiles, exact tool groups, layout, privacy boundaries, Ghostty SSH behavior, rerun semantics, tests, and troubleshooting.

- [ ] Write README commands that match the entry point exactly.
- [ ] Document macOS and Ubuntu/Debian minimal/full tool sets and all existing extensions.
- [ ] Explain that rerunning a profile adds newly declared tools but package upgrades remain package-manager responsibilities.
- [ ] Expand `.gitignore` for OS metadata, editors, logs, caches, environment files, credentials, Chezmoi local state, and generated Rime data while preserving examples.
- [ ] Remove `list.md` and `.DS_Store` files.
- [ ] Scan README for stale `~/.config/ghostty/config`; require `config.ghostty`.
- [ ] Commit with `git commit -m "Document dotfiles setup"`.

### Task 4: Verify the complete repository

**Files:**
- Modify only files required to correct verification failures.

**Interfaces:**
- Produces fresh evidence for tests, syntax, Chezmoi rendering, and privacy review.

- [ ] Run `sh tests/test-dotfiles-install.sh` and `sh tests/test-git-pager.sh`.
- [ ] Run `sh -n` for every shell entry point, module, test, and Chezmoi shell script template where directly parseable.
- [ ] Run representative macOS/Linux dry-runs for minimal, full, and extensions.
- [ ] Run `chezmoi --source "$PWD" managed` and a dry-run apply against the source.
- [ ] Scan candidate files for private keys, common token formats, passwords, generated state, and absolute user paths.
- [ ] Review `git status --short` and `git diff --check`.

### Task 5: Publish the initial repository

**Files:**
- Git metadata only

**Interfaces:**
- Produces: `main` at `git@github.com:BOMBWCC/dotfiles.git`

- [ ] Add `origin` using the SSH URL and verify the remote is empty.
- [ ] Stage all intended files and inspect `git diff --cached --stat` plus `git diff --cached --name-status`.
- [ ] Commit the remaining verified project contents with `git commit -m "Publish Chezmoi dotfiles"`.
- [ ] Re-run the full verification suite from the committed tree.
- [ ] Push `main` with tracking and confirm `git status -sb` is synchronized.
