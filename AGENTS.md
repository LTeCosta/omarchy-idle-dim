# Idle Dim contributor instructions

This repository is one Omarchy shell plugin, Idle Dim (`io.github.ltecosta.idle-dim`), meant to be usable by anyone running Omarchy. Keep it general, self-contained and safe to run inside the shell.

## Structure

- The repository root is the plugin: `manifest.json`, the QML and JavaScript it loads, `i18n/en.json`, `tests/`, `README.md`, `CHANGELOG.md` and `LICENSE`. `omarchy plugin add https://github.com/LTeCosta/omarchy-idle-dim.git` installs a clone of it into `~/.config/omarchy/plugins/io.github.ltecosta.idle-dim/`, and `omarchy plugin update io.github.ltecosta.idle-dim` fast-forwards that clone to `main`.
- The plugin id is `io.github.ltecosta.idle-dim`; it is also the IPC target.
- `scripts/check` validates the plugin and runs its tests; `.github/workflows/validation.yml` runs it on every push and pull request.

## Generality

- No machine-specific values: no host names, user names, home paths, hardware models, account names or private data in code, defaults, tests, fixtures or screenshots. Resolve paths from `HOME` or the XDG variables, and expose choices as manifest settings with sensible defaults.
- A machine's choices (whether the plugin is installed, its bar placement and settings) belong in the consuming workstation repository, not here.
- Read Omarchy's own files and talk to its services through `omarchy-shell <target> <method>`; never write files that Omarchy or another plugin owns. The plugin's own state goes in `~/.local/state/omarchy/<id>/`, created with mode 0700, and holds no more than it needs.

## Shell code

- Treat every string from senders, files, IPC, settings and command output as untrusted: set `textFormat: Text.PlainText` on every `Text`, bound and validate parsed data, run commands as argv arrays (`Process`, `Quickshell.execDetached`), never through a shell string, and open URLs only after checking them.
- Code the plugin needs beyond the shell (a root helper, a service, a script) lives in this repository (`backend/`, or beside the QML for a small script), tested with Python `unittest` suites in `tests/` against simulated system files, and its installation is documented in the README. Units, PolicyKit actions and other system files ship as `examples/`; a machine's own copies and values belong in its workstation repository.

## Validation and releases

- Run `scripts/check` before every commit.
- To try an unpublished change in the running shell, check it out in the installed clone (`git -C ~/.config/omarchy/plugins/<id> fetch <path-to-your-clone> <branch>` and `git -C ~/.config/omarchy/plugins/<id> checkout --detach FETCH_HEAD`), run `omarchy-restart-shell` (the shell keeps loaded QML until it restarts) and check `journalctl --user -o cat` for warnings that name the plugin. Once the change is on `main`, return the clone with `git -C ~/.config/omarchy/plugins/<id> checkout main` and `omarchy plugin update <id>`.
- Bump the manifest `version` (semantic versioning) and add a `CHANGELOG.md` entry for each user-visible change.
- Write code, comments, documentation and commit messages in English; commit subjects are imperative sentences.
