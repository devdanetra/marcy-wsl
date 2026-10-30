#!/usr/bin/env bash
[[ -n $NO_MOTD ]] && exit 0
export LC_ALL=C.UTF-8
E=$'\e'

# ── theme: one green, taken from the frog's toes ──────────────
GREEN="143;196;112"
G="$E[1;38;2;${GREEN}m"                 # banner / accents
DG="$E[38;2;86;128;78m"                 # dim green (labels, rule)
TXT="$E[38;2;214;228;214m"              # values
R="$E[0m"

BANNER=(
"▄▄█▄▄▄██ ▄▄█▀▀█▄  ██▀▀█▄ ▄▄█▀▀▀ ███ ███"
"███▀▀███ ███▄▄██  ██▄▄█▀  ██     ▀▀▄▄██"
"███  ███ ███ ███  ██▀▀██  ██▄▄▄     ███"
)

# ── data ──────────────────────────────────────────────────────
cache="${XDG_CACHE_HOME:-$HOME/.cache}/motd"; mkdir -p "$cache"
pub_file="$cache/public_ip"
if [[ ! -s $pub_file || -n $(find "$pub_file" -mmin +60 2>/dev/null) ]]; then
  ( curl -fsS --max-time 3 https://ifconfig.me > "$pub_file.tmp" 2>/dev/null \
      && mv "$pub_file.tmp" "$pub_file" || rm -f "$pub_file.tmp" ) &>/dev/null &
  disown 2>/dev/null
fi
pub=$(cat "$pub_file" 2>/dev/null); pub=${pub:-resolving…}

. /etc/os-release 2>/dev/null
if grep -qi microsoft /proc/version 2>/dev/null; then
  [[ $(uname -r) == *WSL2* ]] && wsl="WSL2" || wsl="WSL1"; wsl+="/${WSL_DISTRO_NAME:-?}"
else wsl="bare-metal"; fi
up=$(awk '{d=int($1/86400);h=int($1%86400/3600);m=int($1%3600/60);
  if(d)printf "%dd %dh",d,h; else if(h)printf "%dh %dm",h,m; else printf "%dm",m}' /proc/uptime)
read -r l1 l5 l15 _ < /proc/loadavg
lip=$(hostname -I 2>/dev/null | awk '{print $1}')

# ── right column: banner + rule + readout ─────────────────────
SEP=" ${DG}::${R} "
RIGHT=()
for row in "${BANNER[@]}"; do RIGHT+=("${G}${row}${R}"); done
RIGHT+=(
  "${DG}───────────────────────────────────────${R}"
  "${G}[+]${R} ${DG}sys${R}  ${TXT}${PRETTY_NAME:-linux}${R}${SEP}${TXT}${wsl}${R}"
  "${G}[+]${R} ${DG}up ${R}  ${TXT}${up}${R}${SEP}${DG}load${R} ${TXT}${l1} ${l5} ${l15}${R}"
  "${G}[+]${R} ${DG}net${R}  ${DG}lan${R} ${TXT}${lip:-n/a}${R}${SEP}${DG}wan${R} ${TXT}${pub}${R}"
)

