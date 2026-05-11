#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# HEX RED PHANTOM Installer – Shell version
set -euo pipefail

# ── ANSI color and style definitions ───────────────────────────────
R="\033[0m"    B="\033[1m"
W="\033[97m"   GR="\033[90m"
G1="\033[38;5;46m"  Y1="\033[93m"
C1="\033[38;5;51m"  r1="\033[38;5;196m"
BAR_COL="\033[38;5;196m"

# Hide / show cursor
hide_cursor()  { printf "\033[?25l"; }
show_cursor()  { printf "\033[?25h"; }
clear_screen() { printf "\033[2J\033[H"; }

# Terminal size
tcols() { tput cols 2>/dev/null || echo 80; }
tlines(){ tput lines 2>/dev/null || echo 24; }

# Visual length: strip ANSI and count emoji width≈2
vlen() {
    local s="$1" clean w=0 ch cp
    clean=$(printf "%s" "$s" | sed -E 's/\x1b\[[0-9;]*m//g')
    while IFS= read -r -n1 ch; do
        [ -z "$ch" ] && continue
        cp=$(printf "%d" "'$ch")
        if ( [ "$cp" -ge 0x2300 ] && [ "$cp" -le 0x27BF ] ) || \
           ( [ "$cp" -ge 0x1F000 ] && [ "$cp" -le 0x1FFFF ] ); then
            w=$((w+2))
        else
            w=$((w+1))
        fi
    done <<< "$clean"
    echo "$w"
}

# Center text with spaces
center() {
    local msg="$1" pad cols lag
    cols=$(tcols)
    lag=$(( (cols - $(vlen "$msg")) / 2 ))
    [ "$lag" -lt 0 ] && lag=0
    pad=$(printf "%*s" "$lag" "")
    printf "%s%s" "$pad" "$msg"
}

# Clear current line
clrline() { printf "\033[2K\r"; }

# ── ASCII banner and animation ─────────────────────────────────────
BANNER=(
  "  ██╗  ██╗███████╗██╗  ██╗  "
  "  ██║  ██║██╔════╝╚██╗██╔╝  "
  "  ██║  ██║█████╗   ╚███╔╝   "
  "  ██║  ██║██╔══╝   ██╔██╗   "
  "  ██║  ██║███████╗██╔╝ ██╗  "
  "  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝  "
)
BANNER_W=33  # max length without ANSI

PULSE_SEQ=(
  "\033[38;5;52m" "\033[38;5;88m" "\033[38;5;124m"
  "\033[38;5;160m" "\033[38;5;196m" "\033[38;5;203m"
  "\033[38;5;209m" "\033[38;5;203m" "\033[38;5;196m"
  "\033[38;5;160m" "\033[38;5;124m" "\033[38;5;88m"
  "\033[38;5;52m"
)

draw_banner() {
    local col="$1" pad_top="$2"
    printf "\033[H"
    local i; for ((i=0;i<pad_top;i++)); do printf "\n"; done
    local line side
    local cols
    cols=$(tcols)
    side=$(( (cols - BANNER_W) / 2 ))
    [ "$side" -lt 0 ] && side=0
    local spc
    spc=$(printf "%*s" "$side" "")
    for line in "${BANNER[@]}"; do
        printf "%s%b%b%b%s\n" "$spc" "$col" "$B" "$line" "$R"
    done
}

