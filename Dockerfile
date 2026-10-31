ARG MARCY_VERSION="0.1.0"
FROM ubuntu:24.04

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
  sudo curl git zsh ca-certificates unzip build-essential locales openssh-client gnupg jq \
  vim nano less tree rsync wget file zip \
  htop btop ncdu lsof strace psmisc procps sysstat iotop-c \
  iproute2 iputils-ping dnsutils traceroute mtr-tiny netcat-openbsd nmap tcpdump socat whois openssl ethtool \
  && locale-gen en_US.UTF-8 \
  && rm -rf /var/lib/apt/lists/*

ARG USER=marcy
RUN userdel -r ubuntu 2>/dev/null || true \
  && useradd -m -u 1000 -s /bin/zsh -G sudo $USER \
  && echo "$USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER

# k3s: local Kubernetes cluster, installed but stopped (k3s-up / k3s-down)
RUN curl -fsSLo /usr/local/bin/k3s https://github.com/k3s-io/k3s/releases/latest/download/k3s \
  && cd /usr/local/bin \
  && curl -fsSL https://github.com/k3s-io/k3s/releases/latest/download/sha256sum-amd64.txt | grep ' k3s$' | sha256sum -c - \
  && chmod 755 k3s
COPY configs/k3s/k3s.service /etc/systemd/system/k3s.service
COPY configs/k3s/config.yaml /etc/rancher/k3s/config.yaml
COPY configs/k3s/crictl.yaml /etc/crictl.yaml
COPY --chmod=755 configs/k3s/k3s-up configs/k3s/k3s-down /usr/local/bin/

COPY wsl.conf /etc/wsl.conf
COPY wsl-distribution.conf /etc/wsl-distribution.conf
COPY assets/marcy.ico /usr/lib/wsl/marcy.ico
COPY configs/windows-terminal.json /usr/lib/wsl/terminal-profile.json
COPY --chmod=755 configs/motd.sh /usr/local/bin/motd

USER $USER
WORKDIR /home/$USER

RUN curl -fsSL https://mise.run | sh
COPY --chown=$USER mise.toml .config/mise/config.toml
# Node ships an older npm whose bundled libraries (undici, brace-expansion...) carry
# fixed CVEs; the latest npm picks up the fixes.
# Clean download caches in the same layer, or they still ship in the image.
RUN ~/.local/bin/mise install \
  && ~/.local/bin/mise exec node -- npm install -g npm@latest \
  && rm -rf ~/.cache/* ~/.npm ~/.cargo/registry ~/.cargo/git ~/.local/share/mise/downloads

RUN mkdir -p ~/.zsh/plugins && cd ~/.zsh/plugins \
  && for r in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting \
  zsh-users/zsh-completions Aloxaf/fzf-tab; do \
  git clone -q --depth 1 https://github.com/$r; \
  done \
  && touch ~/.hushlogin

COPY --chown=$USER configs/zsh/.zshrc .zshrc
COPY --chown=$USER configs/zellij/ .config/zellij/
COPY --chown=$USER configs/starship.toml .config/starship.toml


# Install Liberation Mono font for terminal and editor
COPY assets/fonts/liberationMonoNerdFont/ /usr/local/share/fonts/liberationMonoNerdFont/
RUN fc-cache -fv

RUN echo "$MARCY_VERSION" | sudo tee /etc/marcy-release >/dev/null
