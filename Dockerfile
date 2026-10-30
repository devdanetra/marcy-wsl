FROM ubuntu:24.04

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
  sudo curl git zsh ca-certificates unzip build-essential locales \
  openssh-client gnupg jq \
  && locale-gen en_US.UTF-8 \
  && rm -rf /var/lib/apt/lists/*

ARG USER=marcy
RUN userdel -r ubuntu 2>/dev/null || true \
  && useradd -m -u 1000 -s /bin/zsh -G sudo $USER \
  && echo "$USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER

COPY wsl.conf /etc/wsl.conf
COPY wsl-distribution.conf /etc/wsl-distribution.conf
COPY assets/marcy.ico /usr/lib/wsl/marcy.ico
COPY --chmod=755 configs/motd.sh /usr/local/bin/motd

USER $USER
WORKDIR /home/$USER

RUN curl -fsSL https://mise.run | sh
COPY --chown=$USER mise.toml .config/mise/config.toml
# clean download caches in the same layer, or they still ship in the image
RUN ~/.local/bin/mise install \
  && rm -rf ~/.cache/* ~/.cargo/registry ~/.cargo/git ~/.local/share/mise/downloads

RUN mkdir -p ~/.zsh/plugins && cd ~/.zsh/plugins \
  && for r in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting \
  zsh-users/zsh-completions Aloxaf/fzf-tab; do \
  git clone -q --depth 1 https://github.com/$r; \
  done \
  && touch ~/.hushlogin

COPY --chown=$USER configs/zsh/.zshrc .zshrc
COPY --chown=$USER configs/zellij/ .config/zellij/
