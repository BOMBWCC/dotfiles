# Dotfiles Installer and Initial Publish Design

## Goal

Publish `bombwcc/dotfiles` as a Chezmoi-managed dotfiles repository with a modular, repeatable installer and documentation that describes only currently supported behavior.

## Installation interface

The public commands remain:

```sh
dotfiles-install [--dry-run] [--os macos|linux] minimal
dotfiles-install [--dry-run] [--os macos|linux] full
dotfiles-install [--dry-run] [--os macos|linux] extension dev|ai|server|mac
```

`minimal` installs the smallest usable shell environment. `full` always runs `minimal` first and then installs general-purpose terminal tools. Extensions remain opt-in and retain their existing implemented contents. The `repair` command and machine-local install profile are removed. Users repair or extend an installation by rerunning `minimal`, `full`, or the relevant extension.

## Installer structure

The applied layout is:

```text
~/.local/bin/dotfiles-install
~/.local/lib/bombwcc-dotfiles/
├── common.sh
├── installers/
│   ├── fastfetch.sh
│   ├── fnm.sh
│   ├── rustup.sh
│   ├── starship.sh
│   ├── uv.sh
│   └── zoxide.sh
├── profiles/
│   ├── minimal.sh
│   └── full.sh
└── extensions/
    ├── ai.sh
    ├── dev.sh
    ├── mac.sh
    └── server.sh
```

The entry point only parses arguments, detects the operating system, loads modules relative to its own path, and dispatches a profile. `common.sh` owns logging, dry-run behavior, command checks, privilege handling, Homebrew bootstrap, and package-manager helpers.

Ordinary CLI tools use APT or Homebrew. Zinit manages only Zsh plugins. Tools unavailable or unsuitable through a platform package manager use a dedicated installer module. Development, AI, server, and macOS-specific software remain in extensions. A tool has one primary installation source.

## Repeatability and failure behavior

Profiles are safe to rerun. APT and Homebrew ensure declared packages are present. Dedicated installers skip an already available command unless their installation procedure requires reconciliation. Full always includes minimal, so adding a future minimal tool also adds it to future full runs.

Required minimal-package failures stop the command. Optional full tools that are unavailable from the active Linux repositories are reported and skipped. Extensions do not silently enable services, firewall rules, credentials, or authentication.

## Documentation

Create a concise `README.md` containing:

- project purpose and supported platforms;
- Chezmoi bootstrap and apply workflow;
- `minimal`, `full`, and extension commands;
- exact currently implemented tool groups;
- directory structure and module responsibilities;
- repeat-run behavior;
- private and sensitive file boundaries;
- Ghostty SSH terminfo behavior;
- test commands and common troubleshooting.

Delete `list.md`. The README becomes the user-facing source of truth, while installer modules remain the behavioral source of truth. Tools that are not implemented are not presented as automatically installed.

## Repository hygiene and publication

Expand `.gitignore` for macOS metadata, editor files, logs, temporary files, caches, local environment files, credentials, Chezmoi local state, and generated Rime data. Remove existing `.DS_Store` files from the project tree. Preserve safe example files such as `private.zsh.example`.

Before publishing:

1. run installer dry-run regression tests;
2. run pager tests;
3. run shell syntax checks on every installer module;
4. render or verify Chezmoi-managed files;
5. scan tracked candidates for common secrets and private keys;
6. review the complete staged file list.

Initialize the repository on `main`, configure `git@github.com:BOMBWCC/dotfiles.git` as `origin`, commit the intended project contents, and push directly to the currently empty GitHub repository. A pull request is unnecessary for the initial publication because no remote base branch exists.

## Success criteria

- `minimal`, `full`, and all extension dry runs dispatch correctly on macOS and Linux.
- `full` includes minimal and no `repair` command or profile state remains.
- Chezmoi maps the modular installer into `~/.local/bin` and `~/.local/lib`.
- README commands match real installer behavior.
- tests and syntax checks pass.
- no generated metadata, credentials, tokens, or private keys are included.
- the initial project is available on `BOMBWCC/dotfiles` on branch `main`.
