# ── tools (mise) ──────────────────────────────────────────────
# activate, then apply PATH now so the inits below can find the tools
eval "$(~/.local/bin/mise activate zsh)"
eval "$(~/.local/bin/mise hook-env -s zsh)"

# appendWindowsPath=false keeps Windows out of PATH; bring back the
# Windows binaries (clip.exe, explorer.exe for `open`), appended so Linux wins
path+=(/mnt/c/Windows/System32 /mnt/c/Windows)
# VS Code's `code` CLI, so `code .` opens the folder through the Remote - WSL extension
# (user install first, then system-wide; (N) drops patterns that match nothing)
vscode=(/mnt/c/Users/*/AppData/Local/Programs/Microsoft\ VS\ Code/bin(N) "/mnt/c/Program Files/Microsoft VS Code/bin"(N))
(( $#vscode )) && path+=($vscode[1])
unset vscode

# ── history ───────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks extended_history

# ── options ───────────────────────────────────────────────────
setopt auto_cd auto_pushd pushd_ignore_dups interactive_comments no_beep
WORDCHARS=${WORDCHARS//\/}   # ctrl-w stops at /

# ── completion ────────────────────────────────────────────────
P=~/.zsh/plugins
fpath=($P/zsh-completions/src $fpath)
autoload -Uz compinit && compinit -i -d ~/.cache/zcompdump
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'
(( $+commands[kubectl] )) && source <(kubectl completion zsh)
(( $+commands[helm] )) && source <(helm completion zsh)
(( $+commands[k9s] )) && source <(k9s completion zsh)
# crictl warns on stderr about the missing /etc/crictl.yaml on every run
(( $+commands[crictl] )) && source <(crictl completion zsh 2>/dev/null)
(( $+commands[stern] )) && source <(stern --completion zsh)
(( $+commands[gh] )) && source <(gh completion -s zsh)
(( $+commands[uv] )) && source <(uv generate-shell-completion zsh)
(( $+commands[rg] )) && source <(rg --generate complete-zsh)
autoload -Uz bashcompinit && bashcompinit
(( $+commands[terraform] )) && complete -o nospace -C terraform terraform
(( $+commands[vault] )) && complete -o nospace -C vault vault

# fzf-tab must come after compinit, before widgets that wrap completion
source $P/fzf-tab/fzf-tab.plugin.zsh
zstyle ':fzf-tab:complete:(cd|z|__zoxide_z):*' fzf-preview 'eza -1 --color=always --icons $realpath'

# ── keys ──────────────────────────────────────────────────────
bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[3~' delete-char

# ── theme: the frog's colours (Windows Terminal scheme "marcy") ─
export BAT_THEME=ansi   # bat follows the terminal palette
export FZF_DEFAULT_OPTS="--layout=reverse --height=40% --border=rounded \
--color=bg+:#1f3328,fg:#d6e4d6,fg+:#f2f8f4,hl:#8fc470,hl+:#b4e08f,info:#6c968c \
--color=prompt:#8fc470,pointer:#8fc470,marker:#e6c86e,spinner:#acd6cd,header:#6c968c,border:#3e6260"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#4a5e52'

# ── integrations ──────────────────────────────────────────────
# fzf's keybindings need a terminal; without one (zsh -i -c from scripts) they error
[[ -t 0 ]] && (( $+commands[fzf] )) && source <(fzf --zsh)
(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd cd)"
(( $+commands[starship] )) && eval "$(starship init zsh)"

# ── aliases ───────────────────────────────────────────────────
if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first --icons'
  alias ll='ls -lh --git'
  alias la='ll -a'
  alias lt='eza --tree --level=2 --icons'
fi
(( $+commands[bat] )) && alias cat='bat --paging=never --style=plain'
alias k=kubectl
alias kctx=kubectx
alias kns=kubens
alias tf=terraform
alias zj=zellij
alias ..='cd ..'
alias ...='cd ../..'
alias open=explorer.exe

# ── plugins that must load last ───────────────────────────────
source $P/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
source $P/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
unset P

# ── greeting: once per terminal, not in every zellij pane ─────
# `if`, not `&&`: a false test would leave status 1 behind (red first prompt, failed `zsh -c exit`)
if [[ -o login && -z $ZELLIJ ]]; then motd; fi
