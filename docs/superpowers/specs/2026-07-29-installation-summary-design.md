# Installation Summary Design

## Goal

Add a concise English summary to `dotfiles-install` so users can tell which tools are ready after a profile or extension runs and which tools remain unavailable.

The summary reports verified machine state rather than attempting to infer package-manager actions. This makes repeated runs reliable and treats tools installed before the current run the same as tools installed during it.

## User-visible behavior

After a real installation attempt, the installer prints an `Installation summary` with two groups:

- `Ready`: commands found after installation, with a one-line version when it can be obtained safely.
- `Missing`: commands that are still unavailable.

If the requested installation finishes successfully, the summary ends with `Installation completed.` If a required step fails, the installer preserves the non-zero exit status and ends with `Installation did not complete.` The summary still prints on this failure path and reflects the state observable at that point.

For `--dry-run`, no readiness claim is made. The installer prints a `Planned` list containing the tools associated with the selected profile or extension.

All new summary text is in English.

## Scope and tool lists

Each command owns a declared list of user-facing tool names and the commands used to verify them:

- `minimal` reports only the tools promised by the platform-specific minimal profile.
- `full` reports both minimal tools and full-only tools.
- `extension NAME` reports only tools promised by that extension on the selected platform.

Package names and verification commands are distinct. For example, Ubuntu's `fd-find` package is verified through `fd`, and `bat` is verified through `bat` after compatibility links are created. Libraries and infrastructure packages without a meaningful user command are not listed individually.

Optional packages that are unavailable in a platform repository appear under `Missing` after a real run. This replaces the need to understand earlier `SKIP` lines when reading the final outcome.

## Architecture

Shared summary helpers live in `common.sh`. They maintain the selected summary manifest, verify commands, obtain bounded version strings, and render the final report.

Profile and extension modules declare their manifests close to their installation logic. The entry point selects the manifest before invoking the installer and installs an exit handler that renders exactly one summary. The handler receives the original exit status, prints the appropriate completion message, and returns that status unchanged.

Version probing is best-effort. A failed or noisy version command must not change a tool from `Ready` to `Missing` and must not fail the installation. Output is reduced to one line; when no safe version probe is defined, the tool is listed without a version.

The implementation remains POSIX `sh` compatible and does not introduce external parsing dependencies.

## Error handling

Required installation failures retain the installer's current fail-fast behavior. The exit handler temporarily disables fail-fast behavior while checking commands so that summary generation cannot hide or replace the original error.

Summary rendering itself is defensive: missing commands, unsupported version flags, or malformed version output cannot cause a successful installation to fail. A failure before a manifest is selected, such as invalid command-line arguments, prints usage as it does today and does not print an installation summary.

## Testing

Shell tests exercise the real installer entry point with controlled command lookup:

1. A successful run renders `Ready` and `Installation completed.`
2. An unavailable optional command renders under `Missing`.
3. `--dry-run` renders `Planned` and never claims readiness.
4. A required command failure retains its non-zero exit status and still renders `Installation did not complete.`
5. Linux compatibility mappings verify `fd-find` as `fd` and `bat` as `bat`.
6. macOS and Linux manifests contain only tools promised by the selected profile or extension.
7. Existing modular-installer regression tests continue to pass.

Tests are written and observed failing before production changes are made.
