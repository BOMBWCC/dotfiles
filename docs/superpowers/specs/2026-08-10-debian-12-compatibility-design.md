# Debian 12 Compatibility Design

## Goal

Make Debian 12 a verified, first-class target for the Chezmoi-managed installer. Support covers the `minimal` and `full` profiles plus the `dev`, `ai`, and `server` extensions without silently treating every Linux distribution as an APT system.

The installer uses Debian's configured repositories and existing upstream installers. It does not add backports, third-party APT repositories, Docker repositories, or firewall rules.

## Supported platforms

Runtime platform detection has two levels:

- `OS_NAME` distinguishes `macos` and `linux`.
- Linux detection reads `/etc/os-release` and sets a distribution identifier and version.

Debian and Ubuntu use the existing APT installation path. Unsupported Linux distributions fail early with a clear message before package installation begins. macOS behavior remains unchanged.

The existing `--os linux` dry-run override remains available and selects the shared Debian/Ubuntu package plan without requiring the host to provide `/etc/os-release`. Tests of automatic detection inject deterministic os-release content rather than depending on the host machine. User-facing commands do not need a new distribution override.

## Debian 12 package policy

Required packages are limited to the stable foundation needed by a selected profile or extension. A required package failure stops the installer with a non-zero status.

Packages whose names or availability vary by configured repository remain optional. The installer checks APT metadata before attempting each optional package and continues when it is unavailable.

For Debian 12:

- `minimal` installs the base shell and terminal packages from APT.
- Debian command aliases map `batcat` to `bat` and `fdfind` to `fd` under `~/.local/bin`.
- Starship, zoxide, and fastfetch retain their current upstream installation paths. Fastfetch supports only the existing `amd64` and `arm64` mappings.
- `full` attempts repository-provided enhanced tools individually and skips unavailable packages without adding another repository.
- `dev` installs compilation and Python prerequisites from APT, then uses the existing upstream installers for uv, fnm, and rustup. Node.js LTS and tree-sitter installation retain their current flow.
- `ai` retains its current npm and upstream-script flow and documents its Node.js/npm prerequisite.
- `server` installs OpenSSH Server, vnStat, fail2ban, and UFW as required packages. Docker, Compose, and Buildx remain optional and depend on configured repositories.

The installer does not enable services, modify SSH policy, or change firewall rules automatically.

## Installation summary integration

The previously approved installation-summary design is implemented as part of this work because Debian repository differences must be visible at the end of a run.

After a real run, an English summary reports commands that are `Ready` and commands that remain `Missing`. A successful run ends with `Installation completed.` A required-step failure preserves the original non-zero status, prints the observable partial result, and ends with `Installation did not complete.`

Dry runs print a `Planned` list and do not claim that tools are installed. Package names and verification commands remain distinct, including `fd-find` to `fd` and `bat` to `bat` mappings.

Unavailable optional packages continue to emit an immediate `SKIP` line and are also represented accurately in the final result. A missing optional tool does not turn an otherwise successful profile into a failed run.

## Components and data flow

`common.sh` owns:

- Linux distribution detection and support validation.
- APT required and optional package helpers.
- Summary manifest registration, command verification, bounded version probing, and final rendering.

Profile and extension modules declare platform-specific summary manifests next to their installation logic. The entry point validates the platform, selects the requested manifest, installs a single exit handler, and invokes the requested installer.

The exit handler prints at most one summary and returns the original exit status unchanged. Invalid arguments and unsupported platforms fail before summary activation.

## Error handling

Missing or unreadable `/etc/os-release` during automatic Linux detection produces a clear unsupported-platform error. Debian derivatives are not inferred from `ID_LIKE` in this iteration; only explicit Debian and Ubuntu identifiers are supported. An explicit `--os linux` override intentionally bypasses distribution detection for portable dry-run inspection.

Summary version probing is best-effort. A missing version flag or noisy output cannot make installation fail and cannot change an available command to `Missing`.

Temporary files used by release installers are cleaned up on their normal success path. Existing upstream installer failures remain required failures unless the calling profile already treats that tool as optional.

## Verification

Shell regression tests cover:

1. Debian 12 and supported Ubuntu os-release detection.
2. Rejection of a non-APT Linux distribution before package installation.
3. Required and optional APT behavior.
4. Debian `batcat`/`fdfind` compatibility links.
5. Manifests for `minimal`, `full`, `dev`, `ai`, and `server`.
6. Successful, missing-tool, dry-run, and required-failure summaries.
7. Preservation of existing macOS behavior.

A Docker-based integration check uses the official `debian:12` image to verify platform detection, shell portability, APT package metadata, and a minimal dry-run. It does not install large AI packages or modify the host.

All production behavior is developed test-first. The complete shell test suite, syntax checks, Chezmoi dry-run, and Debian 12 integration check must pass before completion is reported.

## Documentation

The README identifies Debian 12 as a verified target and explains:

- which commands are supported;
- that optional package availability follows configured repositories;
- that no third-party APT source is added;
- that server installation does not enable services or change firewall rules;
- how to interpret `Ready`, `Missing`, `Planned`, and `SKIP` output.
