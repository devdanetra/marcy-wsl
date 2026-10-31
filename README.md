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
- **look after servers and networks**: Ansible, plus the usual sysadmin toolkit for processes, disks, DNS and packet debugging
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

### Updating

A new marcy release also brings new configs and new tools. The welcome banner will tell you when one is out:

```text
[+] ver  v2026.10.29-3 :: update v2026.10.30-1 available
```

Installing a release replaces the whole distro, so back up anything you want to keep first:

```powershell
wsl --export marcy marcy-backup.tar                              # full backup of the current install
& ([scriptblock]::Create((irm https://wsl.danetra.dev))) -Force  # install the latest release
```

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
| --- | --- |
| Kubernetes | k3s (local cluster), kubectl, helm, k9s, crictl, kubectx/kubens (`kctx`, `kns`), stern (multi-pod logs) |
| Infrastructure | terraform, vault, ansible (core) |
| Sysadmin: processes and disks | htop, btop, ncdu, duf, dust, lsof, strace, iostat, iotop-c, pstree |
| Sysadmin: network | ip, ping, dig, doggo, traceroute, mtr, gping, nc, socat, nmap, tcpdump, whois, ethtool, openssl |
| Sysadmin: files | vim, nano, rsync, wget, tree, file, zip |
| Languages | go, node (LTS, with the latest npm), rust (rustfmt, clippy), uv (Python) |
| Git | gh |
| Shell | zsh, starship, fzf, fzf-tab, zoxide, eza, bat, ripgrep, autosuggestions, syntax highlighting |
| Terminal | zellij (sessions survive closing the terminal) |

The Windows PATH is kept out of Linux, so Windows tools don't shadow Linux ones. `clip.exe` and `explorer.exe` (aliased to `open`) still work, and so does `code .` if VS Code is installed on Windows (it opens the folder through the WSL extension).

The welcome banner shows the system, uptime and load, LAN and public IP, and your marcy version compared with the latest release. It appears once per terminal, not in every zellij pane. The public IP is looked up on first start (trying several providers), then cached and refreshed in the background every 15 minutes. The release check runs in the background and is cached for 6 hours. Set `NO_MOTD=1` to hide it, or `MOTD_NOFROG=1` to hide just the frog.

### Look and feel

Everything uses marcy's frog colours: the welcome banner, a **marcy** colour scheme for Windows Terminal (set up automatically with the profile), the starship prompt, zellij, fzf and bat.

The prompt shows the folder, git branch and status, the current Kubernetes context and namespace, the Terraform workspace, language versions inside projects, and how long slow commands took. **Contexts with "prod" in the name turn red.** Customise it in `~/.config/starship.toml`.

The icons need a Nerd Font, by default marcy is shipped with Liberation Mono.

### Local Kubernetes cluster

marcy ships [k3s](https://k3s.io), a single-node Kubernetes that runs straight on systemd, no Docker needed. It's installed but off, so it uses no memory until you want it:

```bash
k3s-up      # start it (and on every boot), add context "k3s" to ~/.kube/config
k9s         # or kubectl, helm... against the k3s context
k3s-down    # stop it and keep it off; cluster data is kept for the next k3s-up
```

It comes with k3s's defaults: Traefik as ingress controller on ports 80/443, local-path storage and a load balancer, so `LoadBalancer` services work. Change the server flags in `/etc/rancher/k3s/config.yaml`. `sudo crictl` shows the cluster's containers.

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

Local builds are marked `dev` (the banner shows "local build"). Set `MARCY_VERSION` to give one a real version number; CI uses the release tag.

### Tests

```bash
bash scripts/test.sh                 # all suites
bash scripts/test.sh icon installer  # just the fast ones
```

| Suite | Checks |
| --- | --- |
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
