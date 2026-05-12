#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# ── ANSI ────────────────────────────────────────────────
R="\033[0m";  B="\033[1m"
W="\033[97m"; GR="\033[90m"
G1="\033[38;5;46m";  Y1="\033[93m"
C1="\033[38;5;51m";  r1="\033[38;5;196m"

# ── إعادة الرسم عند تغيير حجم الطرفية ──────────────────
_RESIZE_FLAG=0

_on_resize() {
    # عند تغيير حجم الطرفية: نزل سطراً جديداً حتى لا تختلط السطور
    _RESIZE_FLAG=1
    printf "\n"
}

trap '_on_resize' WINCH 2>/dev/null

tw() { tput cols 2>/dev/null || echo 80; }
th() { tput lines 2>/dev/null || echo 24; }
hide() { printf "\033[?25l"; }
show() { printf "\033[?25h"; }
clear_screen() { printf "\033[2J\033[H"; }

# ── مساعدات المحاذاة ────────────────────────────────────
# _ANSI pattern equivalent handled via sed

vlen() {
    # العرض المرئي الفعلي: بدون ANSI، والإيموجي بعرض 2
    local s="$1"
    local clean
    clean=$(printf '%s' "$s" | sed 's/\x1b\[[0-9;]*m//g')
    local w=0
    local i
    local len=${#clean}
    for ((i=0; i<len; i++)); do
        local ch="${clean:$i:1}"
        local cp
        cp=$(printf '%d' "'$ch" 2>/dev/null || echo 0)
        if { [ "$cp" -ge 8960 ] && [ "$cp" -le 10175 ]; } || \
           { [ "$cp" -ge 126976 ] && [ "$cp" -le 131071 ]; }; then
            w=$((w + 2))
        else
            w=$((w + 1))
        fi
    done
    echo "$w"
}

cpad() {
    local s="$1"
    local vl
    vl=$(vlen "$s")
    local cols
    cols=$(tw)
    local pad=$(( (cols - vl) / 2 ))
    [ "$pad" -lt 0 ] && pad=0
    printf '%*s' "$pad" ''
}

clr_line() {
    # مسح السطر الحالي بالكامل
    printf "\033[2K\r"
}

# ── شعار ASCII ─────────────────────────────────────────
BANNER=(
    "  ██╗  ██╗███████╗██╗  ██╗  "
    "  ██║  ██║██╔════╝╚██╗██╔╝  "
    "  ███████║█████╗   ╚███╔╝   "
    "  ██╔══██║██╔══╝   ██╔██╗   "
    "  ██║  ██║███████╗██╔╝ ██╗  "
    "  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝  "
)
BANNER_W=30

PULSE_SEQ=(
    "\033[38;5;52m"  "\033[38;5;88m"  "\033[38;5;124m"
    "\033[38;5;160m" "\033[38;5;196m" "\033[38;5;203m"
    "\033[38;5;209m" "\033[38;5;203m" "\033[38;5;196m"
    "\033[38;5;160m" "\033[38;5;124m" "\033[38;5;88m"
    "\033[38;5;52m"
)

_draw_banner() {
    local col="$1"
    local pad_top="$2"
    printf "\033[H"
    local i
    for ((i=0; i<pad_top; i++)); do printf "\n"; done
    local cols
    cols=$(tw)
    for line in "${BANNER[@]}"; do
        local side_w=$(( (cols - BANNER_W) / 2 ))
        [ "$side_w" -lt 0 ] && side_w=0
        local side
        side=$(printf '%*s' "$side_w" '')
        printf "%s%s%s%s%s\n" "$side" "$col" "$B" "$line" "$R"
    done
}

banner_pulse() {
    hide
    clear_screen
    local banner_len=${#BANNER[@]}
    local lines
    lines=$(th)
    local pad_top=$(( (lines - banner_len - 10) / 2 ))
    [ "$pad_top" -lt 2 ] && pad_top=2

    local i
    for ((i=0; i<7; i++)); do
        _draw_banner "${PULSE_SEQ[$i]}" "$pad_top"
        sleep 0.055
    done

    local round
    for ((round=0; round<3; round++)); do
        local col
        for col in "${PULSE_SEQ[@]}"; do
            _draw_banner "$col" "$pad_top"
            sleep 0.042
        done
    done

    _draw_banner "\033[38;5;196m" "$pad_top"

    local cols
    cols=$(tw)
    local sep_len=$(( cols - 4 ))
    local max_sep=$(( BANNER_W + 6 ))
    [ "$sep_len" -gt "$max_sep" ] && sep_len="$max_sep"
    local sep=""
    local j
    for ((j=0; j<sep_len; j++)); do sep+="─"; done
    local side_w=$(( (cols - sep_len) / 2 ))
    [ "$side_w" -lt 0 ] && side_w=0
    local side
    side=$(printf '%*s' "$side_w" '')
    printf "\n%s%s%s%s\n" "$side" "$GR" "$sep" "$R"
    show
}

# ── صندوق المعلومات ──────────────────────────────────────
info_box() {
    printf "\n"
    local msg1="${r1}${B}✦${R} ${W}${B}HEX RED PHANTOM INSTALLER${R} ${r1}${B}✦${R}"
    local pad
    pad=$(cpad "$msg1")
    printf "%s%s\n" "$pad" "$msg1"
    sleep 0.05
    local msg2="${GR}ﺭﺎﻈﺘﻧﻻﺍ ﻮﺟﺮﻤﻟﺍ ...${R}"
    printf "%s%s\n" "$pad" "$msg2"
    printf "\n"
}

# ── صندوق انتظار ─────────────────────────────────────────
waiting_box() {
    local inner="${Y1}⏳  ...ﻞﻴﻤﺤﺘﻟﺍ ﻱﺭﺎﺟ${R}"
    printf "\n"
    local pad
    pad=$(cpad "$inner")
    printf "%s%s\n" "$pad" "$inner"
    printf "\n"
}

# ── Spinner ──────────────────────────────────────────────
SPINNER_FRAMES=("⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷")
SPINNER_PID=0

_spinner_run() {
    local msg="$1"
    local col="$2"
    local i=0
    local nf=${#SPINNER_FRAMES[@]}
    hide
    while true; do
        local f="${SPINNER_FRAMES[$((i % nf))]}"
        printf "\033[2K\r  %s%s%s%s  %s%s%s ...%s   " \
            "$col" "$B" "$f" "$R" \
            "$W" "$msg" "$GR" "$R"
        i=$((i + 1))
        sleep 0.08
    done
}

spinner_start() {
    local msg="$1"
    local col="${2:-$C1}"
    _spinner_run "$msg" "$col" &
    SPINNER_PID=$!
}

spinner_stop() {
    local ok="${1:-1}"
    local msg="${2:-}"
    if [ "$SPINNER_PID" -ne 0 ]; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null
        SPINNER_PID=0
    fi
    clr_line
    show
    local ic
    if [ "$ok" -eq 1 ]; then
        ic="${G1}${B}✓${R}"
    else
        ic="${r1}${B}✗${R}"
    fi
    if [ -n "$msg" ]; then
        printf "\033[2K\r  %s  %s%s%s\n" "$ic" "$W" "$msg" "$R"
    fi
}

# ── ثوابت التحميل ───────────────────────────────────────
RETRY_WAIT=5    # ثواني بين كل محاولة إعادة اتصال
NET_TIMEOUT=20  # timeout لكل طلب HTTP بالثواني
BAR_COL="\033[38;5;196m"   # أحمر فقط

# ── تنسيق الحجم ──
fz() {
    local b=$1
    if [ "$b" -lt 1024 ]; then
        printf "%dB" "$b"
    elif [ "$b" -lt 1048576 ]; then
        awk "BEGIN{printf \"%.1fKB\", $b/1024}"
    else
        awk "BEGIN{printf \"%.1fMB\", $b/1048576}"
    fi
}

# ── تنسيق السرعة ──
fs() {
    local s=$1
    if [ -z "$s" ] || [ "$s" -le 0 ] 2>/dev/null; then
        printf "───"
        return
    fi
    if [ "$s" -lt 1024 ]; then
        printf "%.0fB/s" "$s"
    elif [ "$s" -lt 1048576 ]; then
        awk "BEGIN{printf \"%.1fKB/s\", $s/1024}"
    else
        awk "BEGIN{printf \"%.2fMB/s\", $s/1048576}"
    fi
}

# ── رسم شريط التقدم ──
show_progress() {
    local dl=$1
    local tot=$2
    local t0=$3

    if [ "$_RESIZE_FLAG" -ne 0 ]; then
        _RESIZE_FLAG=0
    else
        clr_line
    fi
    _RESIZE_FLAG=0

    local cols
    cols=$(tw)
    local bw=$(( cols - 48 ))
    [ "$bw" -lt 10 ] && bw=10

    if [ "$tot" -le 0 ]; then
        local bar="${BAR_COL}"
        local k
        for ((k=0; k<bw; k++)); do bar+="█"; done
        bar+="$R"
        printf "  %s▌%s%s▐%s  %s...ﻞﻴﻤﺤﺘﻟﺍ ﻱﺭﺎﺟ%s  %s%s%s" \
            "$BAR_COL" "$bar" "$BAR_COL" "$R" \
            "$W" "$R" \
            "$C1" "$(fz "$dl")" "$R"
        return
    fi

    local pct=$(( dl * 100 / tot ))
    [ "$pct" -gt 100 ] && pct=100
    local filled=$(( bw * pct / 100 ))

    local now
    now=$(date +%s)
    local elapsed=$(( now - t0 ))
    [ "$elapsed" -le 0 ] && elapsed=1
    local avg=$(( dl / elapsed ))

    # شريط أحمر صلب — بدون ترعيش
    local bar="${BAR_COL}"
    local k
    for ((k=0; k<bw; k++)); do
        if [ "$k" -lt "$filled" ]; then
            bar+="█"
        else
            bar+="${GR}░"
        fi
    done
    bar+="$R"

    printf "  %s▌%s%s▐%s %s%s%3d%%%s  %s%s%s/%s%s%s  %s%s%s" \
        "$BAR_COL" "$bar" "$BAR_COL" "$R" \
        "$BAR_COL" "$B" "$pct" "$R" \
        "$W" "$(fz "$dl")" "$GR" "$W" "$(fz "$tot")" "$R" \
        "$C1" "$(fs "$avg")" "$R"
}

# ── عرض عداد إعادة الاتصال ──
show_reconnect() {
    local attempt=$1
    local secs_left=$2

    if [ "$_RESIZE_FLAG" -ne 0 ]; then
        _RESIZE_FLAG=0
    else
        clr_line
    fi
    _RESIZE_FLAG=0

    local dots_count=$(( secs_left % 4 ))
    local dots=""
    local d
    for ((d=0; d<dots_count; d++)); do dots+="·"; done

    printf "  %s%s⟳%s  %sﺔﻜﺒﺸﻟﺍ ﺭﺎﻈﺘﻧﺍ%s  %sﺔﻴﻧﺎﺛ %s%s%2d%s  %sﺔﻟﻭﺎﺤﻣ #%s%s%s  %s%s%s" \
        "$r1" "$B" "$R" \
        "$W" "$R" \
        "$GR" "$Y1" "$B" "$secs_left" "$R" \
        "$GR" "$Y1" "$attempt" "$R" \
        "$r1" "$dots" "$R"
}

# ── HEAD: الحجم الكلي ودعم الاستئناف ──
_head_total_size=0
_head_supports_res=0

head_check() {
    local url="$1"
    local headers
    headers=$(curl -sI --max-time "$NET_TIMEOUT" "$url" 2>/dev/null)

    local content_length
    content_length=$(printf '%s' "$headers" | grep -i '^Content-Length:' | awk '{print $2}' | tr -d '\r\n')

    local accept_ranges
    accept_ranges=$(printf '%s' "$headers" | grep -i '^Accept-Ranges:' | awk '{print $2}' | tr -d '\r\n' | tr '[:upper:]' '[:lower:]')

    _head_total_size="${content_length:-0}"
    if [ "$accept_ranges" = "bytes" ]; then
        _head_supports_res=1
    else
        _head_supports_res=0
    fi
}

# ── تحميل مع شريط تقدم + استئناف + إعادة اتصال تلقائي ──
download_with_progress() {
    local url="$1"
    local dest="$2"

    local total_size=0
    local downloaded=0
    local supports_res=0

    # ── التحقق من ملف جزئي مسبق ──
    if [ -f "$dest" ]; then
        downloaded=$(stat -c%s "$dest" 2>/dev/null || stat -f%z "$dest" 2>/dev/null || echo 0)
    fi

    head_check "$url"
    total_size="$_head_total_size"
    supports_res="$_head_supports_res"

    if [ "$downloaded" -gt 0 ] && [ "$supports_res" -eq 0 ]; then
        rm -f "$dest"
        downloaded=0
    fi

    # اكتمل مسبقاً؟
    if [ "$total_size" -gt 0 ] && [ "$downloaded" -ge "$total_size" ]; then
        local ok_msg="  ✓  ﻞﻴﻤﺤﺘﻟﺍ ﻢﺗ  ✓  "
        local cols
        cols=$(tw)
        local pad_w=$(( (cols - ${#ok_msg}) / 2 ))
        [ "$pad_w" -lt 0 ] && pad_w=0
        local pad
        pad=$(printf '%*s' "$pad_w" '')
        local col
        for col in "$G1" "$W" "$G1" "$W" "$G1"; do
            printf "\033[2K\r%s%s%s%s%s" "$pad" "$col" "$B" "$ok_msg" "$R"
            sleep 0.13
        done
        printf "\n\n"
        return
    fi

    waiting_box

    local t0
    t0=$(date +%s)

    # ── حلقة التحميل مع إعادة الاتصال اللانهائية ──
    local attempt=0
    while true; do
        if [ "$downloaded" -gt 0 ] && [ "$supports_res" -eq 1 ]; then
            curl -s --max-time 0 --connect-timeout "$NET_TIMEOUT" \
                -C "$downloaded" \
                -o "$dest" \
                "$url" &
        else
            curl -s --max-time 0 --connect-timeout "$NET_TIMEOUT" \
                -o "$dest" \
                "$url" &
        fi
        local curl_pid=$!

        # مراقبة التقدم
        while kill -0 "$curl_pid" 2>/dev/null; do
            local current_size=0
            if [ -f "$dest" ]; then
                current_size=$(stat -c%s "$dest" 2>/dev/null || stat -f%z "$dest" 2>/dev/null || echo 0)
            fi
            show_progress "$current_size" "$total_size" "$t0"
            sleep 0.1
        done

        wait "$curl_pid"
        local curl_exit=$?

        if [ "$curl_exit" -eq 0 ]; then
            break  # اكتمل
        fi

        # ── انقطع الاتصال: عدّ تنازلي ثم إعادة المحاولة ──
        attempt=$((attempt + 1))
        local s
        for ((s=RETRY_WAIT; s>0; s--)); do
            show_reconnect "$attempt" "$s"
            sleep 1
        done

        # فحص HEAD قبل المحاولة التالية
        head_check "$url"
        total_size="$_head_total_size"
        supports_res="$_head_supports_res"

        if [ -f "$dest" ]; then
            downloaded=$(stat -c%s "$dest" 2>/dev/null || stat -f%z "$dest" 2>/dev/null || echo 0)
        fi

        if [ "$downloaded" -gt 0 ] && [ "$supports_res" -eq 0 ]; then
            [ -f "$dest" ] && rm -f "$dest"
            downloaded=0
        fi
    done

    # ── رسالة الاكتمال ──
    local ok_msg="  ✓  ﻞﻴﻤﺤﺘﻟﺍ ﻢﺗ  ✓  "
    local cols
    cols=$(tw)
    local pad_w=$(( (cols - ${#ok_msg}) / 2 ))
    [ "$pad_w" -lt 0 ] && pad_w=0
    local pad
    pad=$(printf '%*s' "$pad_w" '')
    local col
    for col in "$G1" "$W" "$G1" "$W" "$G1"; do
        printf "\033[2K\r%s%s%s%s%s" "$pad" "$col" "$B" "$ok_msg" "$R"
        sleep 0.13
    done
    printf "\n\n"
}

# ── حالة ────────────────────────────────────────────────
st() {
    local icon="$1"
    local col="$2"
    local text="$3"
    local d="${4:-0.2}"
    printf "  %s%s%s%s  %s%s%s\n" "$col" "$B" "$icon" "$R" "$W" "$text" "$R"
    sleep "$d"
}

# ── كشف النظام ──────────────────────────────────────────
detect_platform() {
    local s
    s=$(uname -s | tr '[:upper:]' '[:lower:]')
    local m
    m=$(uname -m | tr '[:upper:]' '[:lower:]')

    local android=0
    if [ -f /system/build.prop ] || \
       { command -v getprop &>/dev/null && [ -n "$(getprop ro.build.version.release 2>/dev/null)" ]; }; then
        android=1
    fi

    if [ "$android" -eq 1 ]; then
        case "$m" in
            *64*|*aarch64*) echo "hex_phantom_android_arm64" ;;
            *)              echo "hex_phantom_android_armv7" ;;
        esac
        return
    fi

    case "$s" in
        linux)
            case "$m" in
                x86_64|amd64)        echo "hex_phantom_linux_x64" ;;
                aarch64|arm64)       echo "hex_phantom_linux_arm64" ;;
                armv7*)              echo "hex_phantom_linux_armv7" ;;
                *)                   echo "hex_phantom_linux_x86" ;;
            esac
            ;;
        *)
            echo ""
            ;;
    esac
}

# ── main ─────────────────────────────────────────────────
main() {
    banner_pulse
    info_box

    spinner_start " " "$C1"
    sleep 1.0
    local plat
    plat=$(detect_platform)
    spinner_stop 0 ""

    if [ -z "$plat" ]; then
        exit 1
    fi

    local script_dir
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    local src="${script_dir}/src/${plat}"

    if [ -f "$src" ]; then
        st "→" "$G1" "...ﺮﺷﺎﺒﻣ ﻞﻴﻐﺸﺗ"
        sleep 1
        chmod 755 "$src"
        "./$src" "$@"
        exit 0
    fi

    # ── الاتصال بالمخدم مع إعادة محاولة لانهائية ──
    local attempt=0
    local data=""
    while [ -z "$data" ]; do
        spinner_start " ...ﻝﺎﺼﺗﻻﺍ ﻱﺭﺎﺟ" "$r1"
        local resp
        resp=$(curl -s --max-time "$NET_TIMEOUT" \
            "https://api.github.com/repos/ma-dark404/MikroTik-HEX/releases/latest" 2>/dev/null)
        local curl_exit=$?
        spinner_stop 0 ""

        if [ "$curl_exit" -eq 0 ] && [ -n "$resp" ]; then
            data="$resp"
            clr_line
            printf "  %s%s✓%s  %sﻝﺎﺼﺗﻻﺍ ﻢﺗ%s\n" "$G1" "$B" "$R" "$W" "$R"
        else
            attempt=$((attempt + 1))
            local s
            for ((s=RETRY_WAIT; s>0; s--)); do
                printf "\033[2K\r  %s%s⟳%s  %sﺔﻜﺒﺸﻟﺍ ﺭﺎﻈﺘﻧﺍ%s  %s%s%2ds%s  %s#%d%s" \
                    "$r1" "$B" "$R" \
                    "$W" "$R" \
                    "$Y1" "$B" "$s" "$R" \
                    "$GR" "$attempt" "$R"
                sleep 1
            done
            clr_line
        fi
    done

    local dl_url=""
    if command -v jq &>/dev/null; then
        dl_url=$(printf '%s' "$data" | \
            jq -r --arg p "$plat" '.assets[] | select(.name == $p) | .browser_download_url' 2>/dev/null | head -1)
    fi

    if [ -z "$dl_url" ] && command -v python3 &>/dev/null; then
        dl_url=$(printf '%s' "$data" | python3 -c "
import sys, json
data = json.load(sys.stdin)
plat = '$plat'
for a in data.get('assets', []):
    if a['name'] == plat:
        print(a['browser_download_url'])
        break
" 2>/dev/null)
    fi

    if [ -z "$dl_url" ]; then
        dl_url=$(printf '%s' "$data" | \
            grep -o '"browser_download_url":"[^"]*'"$plat"'"' | \
            head -1 | sed 's/"browser_download_url":"//;s/"//')
    fi

    if [ -z "$dl_url" ]; then
        st "✗" "$r1" "ﺩﻮﺟﻮﻣ ﺮﻴﻏ ﻒﻠﻤﻟﺍ"
        exit 1
    fi

    download_with_progress "$dl_url" "$plat"

    spinner_start "...ﻞﻴﻐﺸﺘﻟﺍ ﻱﺭﺎﺟ" "$G1"
    sleep 1.3
    spinner_stop 1 "ﻞﻴﻐﺸﺘﻟﺍ ﻢﺗ"

    chmod 755 "$plat"
    "./$plat" "$@"
}

main "$@"

