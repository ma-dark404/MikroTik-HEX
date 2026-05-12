#!/bin/bash

# ── ANSI COLORS ────────────────────────────────────────
R="\e[0m";  B="\e[1m"
W="\e[97m"; GR="\e[90m"
G1="\e[38;5;46m"; Y1="\e[93m"
C1="\e[38;5;51m"; r1="\e[38;5;196m"

# ── TERMINAL UTILS ─────────────────────────────────────
tw() { tput cols; }
th() { tput lines; }
hide() { printf "\e[?25l"; }
show() { printf "\e[?25h"; }
clear_scr() { printf "\e[2J\e[H"; }
clr_line() { printf "\e[2K\r"; }

vlen() {
    local str=$(echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g')
    echo ${#str}
}

cpad() {
    local text="$1"
    local len=$(vlen "$text")
    local pad=$(( ( $(tw) - len ) / 2 ))
    [ $pad -lt 0 ] && pad=0
    printf "%${pad}s" " "
}

# ── ASCII BANNER (HEX) ─────────────────────────────────
BANNER=(
    "  ██╗  ██╗███████╗██╗  ██╗  "
    "  ██║  ██║██╔════╝╚██╗██╔╝  "
    "  ███████║█████╗   ╚███╔╝   "
    "  ██╔══██║██╔══╝   ██╔██╗   "
    "  ██║  ██║███████╗██╔╝ ██╗  "
    "  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝  "
)
BANNER_W=28

_draw_banner() {
    local col="$1"
    local pad_top="$2"
    printf "\e[H"
    for ((i=0; i<pad_top; i++)); do echo; done
    for line in "${BANNER[@]}"; do
        local side_pad=$(( ( $(tw) - BANNER_W ) / 2 ))
        printf "%${side_pad}s${col}${B}${line}${R}\n" " "
    done
}

banner_pulse() {
    hide; clear_scr
    local pad_top=$(( ( $(th) - 15 ) / 2 ))
    [ $pad_top -lt 2 ] && pad_top=2
    
    # تحريك الألوان (Pulse)
    local colors=("\e[38;5;52m" "\e[38;5;88m" "\e[38;5;124m" "\e[38;5;160m" "\e[38;5;196m")
    for c in "${colors[@]}"; do _draw_banner "$c" "$pad_top"; sleep 0.05; done
    _draw_banner "$r1" "$pad_top"
    
    local sep=$(printf '─%.0s' $(seq 1 $((BANNER_W + 4))))
    local side=$(( ( $(tw) - ${#sep} ) / 2 ))
    printf "\n%${side}s${GR}${sep}${R}\n" " "
}

# ── UI COMPONENTS ──────────────────────────────────────
info_box() {
    echo
    local m1="${r1}${B}✦${R} ${W}${B}HEX RED PHANTOM INSTALLER${R} ${r1}${B}✦${R}"
    cpad "✦ HEX RED PHANTOM INSTALLER ✦"; echo -e "$m1"
    local m2="${GR}ﺭﺎﻈﺘﻧﻻﺍ ﻮﺟﺮﻤﻟﺍ ...${R}"
    cpad "ﺭﺎﻈﺘﻧﻻﺍ ﻮﺟﺮﻤﻟﺍ ..."; echo -e "$m2"
    echo
}

# ── CUSTOM PROGRESS BAR (تطابق الصورة) ────────────────
download_with_bar() {
    local url="$1"
    local dest="$2"
    
    # "تم الاتصال"
    echo -e "  ${G1}✓${R}  ${W}${B}ﻝﺎﺼﺗﻻﺍ ﻢﺗ${R}"
    echo
    
    # "جاري التحميل"
    local loading_msg="${Y1}⌛  ...ﻞﻴﻤﺤﺘﻟﺍ ﻱﺭﺎﺟ${R}"
    cpad "...ﻞﻴﻤﺤﺘﻟﺍ ﻱﺭﺎﺟ"; echo -e "$loading_msg"
    echo

    # الحصول على حجم الملف
    local total_size=$(curl -sI "$url" | grep -i Content-Length | awk '{print $2}' | tr -d '\r')
    [ -z "$total_size" ] && total_size=0

    # بدء التحميل في الخلفية
    curl -L -s -o "$dest" "$url" &
    local pid=$!
    local start_time=$(date +%s)

    while kill -0 $pid 2>/dev/null; do
        local current_size=$(stat -c%s "$dest" 2>/dev/null || echo 0)
        local cols=$(tw)
        local bar_width=$(( cols - 50 ))
        [ $bar_width -lt 10 ] && bar_width=10

        if [ "$total_size" -gt 0 ]; then
            local percent=$(( current_size * 100 / total_size ))
            local filled=$(( percent * bar_width / 100 ))
            local empty=$(( bar_width - filled ))
            
            # حساب السرعة
            local now=$(date +%s)
            local elapsed=$(( now - start_time ))
            [ $elapsed -le 0 ] && elapsed=1
            local speed=$(( current_size / elapsed / 1024 )) # KB/s
            
            # تحويل الأحجام لـ MB
            local cur_mb=$(echo "scale=1; $current_size/1048576" | bc)
            local tot_mb=$(echo "scale=1; $total_size/1048576" | bc)

            # رسم الشريط كما في الصورة
            clr_line
            printf " ${r1}│${R}" # الحافة اليسرى الحمراء
            printf "${r1}$(printf '█%.0s' $(seq 1 $filled))${R}" # الجزء الممتلئ
            printf "${GR}$(printf '░%.0s' $(seq 1 $empty))${R}" # الجزء الفارغ
            printf "${r1}│${R}" # الحافة اليمنى الحمراء
            
            # النسبة والمعلومات
            printf " ${r1}${B}${percent}%%${R}  ${W}${cur_mb}MB/${tot_mb}MB${R}  ${C1}${speed}KB/s${R}"
        fi
        sleep 0.1
    done

    wait $pid
    echo -e "\n\n"
    cpad "  ✓  ﻞﻴﻤﺤﺘﻟﺍ ﻢﺗ  ✓  "; echo -e "${G1}${B}  ✓  ﻞﻴﻤﺤﺘﻟﺍ ﻢﺗ  ✓  ${R}\n"
}

# ── SPINNER ───────────────────────────────────────────
SPIN_PID=""
start_spinner() {
    hide
    (
        local frames=("⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷")
        while true; do
            for f in "${frames[@]}"; do
                printf "\e[2K\r  ${C1}${B}${f}${R}  ${W}$1${GR} ...${R}"
                sleep 0.08
            done
        done
    ) &
    SPIN_PID=$!
}

stop_spinner() {
    [ -n "$SPIN_PID" ] && kill $SPIN_PID 2>/dev/null && wait $SPIN_PID 2>/dev/null
    clr_line
    show
}

# ── DETECT PLATFORM ───────────────────────────────────
detect_platform() {
    local arch=$(uname -m)
    if [[ "$PREFIX" == *"/com.termux/"* ]]; then
        [[ "$arch" == "aarch64" ]] && echo "hex_phantom_android_arm64" || echo "hex_phantom_android_armv7"
    else
        [[ "$arch" == "x86_64" ]] && echo "hex_phantom_linux_x64" || echo "hex_phantom_linux_x86"
    fi
}

# ── MAIN ──────────────────────────────────────────────
main() {
    banner_pulse
    info_box

    start_spinner " "
    sleep 1
    PLATFORM=$(detect_platform)
    stop_spinner

    # الاتصال بـ GitHub
    local data=""
    local attempt=0
    while [ -z "$data" ]; do
        start_spinner " ...ﻝﺎﺼﺗﻻﺍ ﻱﺭﺎﺟ" 
        data=$(curl -s --connect-timeout 10 "https://api.github.com/repos/ma-dark404/MikroTik-HEX/releases/latest")
        if [ $? -eq 0 ] && [[ "$data" == *"browser_download_url"* ]]; then
            stop_spinner
            # ملاحظة: "تم الاتصال" تظهر داخل وظيفة download_with_bar
        else
            stop_spinner
            ((attempt++))
            for s in {5..1}; do
                printf "\e[2K\r  ${r1}${B}⟳${R}  ${W}ﺔﻜﺒﺸﻟﺍ ﺭﺎﻈﺘﻧﺍ${R}  ${Y1}${B}${s}s${R}  ${GR}#${attempt}${R}"
                sleep 1
            done
            data=""
        fi
    done

    DL_URL=$(echo "$data" | grep -oP '"browser_download_url":\s*"\K[^"]+' | grep "$PLATFORM")
    
    if [ -z "$DL_URL" ]; then
        echo -e "  ${r1}✗${R}  ${W}ﺩﻮﺟﻮﻣ ﺮﻴﻏ ﻒﻠﻤﻟﺍ${R}"; exit 1
    fi

    download_with_bar "$DL_URL" "$PLATFORM"

    chmod +x "$PLATFORM"
    ./"$PLATFORM" "$@"
}

main "$@"
