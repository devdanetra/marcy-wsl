<p align="center"><img src="assets/marcy.png" width="96" alt="marcy frog icon"></p>

# marcy-wsl

[![Latest release](https://img.shields.io/github/v/release/devdanetra/marcy-wsl?label=release)](https://github.com/devdanetra/marcy-wsl/releases/latest)
[![Build](https://github.com/devdanetra/marcy-wsl/actions/workflows/release.yml/badge.svg?branch=main)](https://github.com/devdanetra/marcy-wsl/actions/workflows/release.yml)
[![Vulnerabilities](https://img.shields.io/endpoint?url=https%3A%2F%2Fgithub.com%2Fdevdanetra%2Fmarcy-wsl%2Freleases%2Flatest%2Fdownload%2Fvuln-badge.json)](https://github.com/devdanetra/marcy-wsl/releases/latest#vulnerability-scan)

A ready-to-use WSL2 distro for platform, DevOps and SRE engineers who work on Windows but live in a Linux terminal.

## Who it's for

You'll get the most out of marcy if you:

- **run Kubernetes**: you use kubectl, helm and k9s every day, and sometimes need crictl on a node
- **build infrastructure as code**: you work with Terraform and keep secrets in Vault
- **also write code**: Go, Node, Python (via uv) and Rust are installed and ready
- **want a fast terminal**: zsh with autosuggestions, fzf, zoxide, starship and zellij, set up out of the box
- **want the same environment everywhere**: every machine, and everyone on the team, gets an identical, versioned setup from one command

It's probably not for you if you want a minimal base image to customise from scratch, or a desktop Linux experience. marcy is opinionated and terminal-first.

## Install

You need Windows 10/11 with WSL2. If you haven't set up WSL yet, run `wsl --install --no-distribution` as admin and reboot.

```powershell
irm https://wsl.danetra.dev | iex
```

Then start it with `wsl -d marcy`, or use the **marcy** entry in the Start menu or Windows Terminal.

Options:

```powershell
# replace an existing install (deletes its data)
& ([scriptblock]::Create((irm https://wsl.danetra.dev))) -Force

# install a specific release, or under a different name
& ([scriptblock]::Create((irm https://wsl.danetra.dev))) -Version v2026.10.30-12 -Name marcy-test

# build from source with Docker instead of downloading a release
& ([scriptblock]::Create((irm https://wsl.danetra.dev))) -FromSource
```

The installer downloads the latest [release](https://github.com/devdanetra/marcy-wsl/releases/latest), checks its SHA-256 checksum and registers it with WSL.

## Security

Every release is scanned with [Trivy](https://trivy.dev) before it's published.

- **Ubuntu packages:** a release is blocked if any HIGH or CRITICAL vulnerability already has a fix. The image runs `apt-get upgrade` at build time, so those fixes are normally applied.
- **Prebuilt tools** (kubectl, k9s, vault and the others installed by mise): findings are reported but don't block a release. marcy always ships the latest release of each tool, so only the tool's maintainers can fix what's inside it.
- **Kernel headers** (`linux-libc-dev`) are excluded: their CVEs are bugs in the Linux kernel, and WSL runs Microsoft's kernel instead.

For the latest release:

- **[Scan summary](https://github.com/devdanetra/marcy-wsl/releases/latest#vulnerability-scan)**: counts by severity and a list of HIGH/CRITICAL findings, in the release notes
- **[vuln-report.json](https://github.com/devdanetra/marcy-wsl/releases/latest/download/vuln-report.json)**: the full Trivy report, every severity included
- **[vuln-report.sarif](https://github.com/devdanetra/marcy-wsl/releases/latest/download/vuln-report.sarif)**: the same results in SARIF, for security tooling
- **[Code scanning alerts](https://github.com/devdanetra/marcy-wsl/security/code-scanning)**: findings tracked over time in GitHub's Security tab

Vulnerabilities without a fix upstream are still listed in the reports, so you can see them. Accepted exceptions are documented in [`.trivyignore`](.trivyignore) (single CVEs) and [`tests/trivy-ignore.rego`](tests/trivy-ignore.rego) (whole packages).

## What's inside

Ubuntu 24.04 with systemd enabled. The default user is `marcy`, with passwordless sudo and zsh as the shell. All tools are managed by [mise](https://mise.jdx.dev), so `mise upgrade` keeps them current.

| Area | Tools |
|---|---|
| Kubernetes | kubectl, helm, k9s, crictl |
| Infrastructure | terraform, vault |
| Languages | go, node (LTS), rust, uv (Python) |
| Git | gh |
| Shell | zsh, starship, fzf, fzf-tab, zoxide, eza, bat, ripgrep, autosuggestions, syntax highlighting |
| Terminal | zellij (sessions survive closing the terminal) |

The Windows PATH is kept out of Linux, so Windows tools don't shadow Linux ones. `clip.exe` and `explorer.exe` (aliased to `open`) still work.

Set `NO_MOTD=1` to hide the welcome banner.

## Development

```
Dockerfile               image definition
mise.toml                CLI tools and versions
configs/                 zsh, zellij and motd
wsl.conf                 WSL runtime settings
wsl-distribution.conf    shortcut, icon, Windows Terminal profile
install.ps1              Windows installer
scripts/                 build, icon generation and test runner
tests/                   installer, icon, image and vulnerability tests
```

Build a `.wsl` package locally (needs Docker):

```bash
bash scripts/build-wsl.sh            # writes dist/marcy.wsl + .sha256
wsl --install --from-file dist/marcy.wsl --name marcy-dev
```

### Tests

```bash
bash scripts/test.sh                 # all suites
bash scripts/test.sh icon installer  # just the fast ones
```

| Suite | Checks |
|---|---|
| `icon` | the icon is valid and still matches the frog in the motd |
| `installer` | `install.ps1` logic, with WSL and downloads mocked (needs Pester 5) |
| `image` | user, shell, config, every tool on PATH, and the package contents |
| `vuln` | Trivy scan: fails on fixable HIGH/CRITICAL in Ubuntu packages, reports everything else |

Turn on the pre-commit hook once per clone. It runs only the suites your staged files affect:

```bash
git config core.hooksPath .githooks
SKIP_IMAGE_TESTS=1 git commit ...    # skip the slow Docker build
```

### Releases

Every push to `main` builds the image, runs every test suite and publishes a GitHub release tagged `vYYYY.MM.DD-<run>`, containing `marcy.wsl`, its checksum and the vulnerability reports. Pull requests run the same build and tests without publishing.

After editing the frog in `configs/motd.sh`, regenerate the icon with `python scripts/make-icon.py`.
