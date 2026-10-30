#!/usr/bin/env bash
[[ -n $NO_MOTD ]] && exit 0
export LC_ALL=C.UTF-8
E=$'\e'

# ── theme: one green, taken from the frog's toes ──────────────
GREEN="143;196;112"
G="$E[1;38;2;${GREEN}m"                 # banner / accents
DG="$E[38;2;86;128;78m"                 # dim green (labels, rule)
TXT="$E[38;2;214;228;214m"              # values
Y="$E[38;2;230;200;110m"                # attention (update available)
R="$E[0m"

BANNER=(
"▄▄█▄▄▄██ ▄▄█▀▀█▄  ██▀▀█▄ ▄▄█▀▀▀ ███ ███"
"███▀▀███ ███▄▄██  ██▄▄█▀  ██     ▀▀▄▄██"
"███  ███ ███ ███  ██▀▀██  ██▄▄▄     ███"
)

# ── data ──────────────────────────────────────────────────────
cache="${XDG_CACHE_HOME:-$HOME/.cache}/motd"; mkdir -p "$cache"

# refresh <file> from <url> in the background when older than <minutes>, so login
# never waits on the network; this run shows the previous value
refresh() {
  local file=$1 url=$2 minutes=$3
  [[ -s $file && -z $(find "$file" -mmin +"$minutes" 2>/dev/null) ]] && return
  ( curl -fsS --max-time 3 "$url" > "$file.tmp" 2>/dev/null \
      && mv "$file.tmp" "$file" || rm -f "$file.tmp" ) &>/dev/null &
  disown 2>/dev/null
}

# public IP: try several providers, accept only something shaped like an IP
# (a provider error page must never end up in the banner)
fetch_ip() {
  local url ip
  for url in https://api.ipify.org https://icanhazip.com https://ifconfig.me/ip; do
    ip=$(curl -fsS --connect-timeout 1 --max-time 2 "$url" 2>/dev/null | tr -d '[:space:]')
    [[ $ip =~ ^[0-9.]+$|^[0-9a-fA-F:]+$ ]] && { echo "$ip"; return 0; }
  done
  return 1
}
ip_file=$cache/public_ip
save_ip() { fetch_ip > "$ip_file.tmp" && mv "$ip_file.tmp" "$ip_file" || rm -f "$ip_file.tmp"; }
if [[ ! -s $ip_file ]]; then
  save_ip                                    # first start: wait for it (a few seconds at most)
elif [[ -n $(find "$ip_file" -mmin +15 2>/dev/null) ]]; then
  ( save_ip ) &>/dev/null & disown 2>/dev/null   # later: refresh in the background
fi
pub=$(cat "$ip_file" 2>/dev/null); pub=${pub:-unavailable}

# installed version (written at build time) vs the latest GitHub release
ver=$(cat /etc/marcy-release 2>/dev/null); ver=${ver:-unknown}
refresh "$cache/latest_release" https://api.github.com/repos/devdanetra/marcy-wsl/releases/latest 360
latest=$(grep -o '"tag_name": *"[^"]*"' "$cache/latest_release" 2>/dev/null | cut -d'"' -f4)
if [[ $ver != v* ]];         then ver_status="${DG}local build${R}"
elif [[ -z $latest ]];       then ver_status="${DG}checking…${R}"
elif [[ $ver == "$latest" ]]; then ver_status="${G}latest${R}"
elif [[ $(printf '%s\n' "$ver" "$latest" | sort -V | tail -1) == "$latest" ]]; then
  ver_status="${Y}update ${latest} available${R}"
else ver_status="${DG}newer than ${latest}${R}"; fi

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
  "${G}[+]${R} ${DG}ver${R}  ${TXT}${ver}${R}${SEP}${ver_status}"
)

# ── compose: frog on the left, right column vertically centred ─
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

# frog rows differ in width; pad each to the widest so the right column lines up.
# visible width = length with the \e[...m colour codes stripped
shopt -s extglob
FROG_PAD=(); FROG_W=0
for row in "${FROG[@]}"; do
  plain=${row//\\e\[*([0-9;])m/}; FROG_PAD+=(${#plain})
  (( ${#plain} > FROG_W )) && FROG_W=${#plain}
done
for i in "${!FROG_PAD[@]}"; do FROG_PAD[i]=$(( FROG_W - FROG_PAD[i] )); done

nf=${#FROG[@]}; nr=${#RIGHT[@]}; n=$(( nf > nr ? nf : nr ))
fo=$(( (n - nf) / 2 )); ro=$(( (n - nr) / 2 ))
for (( i = 0; i < n; i++ )); do
  f=""; pad=$FROG_W; r=""
  (( nf && i >= fo && i - fo < nf )) && { f=${FROG[i-fo]}; pad=${FROG_PAD[i-fo]}; }
  (( i >= ro && i - ro < nr )) && r=${RIGHT[i-ro]}
  if (( nf )); then printf ' %b%*s   %s\n' "$f" "$pad" '' "$r"; else printf '  %s\n' "$r"; fi
done