banner_pulse() {
    hide_cursor; clear_screen
    local pad_top
    pad_top=$(( ( $(tlines) - ${#BANNER[@]} - 10 ) / 2 ))
    [ "$pad_top" -lt 2 ] && pad_top=2

    local col i j
    # first seven colors slowly
    for i in {0..6}; do
        draw_banner "${PULSE_SEQ[$i]}" $pad_top
        sleep 0.055
    done
    # three cycles through all colors
    for j in {1..3}; do
        for col in "${PULSE_SEQ[@]}"; do
            draw_banner "$col" $pad_top
            sleep 0.042
        done
    done
    # final red
    draw_banner "\033[38;5;196m" $pad_top

    # separator line
    local sep
    sep="─"$({ seq 1 $(( $(tcols)-4 )); } 2>/dev/null | tr -d '\n')
    sep="${sep:0:$(( BANNER_W+6 ))}"
    local side
    side=$(( ( $(tcols) - ${#sep} ) / 2 ))
    [ "$side" -lt 0 ] && side=0
    printf "\n%${side}s%b%s%b\n" "" "$GR" "$sep" "$R"
    show_cursor
}

# ── Info box ───────────────────────────────────────────────────────
info_box() {
    printf "\n"
    local msg1 msg2
    msg1="${r1}${B}✦${R} ${W}${B}HEX RED PHANTOM INSTALLER${R} ${r1}${B}✦${R}"
    printf "%b\n" "$(center "$msg1")$msg1"
    sleep 0.05
    msg2="${GR}ﺭﺎﻈﺘﻧﻻﺍ ﻮﺟﺮﻤﻟﺍ ...${R}"
    printf "%b\n" "$(center "$msg2")$msg2"
    printf "\n"
}

# ── Spinner ────────────────────────────────────────────────────────
spin_chars=('⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷')
spinner_running=false
spinner_pid=""

start_spinner() {
    local msg="$1" col="${2:-$C1}"
    spinner_running=true
    (
        hide_cursor
        local i=0
        while $spinner_running; do
            local icon="${spin_chars[$((i % ${#spin_chars[@]}))]}"
            printf "\033[2K\r  %b%b%b%s  %b%s%b %s ...   " \
                "$col" "$B" "$icon" "$R" "$W" "$msg" "$GR" "$R"
            i=$((i+1))
            sleep 0.08
        done
        clrline
        show_cursor
    ) &
    spinner_pid=$!
}

stop_spinner() {
    spinner_running=false
    wait "$spinner_pid" 2>/dev/null || true
    local ok="$1" msg="$2"
    local icon
    if $ok; then
        icon="${G1}${B}✓${R}"
    else
        icon="${r1}${B}✗${R}"
    fi
    if [ -n "$msg" ]; then
        printf "\033[2K\r  %b  %b%s%b\n" "$icon" "$W" "$msg" "$R"
    fi
}

# ── Platform detection (same logic as Python script) ───────────────
detect_platform() {
    local sys mach android=false
    sys=$(uname -s | tr '[:upper:]' '[:lower:]')
    mach=$(uname -m | tr '[:upper:]' '[:lower:]')

    # Android check (common methods)
    if [ "$(uname -o 2>/dev/null)" = "Android" ] || [ -n "${ANDROID_ROOT:-}" ]; then
        android=true
    fi

    if $android; then
        case "$mach" in
            aarch64|arm64|armv8*) echo "hex_phantom_android_arm64" ;;
            *)                     echo "hex_phantom_android_armv7" ;;
        esac
    elif [ "$sys" = "windows" ] || [[ "$sys" =~ mingw|cygwin|msys ]]; then
        if [[ "$mach" =~ 64|amd64 ]]; then echo "hex_phantom_windows_x64.exe"
        else echo "hex_phantom_windows_x86.exe"; fi
    elif [ "$sys" = "linux" ]; then
        case "$mach" in
            x86_64|amd64)  echo "hex_phantom_linux_x64" ;;
            aarch64|arm64) echo "hex_phantom_linux_arm64" ;;
            armv7*)        echo "hex_phantom_linux_armv7" ;;
            *)             echo "hex_phantom_linux_x86" ;;
        esac
    else
        return 1
    fi
}

# ── Download with progress bar (using curl) ────────────────────────
NET_TIMEOUT=20
RETRY_WAIT=5
download_file() {
    local url="$1" dest="$2"
    local attempt=0 rc
    local opts=(-L -# --connect-timeout "$NET_TIMEOUT" --max-time 0)

    printf "\n"
    center "⏳  ...ﻞﻴﻤﺤﺘﻟﺍ ﻱﺭﺎﺟ" && printf "%b\n" "${Y1}⏳  ...ﻞﻴﻤﺤﺘﻟﺍ ﻱﺭﺎﺟ${R}"

    while true; do
        if [ -f "$dest" ]; then
            # Resume from existing partial file
            opts+=(-C -)
        else
            # Remove -C if no file
            opts=(${opts[@]//-C -/})
        fi

        # Actually download with retry + resume
        curl "${opts[@]}" --retry 9999 --retry-delay "$RETRY_WAIT" \
            --retry-max-time 0 -o "$dest" "$url"
        rc=$?
        if [ $rc -eq 0 ]; then
            break
        fi
        # If curl fails due to range not satisfiable (e.g., server doesn't support resume)
        # remove partially downloaded file and reset opts
        if [ -f "$dest" ]; then
            rm -f "$dest"
        fi
        for t in $(seq $RETRY_WAIT -1 1); do
            clrline
            printf "  %b%b⟳%b  %bﺔﻜﺒﺸﻟﺍ ﺭﺎﻈﺘﻧﺍ%b  %b%b%2ds%b  %b#%d%b  %b·%b" \
                "$r1" "$B" "$R" "$W" "$R" "$Y1" "$B" "$t" "$R" "$GR" "$attempt" "$R" "$r1" "$R"
            sleep 1
        done
        attempt=$((attempt+1))
    done

    # Completion message (flash)
    local ok_msg="  ✓  ﻞﻴﻤﺤﺘﻟﺍ ﻢﺗ  ✓  "
    local col
    for col in "$G1" "$W" "$G1" "$W" "$G1"; do
        clrline
        printf "%s%b%b%s%b" "$(center "$ok_msg")" "$col" "$B" "$ok_msg" "$R"
        sleep 0.13
    done
    printf "\n\n"
}

# ── Status line ────────────────────────────────────────────────────
status_line() {
    local icon="$1" col="$2" text="$3" delay="${4:-0.2}"
    printf "  %b%b%s%b  %b%s%b\n" "$col" "$B" "$icon" "$R" "$W" "$text" "$R"
    sleep "$delay"
}

# ── Main ───────────────────────────────────────────────────────────
main() {
    trap 'show_cursor; exit' INT TERM

    banner_pulse
    info_box

    start_spinner " " "$C1"
    sleep 1.0
    local plat
    plat=$(detect_platform) || plat=""
    stop_spinner false ""

    if [ -z "$plat" ]; then
        status_line "✗" "$r1" "Unknown platform. Exiting." 0.5
        exit 1
    fi

    local src_dir
    src_dir="$(dirname "$(readlink -f "$0")")/src"

    # Check if binary already present locally
    if [ -f "$src_dir/$plat" ]; then
        status_line "→" "$G1" "...ﺮﺷﺎﺒﻣ ﻞﻴﻐﺸﺗ" 1
        if [[ "$plat" == hex_phantom_windows* ]]; then
            "$src_dir/$plat" "$@"
        else
            chmod +x "$src_dir/$plat"
            "$src_dir/$plat" "$@"
        fi
        exit 0
    fi

    # Fetch latest release tag from GitHub
    local tag
    start_spinner " ...ﻝﺎﺼﺗﻻﺍ ﻱﺭﺎﺟ" "$r1"
    tag=$(curl -s --connect-timeout "$NET_TIMEOUT" \
        "https://api.github.com/repos/ma-dark404/MikroTik-HEX/releases/latest" \
        | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4) || true
    if [ -z "$tag" ]; then
        stop_spinner false ""
        # Retry loop (simplified: let curl handle retries before this)
        local att=1 t
        while [ -z "$tag" ]; do
            for t in $(seq $RETRY_WAIT -1 1); do
                clrline
                printf "  %b%b⟳%b  %bﺔﻜﺒﺸﻟﺍ ﺭﺎﻈﺘﻧﺍ%b  %b%b%2ds%b  %b#%d%b  %b·%b\n" \
                    "$r1" "$B" "$R" "$W" "$R" "$Y1" "$B" "$t" "$R" "$GR" "$att" "$R" "$r1" "$R"
                sleep 1
            done
            tag=$(curl -s --connect-timeout "$NET_TIMEOUT" \
                "https://api.github.com/repos/ma-dark404/MikroTik-HEX/releases/latest" \
                | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4) || true
            att=$((att+1))
        done
        stop_spinner true "ﻝﺎﺼﺗﻻﺍ ﻢﺗ"
    else
        stop_spinner true "ﻝﺎﺼﺗﻻﺍ ﻢﺗ"
    fi

    # Build download URL
    local dl_url="https://github.com/ma-dark404/MikroTik-HEX/releases/download/${tag}/${plat}"

    # Download the binary
    download_file "$dl_url" "$plat"

    # Run
    status_line "✓" "$G1" "...ﻞﻴﻐﺸﺘﻟﺍ ﻱﺭﺎﺟ" 0.5
    if [[ "$plat" == hex_phantom_windows* ]]; then
        ./"$plat" "$@"
    else
        chmod +x "$plat"
        ./"$plat" "$@"
    fi
}

main "$@"
