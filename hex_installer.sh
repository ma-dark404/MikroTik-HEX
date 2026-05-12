#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# HEX RED PHANTOM Installer – Bash version (مطابق حرفياً مع إصلاح التوسيط وكل الأخطاء)
set -euo pipefail

# ── ANSI ────────────────────────────────────────────────
R="\033[0m";    B="\033[1m"
W="\033[97m";   GR="\033[90m"
G1="\033[38;5;46m";  Y1="\033[93m"
C1="\033[38;5;51m";  r1="\033[38;5;196m"
BAR_COL="\033[38;5;196m"

# ── Terminal size ─────────────────────────────────────
tw() { tput cols 2>/dev/null || echo 80; }
th() { tput lines 2>/dev/null || echo 24; }
hide_cursor() { printf "\033[?25l"; }
show_cursor() { printf "\033[?25h"; }
clear_screen() { printf "\033[2J\033[H"; }
clr_line() { printf "\033[2K\r"; }

# ── Resize signal (SIGWINCH) ──────────────────────────
_resize_flag=0
on_resize() {
    _resize_flag=1
    printf "\n"
}
trap on_resize SIGWINCH 2>/dev/null || true

# ── Visual length (strip ANSI, emoji width=2) ─────────
vlen() {
    local s="$1" clean w=0 ch cp
    clean=$(printf "%s" "$s" | sed -E 's/\x1b\[[0-9;]*m//g')
    while IFS= read -r -n1 ch; do
        [ -z "$ch" ] && continue
        cp=$(printf "%d" "'$ch")
        # ranges decimal: 0x2300-0x27BF = 8960-10239, 0x1F000-0x1FFFF = 127744-131071
        if ([ "$cp" -ge 8960 ] && [ "$cp" -le 10239 ]) || \
           ([ "$cp" -ge 127744 ] && [ "$cp" -le 131071 ]); then
            w=$((w+2))
        else
            w=$((w+1))
        fi
    done <<< "$clean"
    printf "%d" "$w"
}

# مراكز النص (ترجع المسافات المطلوبة فقط)
cpad() {
    local str="$1" cols len pad
    cols=$(tw)
    len=$(vlen "$str")
    pad=$(( (cols - len) / 2 ))
    [ $pad -lt 0 ] && pad=0
    printf "%${pad}s" ""
}

# ── ASCII Banner ──────────────────────────────────────
BANNER=(
  "  ██╗  ██╗███████╗██╗  ██╗  "
  "  ██║  ██║██╔════╝╚██╗██╔╝  "
  "  ███████║█████╗   ╚███╔╝   "
  "  ██╔══██║██╔══╝   ██╔██╗   "
  "  ██║  ██║███████╗██╔╝ ██╗  "
  "  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝  "
)
BANNER_W=33

PULSE_SEQ=(
  "\033[38;5;52m" "\033[38;5;88m" "\033[38;5;124m"
  "\033[38;5;160m" "\033[38;5;196m" "\033[38;5;203m"
  "\033[38;5;209m" "\033[38;5;203m" "\033[38;5;196m"
  "\033[38;5;160m" "\033[38;5;124m" "\033[38;5;88m"
  "\033[38;5;52m"
)

_draw_banner() {
    local col="$1" pad_top="$2"
    printf "\033[H"
    local i; for ((i=0;i<$pad_top;i++)); do printf "\n"; done
    local cols=$(tw)
    local side=$(( (cols - BANNER_W) / 2 ))
    [ $side -lt 0 ] && side=0
    local spc=$(printf "%${side}s" "")
    for line in "${BANNER[@]}"; do
        printf "%s%b%b%s%b\n" "$spc" "$col" "$B" "$line" "$R"
    done
}