# ── compose: frog on the left, right column vertically centred ─
FROG_W=18
mapfile -t FROG <<'FROG_EOF'
           \e[38;2;143;196;112m▐\e[0m \e[38;2;143;196;112m▗\e[0m
      \e[38;2;172;214;205m▗\e[0m\e[38;2;143;196;112m\e[48;2;172;214;205m▀\e[0m\e[38;2;172;214;205m▙\e[0m\e[38;2;172;214;205m▄\e[0m \e[38;2;108;150;140m\e[48;2;143;196;112m▀\e[0m\e[38;2;143;196;112m\e[48;2;108;150;140m▛\e[0m\e[38;2;143;196;112m▌\e[0m
     \e[38;2;143;196;112m▟\e[0m\e[38;2;108;150;140m\e[48;2;172;214;205m▙\e[0m\e[38;2;172;214;205m█\e[0m\e[38;2;172;214;205m█\e[0m\e[38;2;172;214;205m\e[48;2;108;150;140m▙\e[0m\e[38;2;143;196;112m\e[48;2;108;150;140m▛\e[0m\e[38;2;108;150;140m█\e[0m\e[38;2;62;98;96m\e[48;2;143;196;112m▄\e[0m
  \e[38;2;143;196;112m▝\e[0m\e[38;2;143;196;112m▀\e[0m\e[38;2;143;196;112m\e[48;2;62;98;96m▜\e[0m\e[38;2;143;196;112m\e[48;2;108;150;140m▙\e[0m\e[38;2;108;150;140m\e[48;2;143;196;112m▀\e[0m\e[38;2;108;150;140m█\e[0m\e[38;2;172;214;205m\e[48;2;232;244;240m▀\e[0m\e[38;2;172;214;205m\e[48;2;108;150;140m▙\e[0m\e[38;2;108;150;140m█\e[0m\e[38;2;108;150;140m▘\e[0m\e[38;2;62;98;96m▝\e[0m
  \e[38;2;143;196;112m▌\e[0m \e[38;2;172;214;205m▝\e[0m\e[38;2;143;196;112m\e[48;2;172;214;205m▟\e[0m\e[38;2;108;150;140m█\e[0m\e[38;2;108;150;140m\e[48;2;232;244;240m▛\e[0m\e[38;2;232;244;240m█\e[0m\e[38;2;232;244;240m\e[48;2;108;150;140m▙\e[0m\e[38;2;108;150;140m▌\e[0m
 \e[38;2;143;196;112m▚\e[0m\e[38;2;143;196;112m█\e[0m\e[38;2;143;196;112m▄\e[0m\e[38;2;108;150;140m▖\e[0m \e[38;2;62;98;96m▜\e[0m\e[38;2;232;244;240m\e[48;2;143;196;112m▜\e[0m\e[38;2;232;244;240m█\e[0m\e[38;2;232;244;240m█\e[0m\e[38;2;232;244;240m▌\e[0m    \e[38;2;143;196;112m▟\e[0m\e[38;2;108;150;140m▖\e[0m
  \e[38;2;143;196;112m▐\e[0m\e[38;2;143;196;112m\e[48;2;108;150;140m▛\e[0m\e[38;2;108;150;140m\e[48;2;143;196;112m▟\e[0m\e[38;2;108;150;140m\e[48;2;172;214;205m▙\e[0m\e[38;2;172;214;205m▟\e[0m\e[38;2;143;196;112m\e[48;2;108;150;140m▀\e[0m\e[38;2;172;214;205m\e[48;2;108;150;140m▜\e[0m\e[38;2;232;244;240m\e[48;2;172;214;205m▀\e[0m\e[38;2;172;214;205m▙\e[0m\e[38;2;108;150;140m▗\e[0m\e[38;2;108;150;140m▄\e[0m\e[38;2;108;150;140m▄\e[0m\e[38;2;143;196;112m\e[48;2;108;150;140m▌\e[0m\e[38;2;143;196;112m▛\e[0m\e[38;2;143;196;112m▘\e[0m
   \e[38;2;108;150;140m▝\e[0m\e[38;2;108;150;140m█\e[0m\e[38;2;108;150;140m█\e[0m\e[38;2;172;214;205m▘\e[0m\e[38;2;108;150;140m▀\e[0m\e[38;2;108;150;140m█\e[0m\e[38;2;108;150;140m█\e[0m\e[38;2;62;98;96m\e[48;2;108;150;140m▟\e[0m\e[38;2;62;98;96m\e[48;2;108;150;140m▌\e[0m\e[38;2;108;150;140m\e[48;2;62;98;96m▛\e[0m\e[38;2;108;150;140m\e[48;2;143;196;112m▟\e[0m\e[38;2;108;150;140m▛\e[0m
     \e[38;2;108;150;140m▜\e[0m\e[38;2;62;98;96m▖\e[0m   \e[38;2;62;98;96m▐\e[0m\e[38;2;62;98;96m▙\e[0m
FROG_EOF
[[ -n $MOTD_NOFROG ]] && FROG=()
nf=${#FROG[@]}; nr=${#RIGHT[@]}; n=$(( nf > nr ? nf : nr ))
fo=$(( (n - nf) / 2 )); ro=$(( (n - nr) / 2 ))
printf -v blank '%*s' "$FROG_W" ''
for (( i = 0; i < n; i++ )); do
  f=$blank; r=""
  (( nf && i >= fo && i - fo < nf )) && f=${FROG[i-fo]}
  (( i >= ro && i - ro < nr )) && r=${RIGHT[i-ro]}
  if (( nf )); then printf ' %b   %s\n' "$f" "$r"; else printf '  %s\n' "$r"; fi
done
