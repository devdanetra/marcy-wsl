#!/usr/bin/env bash
# Smoke-test the built image and the exported WSL package.
# Usage: tests/image.sh [image] [package]   (defaults: marcy-wsl:build dist/marcy.wsl)
set -uo pipefail

image=${1:-marcy-wsl:build}
pkg=${2:-dist/marcy.wsl}
fails=0

check() {
  local name=$1; shift
  if out=$("$@" 2>&1); then
    printf '  \e[32mok\e[0m   %s\n' "$name"
  else
    # show the exit code too: a check can fail with no output at all
    printf '  \e[31mFAIL\e[0m %s (exit %d)\n%s\n' "$name" "$?" "$(sed 's/^/       /' <<<"$out")"
    fails=$((fails + 1))
  fi
}

# run a command inside the image as the default user
in_image() { docker run --rm -e NO_MOTD=1 "$image" bash -c "$1"; }

echo "image: $image"
check "default user is marcy (uid 1000)" in_image '[ "$(id -un):$(id -u)" = marcy:1000 ]'
check "login shell is zsh"               in_image '[ "$(getent passwd marcy | cut -d: -f7)" = /bin/zsh ]'
check "passwordless sudo"                in_image 'sudo -n true'
check "ubuntu user removed"              in_image '! id ubuntu'
check "wsl.conf enables systemd"         in_image 'grep -qx "systemd=true" /etc/wsl.conf'
check "wsl.conf sets default user"       in_image 'grep -qx "default=marcy" /etc/wsl.conf'
check "version recorded"                 in_image '[ -s /etc/marcy-release ]'
check "shortcut icon path exists"        in_image 'icon=$(sed -n "s/^icon *= *//p" /etc/wsl-distribution.conf); [ -f "$icon" ]'
check "icon is a valid .ico"             in_image '[ "$(head -c4 /usr/lib/wsl/marcy.ico | od -An -tx1 | tr -d " ")" = 00000100 ]'
check "zsh starts without errors"        in_image '[ -z "$(zsh -i -c true 2>&1)" ]'
check "zsh puts mise tools on PATH"      in_image 'zsh -i -c "command -v starship zoxide fzf eza bat kubectl k9s crictl vault zellij gh rg uv go node" >/dev/null'
check "zsh aliases load"                 in_image 'zsh -i -c "alias ls k" | grep -q eza'
check "motd renders"                    in_image 'NO_MOTD= motd | grep -q "\[+\]"'
check "mise installed"                   in_image '~/.local/bin/mise --version'
for tool in starship fzf zoxide eza bat kubectl helm k9s crictl terraform vault zellij gh rg uv go node npm \
            ansible ansible-playbook duf dust gping doggo; do
  check "mise tool: $tool"               in_image "~/.local/bin/mise which $tool"
done
# one check for all apt sysadmin commands, so a missing one is named in the failure output
check "sysadmin commands installed"      in_image 'missing=; for c in vim nano less tree rsync wget file zip \
  htop btop ncdu lsof strace pstree killall ps free iostat iotop-c \
  ip ping dig traceroute mtr nc nmap tcpdump socat whois openssl ethtool; do
  command -v $c >/dev/null || missing="$missing $c"; done; [ -z "$missing" ] || { echo "missing:$missing"; false; }'
for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-completions fzf-tab; do
  check "zsh plugin: $plugin"            in_image "[ -d ~/.zsh/plugins/$plugin ]"
done

echo "package: $pkg"
listing=$(tar -tzf "$pkg" 2>/dev/null)
has() { grep -qxE "(\./)?$1" <<<"$listing"; }
check "gzip archive is intact"           gzip -t "$pkg"
check "checksum matches"                 bash -c "cd '$(dirname "$pkg")' && sha256sum -c '$(basename "$pkg").sha256'"
check "contains etc/wsl.conf"            has etc/wsl.conf
check "contains etc/wsl-distribution.conf" has etc/wsl-distribution.conf
check "contains usr/lib/wsl/marcy.ico"   has usr/lib/wsl/marcy.ico
no_dockerenv() { ! has '\.dockerenv'; }
check "no .dockerenv marker"             no_dockerenv

echo
if ((fails)); then echo "$fails check(s) failed"; exit 1; fi
echo "all checks passed"