banner_pulse() {
    hide_cursor; clear_screen
    local pad_top=$(( ( $(th) - ${#BANNER[@]} - 10 ) / 2 ))
    [ $pad_top -lt 2 ] && pad_top=2

    local i col
    for ((i=0;i<7;i++)); do
        _draw_banner "${PULSE_SEQ[$i]}" $pad_top
        sleep 0.055
    done
    for i in {1..3}; do
        for col in "${PULSE_SEQ[@]}"; do
            _draw_banner "$col" $pad_top
            sleep 0.042
        done
    done
    _draw_banner "\033[38;5;196m" $pad_top

    # separator line
    local sep="" c
    for ((c=0;c<BANNER_W+6;c++)); do sep+="─"; done
    local side2=$(( ($(tw) - ${#sep}) / 2 ))
    [ $side2 -lt 0 ] && side2=0
    printf "\n%*s%b%s%b\n" $side2 "" "$GR" "$sep" "$R"
    show_cursor
}

# ── Info box ──────────────────────────────────────────
info_box() {
    printf "\n"
    local msg1="${r1}${B}✦${R} ${W}${B}HEX PHANTOM INSTALLER${R} ${r1}${B}✦${R}"
    printf "%b%b\n" "$(cpad "$msg1")" "$msg1"
    sleep 0.05
    local msg2="${GR}... ﺭﺎﻈﺘﻧﻻﺍ ﺀﺎﺟﺮﻟﺍ${R}"
    printf "%b%b\n" "$(cpad "$msg2")" "$msg2"
    printf "\n"
}

# ── Waiting box ────────────────────────────────────────
waiting_box() {
    printf "\n"
    local inner="${Y1}⏳  ...ﻞﻴﻤﺤﺘﻟﺍ ﻱﺭﺎﺟ${R}"
    printf "%b%b\n" "$(cpad "$inner")" "$inner"
    printf "\n"
}

# ── Spinner ────────────────────────────────────────────
SPIN_FRAMES=('⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷')
spinner_on=false
spinner_pid=""

start_spinner() {
    local msg="$1" col="${2:-$C1}"
    spinner_on=true
    (
        hide_cursor
        local i=0
        while $spinner_on; do
            local f="${SPIN_FRAMES[$((i % 8))]}"
            printf "\033[2K\r  %b%b%s%b  %b%s%b ...   " \
                "$col" "$B" "$f" "$R" "$W" "$msg" "$GR"
            i=$((i+1))
            sleep 0.08
        done
        clr_line
        show_cursor
    ) &
    spinner_pid=$!
}

stop_spinner() {
    spinner_on=false
    wait $spinner_pid 2>/dev/null || true
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

# ── Status line ────────────────────────────────────────
st() {
    local icon="$1" col="$2" text="$3" d="${4:-0.2}"
    printf "  %b%b%s%b  %b%s%b\n" "$col" "$B" "$icon" "$R" "$W" "$text" "$R"
    sleep "$d"
}

# ── Platform detection ─────────────────────────────────
detect_platform() {
    local sys=$(uname -s | tr '[:upper:]' '[:lower:]')
    local mach=$(uname -m | tr '[:upper:]' '[:lower:]')
    local android=false

    if [ "${ANDROID_ROOT:-}" != "" ] || {
        [ -n "$(uname -o 2>/dev/null)" ] && echo "$(uname -o)" | grep -qi android
    }; then
        android=true
    fi

    if $android; then
        case "$mach" in
            *64*) echo "hex_phantom_android_arm64" ;;
            *)    echo "hex_phantom_android_armv7" ;;
        esac
    elif [[ "$sys" =~ (windows|mingw|cygwin|msys) ]]; then
        if [[ "$mach" =~ (64|amd64) ]]; then
            echo "hex_phantom_windows_x64.exe"
        else
            echo "hex_phantom_windows_x86.exe"
        fi
    elif [ "$sys" = "linux" ]; then
        case "$mach" in
            x86_64|amd64)   echo "hex_phantom_linux_x64" ;;
            aarch64|arm64)  echo "hex_phantom_linux_arm64" ;;
            armv7*)         echo "hex_phantom_linux_armv7" ;;
            *)              echo "hex_phantom_linux_x86" ;;
        esac
    else
        return 1
    fi
}

# ── Download with progress + resume + auto reconnect ──
NET_TIMEOUT=20
RETRY_WAIT=5

download_with_progress() {
    local url="$1" dest="$2"

    fz() {
        local b=$1
        if [ "$b" -lt 1024 ]; then printf "%dБ" "$b"
        elif [ "$b" -lt 1048576 ]; then printf "%.1fKB" "$(awk "BEGIN{printf \"%.1f\", $b/1024}")"
        else printf "%.1fMB" "$(awk "BEGIN{printf \"%.1f\", $b/1048576}")"
        fi
    }
    fs() {
        local s=$1
        if [ "$s" -le 0 ]; then printf "───"
        elif [ "$s" -lt 1024 ]; then printf "%dБ/s" "$s"
        elif [ "$s" -lt 1048576 ]; then printf "%.1fKB/s" "$(awk "BEGIN{printf \"%.1f\", $s/1024}")"
        else printf "%.2fMB/s" "$(awk "BEGIN{printf \"%.2f\", $s/1048576}")"
        fi
    }

    local total_size=0 downloaded=0 supports_res=false start_time
    start_time=$(date +%s.%N 2>/dev/null || date +%s)

    head_check() {
        local headers cl ar
        headers=$(curl -sI --connect-timeout "$NET_TIMEOUT" "$url" 2>/dev/null || true)
        if [ -n "$headers" ]; then
            cl=$(echo "$headers" | grep -i '^Content-Length:' | tail -1 | awk '{print $2}' | tr -d '\r')
            ar=$(echo "$headers" | grep -i '^Accept-Ranges:' | tail -1 | tr -d '\r')
            total_size=${cl:-0}
            if echo "$ar" | grep -qi 'bytes'; then
                supports_res=true
            else
                supports_res=false
            fi
        else
            total_size=0
            supports_res=false
        fi
    }

    show_progress() {
        local dl=$1 tot=$2
        if [ "$_resize_flag" -eq 0 ]; then
            clr_line
        fi
        _resize_flag=0

        local cols=$(tw)
        local bw=$((cols - 48))
        [ "$bw" -lt 10 ] && bw=10

        if [ "$tot" -le 0 ]; then
            local bar=""
            local i
            for ((i=0;i<bw;i++)); do bar+="█"; done
            printf "  ${BAR_COL}▌%s%s${BAR_COL}▐${R}  ${W}...ﻞﻴﻤﺤﺘﻟﺍ ﻱﺭﺎﺟ${R}  ${C1}%s${R}" \
                "$BAR_COL" "$bar" "$(fz "$dl")"
            return
        fi

        local pct=$(( dl * 100 / tot ))
        [ "$pct" -gt 100 ] && pct=100
        local filled=$(( bw * pct / 100 ))

        local now elapsed avg_speed
        now=$(date +%s.%N 2>/dev/null || date +%s)
        elapsed=$(awk "BEGIN{printf \"%.3f\", $now - $start_time}")
        [ "${elapsed%.*}" -le 0 ] && elapsed=0.001
        avg_speed=$(awk "BEGIN{printf \"%.0f\", $dl / $elapsed}")

        local bar="$BAR_COL"
        local i
        for ((i=0;i<bw;i++)); do
            if [ $i -lt $filled ]; then bar+="█"; else bar+="${GR}░"; fi
        done
        bar+="$R"

        printf "  ${BAR_COL}▌%s${BAR_COL}▐${R} ${BAR_COL}${B}%3d%%${R}  ${W}%s${GR}/${W}%s${R}  ${C1}%s${R}" \
            "$bar" "$pct" "$(fz "$dl")" "$(fz "$tot")" "$(fs "$avg_speed")"
    }

    show_reconnect() {
        local attempt="$1" secs_left="$2"
        if [ "$_resize_flag" -eq 0 ]; then
            clr_line
        fi
        _resize_flag=0
        local dots=""
        local i
        for ((i=0;i<secs_left%4;i++)); do dots+="·"; done
        printf "  ${r1}${B}⟳${R}  ${W}ﺔﻜﺒﺸﻟﺍ ﺭﺎﻈﺘﻧﺍ${R}  ${GR}ﺔﻴﻧﺎﺛ ${Y1}${B}%2d${R}  ${GR}ﺔﻟﻭﺎﺤﻣ #${Y1}%d${R}  ${r1}%s${R}" \
            "$secs_left" "$attempt" "$dots"
    }

    # ── Initial setup ──────────────────────────────────
    if [ -f "$dest" ]; then
        downloaded=$(stat -c%s "$dest" 2>/dev/null || echo 0)
    fi

    head_check
    if [ "$downloaded" -gt 0 ] && ! $supports_res; then
        rm -f "$dest"
        downloaded=0
    fi

    # Already completed?
    if [ "$total_size" -gt 0 ] && [ "$downloaded" -ge "$total_size" ]; then
        local ok_msg="  ✓  ﻞﻴﻤﺤﺘﻟﺍ ﻢﺗ  ✓  "
        local col
        for col in "$G1" "$W" "$G1" "$W" "$G1"; do
            clr_line
            printf "%b%b%s%b" "$(cpad "$ok_msg")" "$col" "$B" "$ok_msg" "$R"
            sleep 0.13
        done
        printf "\n\n"
        return 0
    fi

    waiting_box

    # ── Main download loop ─────────────────────────────
    local attempt=0
    while true; do
        if [ $attempt -gt 0 ]; then
            head_check
            if [ "$downloaded" -gt 0 ] && ! $supports_res; then
                rm -f "$dest"
                downloaded=0
            fi
        fi

        local curl_opts=(-L -s -S --connect-timeout "$NET_TIMEOUT")
        if [ "$downloaded" -gt 0 ]; then
            curl_opts+=(-C -)
        fi
        curl_opts+=(-o "$dest" "$url")

        curl "${curl_opts[@]}" &
        local pid=$!

        # monitor progress
        while kill -0 $pid 2>/dev/null; do
            if [ -f "$dest" ]; then
                downloaded=$(stat -c%s "$dest" 2>/dev/null || echo 0)
            fi
            show_progress "$downloaded" "$total_size"
            sleep 0.1
        done
        wait $pid
        local rc=$?
        [ -f "$dest" ] && downloaded=$(stat -c%s "$dest" 2>/dev/null || echo 0)

        if [ $rc -eq 0 ]; then
            break
        fi

        # failure: reconnect wait
        attempt=$((attempt+1))
        local s
        for ((s=RETRY_WAIT; s>0; s--)); do
            show_reconnect "$attempt" "$s"
            sleep 1
        done
    done

    # Completion
    local ok_msg="  ✓  ﻞﻴﻤﺤﺘﻟﺍ ﻢﺗ  ✓  "
    local col
    for col in "$G1" "$W" "$G1" "$W" "$G1"; do
        clr_line
        printf "%b%b%s%b" "$(cpad "$ok_msg")" "$col" "$B" "$ok_msg" "$R"
        sleep 0.13
    done
    printf "\n\n"
}

# ── main ────────────────────────────────────────────────
main() {
    trap 'show_cursor; exit' INT TERM

    banner_pulse
    info_box

    start_spinner " " "$C1"
    sleep 1.0
    plat=$(detect_platform) || plat=""
    stop_spinner false ""
    if [ -z "$plat" ]; then
        st "✗" "$r1" "Unsupported platform" 0.5
        exit 1
    fi

    local src_dir
    src_dir="$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")/src"
    local src_file="$src_dir/$plat"

    if [ -f "$src_file" ]; then
        st "→" "$G1" "...ﺮﺷﺎﺒﻣ ﻞﻴﻐﺸﺗ" 1
        if [[ "$plat" == hex_phantom_windows* ]]; then
            "$src_file" "$@"
        else
            chmod +x "$src_file"
            "$src_file" "$@"
        fi
        exit 0
    fi

    # ── Fetch latest release with infinite retry ──────
    local attempt=0 data tag=""
    while [ -z "$tag" ]; do
        start_spinner " ...ﻝﺎﺼﺗﻻﺍ ﻱﺭﺎﺟ" "$r1"
        data=$(curl -s --connect-timeout "$NET_TIMEOUT" \
            "https://api.github.com/repos/ma-dark404/MikroTik-HEX/releases/latest" 2>/dev/null || true)
        if [ -n "$data" ]; then
            tag=$(echo "$data" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"/\1/')
        fi
        if [ -n "$tag" ]; then
            stop_spinner true "ﻝﺎﺼﺗﻻﺍ ﻢﺗ"
            break
        fi
        stop_spinner false ""
        attempt=$((attempt+1))
        local s
        for ((s=RETRY_WAIT; s>0; s--)); do
            clr_line
            printf "  ${r1}${B}⟳${R}  ${W}ﺔﻜﺒﺸﻟﺍ ﺭﺎﻈﺘﻧﺍ${R}  ${Y1}${B}%2ds${R}  ${GR}#%d${R}" \
                "$s" "$attempt"
            sleep 1
        done
        clr_line
    done

    local dl_url="https://github.com/ma-dark404/MikroTik-HEX/releases/download/${tag}/${plat}"

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$dl_url")
    if [ "$http_code" != "200" ]; then
        st "✗" "$r1" "ﺩﻮﺟﻮﻣ ﺮﻴﻏ ﻒﻠﻤﻟﺍ" 0.5
        exit 1
    fi

    download_with_progress "$dl_url" "$plat"

    start_spinner "...ﻞﻴﻐﺸﺘﻟﺍ ﻱﺭﺎﺟ" "$G1"
    sleep 1.3
    stop_spinner true "ﻞﻴﻐﺸﺘﻟﺍ ﻢﺗ"

    if [[ "$plat" == hex_phantom_windows* ]]; then
        ./"$plat" "$@" &
    else
        chmod +x "$plat"
        ./"$plat" "$@"
    fi
}

main "$@"
