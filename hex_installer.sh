#!/bin/bash

# ── ANSI COLORS ────────────────────────────────────────
R="\e[0m";  B="\e[1m"
W="\e[97m"; GR="\e[90m"
G1="\e[38;5;46m"; Y1="\e[93m"
C1="\e[38;5;51m"; r1="\e[38;5;196m"

# ── TERMINAL UTILS ─────────────────────────────────────
tw() { tput cols || echo 80; }
th() { tput lines || echo 24; }
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
    local width=$(tw)
    local pad=$(( (width - len) / 2 ))
    [ $pad -lt 0 ] && pad=0
    printf "%${pad}s" " "
}

# ── ASCII BANNER ───────────────────────────────────────
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
        [ $side_pad -lt 0 ] && side_pad=0
        printf "%${side_pad}s${col}${B}${line}${R}\n" " "
    done
}

banner_pulse() {
    hide; clear_scr
    local pad_top=$(( ( $(th) - 15 ) / 2 ))
    [ $pad_top -lt 2 ] && pad_top=2
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

# ── DETECT PLATFORM (محاكاة دقيقة لبايثون) ───────────────
detect_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m | tr '[:upper:]' '[:lower:]')
    
    # كشف أندرويد
    if [ -n "$PREFIX" ] || [ -d "/system/app" ] || command -v getprop &>/dev/null; then
        if [[ "$arch" == *"64"* ]] || [[ "$arch" == *"aarch64"* ]]; then
            echo "hex_phantom_android_arm64"
        else
            echo "hex_phantom_android_armv7"
        fi
        return
    fi

    # كشف ويندوز (Cygwin/Msys)
    if [[ "$os" == *"mingw"* ]] || [[ "$os" == *"msys"* ]] || [[ "$os" == *"cygwin"* ]]; then
        if [[ "$arch" == *"64"* ]] || [[ "$arch" == *"amd64"* ]]; then
            echo "hex_phantom_windows_x64.exe"
        else
            echo "hex_phantom_windows_x86.exe"
        fi
        return
    fi

    # كشف لينكس
    if [[ "$os" == *"linux"* ]]; then
        if [[ "$arch" == *"x86_64"* ]] || [[ "$arch" == *"amd64"* ]]; then
            echo "hex_phantom_linux_x64"
        elif [[ "$arch" == *"aarch64"* ]] || [[ "$arch" == *"arm64"* ]]; then
            echo "hex_phantom_linux_arm64"
        elif [[ "$arch" == *"armv7"* ]]; then
            echo "hex_phantom_linux_armv7"
        else
            echo "hex_phantom_linux_x86"
        fi
        return
    fi
}

# ── DOWNLOAD WITH PROGRESS BAR ─────────────────────────
download_with_bar() {
    local url="$1"
    local dest="$2"
    
    echo -e "  ${G1}✓${R}  ${W}${B}ﻝﺎﺼﺗﻻﺍ ﻢﺗ${R}"
    echo
    local loading_msg="${Y1}⌛  ...ﻞﻴﻤﺤﺘﻟﺍ ﻱﺭﺎﺟ${R}"
    cpad "...ﻞﻴﻤﺤﺘﻟﺍ ﻱﺭﺎﺟ"; echo -e "$loading_msg"
    echo

    # محاكاة شريط التقدم باستخدام curl
    curl -L -# -o "$dest" "$url" 2>&1 | while read -r line; do
        # تحويل مخرجات curl إلى تنسيق مخصص (اختياري، هنا نستخدم الافتراضي الجميل لـ curl -#)
        # ولكن لجعلها تطابق الصورة، سنستخدم معالجة يدوية بسيطة
        :
    done
    
    # بعد اكتمال التحميل، نظهر رسالة النجاح بتنسيق بايثون
    local ok_msg="  ✓  ﻞﻴﻤﺤﺘﻟﺍ ﻢﺗ  ✓  "
    for col in "$G1" "$W" "$G1" "$W" "$G1"; do
        clr_line
        cpad "  ✓  ﻞﻴﻤﺤﺘﻟﺍ ﻢﺗ  ✓  "; printf "${col}${B}${ok_msg}${R}"
        sleep 0.1
    done
    echo -e "\n"
}

# ── SPINNER ────────────────────────────────────────────
SPIN_PID=""
start_spinner() {
    local msg="$1"
    hide
    (
        local frames=("⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷")
        while true; do
            for f in "${frames[@]}"; do
                printf "\e[2K\r  ${C1}${B}${f}${R}  ${W}${msg}${GR} ...${R}"
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

# ── MAIN ───────────────────────────────────────────────
main() {
    banner_pulse
    info_box

    start_spinner " "
    sleep 0.5
    PLATFORM=$(detect_platform)
    stop_spinner

    if [ -z "$PLATFORM" ]; then
        echo -e "  ${r1}✗${R}  ${W}Unsupported System${R}"; exit 1
    fi

    # التحقق من الملف محلياً في مجلد src
    if [ -f "./src/$PLATFORM" ]; then
        echo -e "  ${G1}→${R}  ${W}...ﺮﺷﺎﺒﻣ ﻞﻴﻐﺸﺗ${R}"
        sleep 1
        chmod +x "./src/$PLATFORM"
        "./src/$PLATFORM" "$@"
        exit 0
    fi

    # الاتصال بـ GitHub
    local data=""
    local attempt=0
    while [ -z "$data" ]; do
        start_spinner " ...ﻝﺎﺼﺗﻻﺍ ﻱﺭﺎﺟ" 
        data=$(curl -sL --connect-timeout 10 "https://api.github.com/repos/ma-dark404/MikroTik-HEX/releases/latest")
        if [ $? -eq 0 ] && [[ "$data" == *"browser_download_url"* ]]; then
            stop_spinner
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

    # استخراج الرابط بدقة (تجاوز مشكلة grep)
    DL_URL=$(echo "$data" | grep -o "https://[^\" ]*${PLATFORM}")

    if [ -z "$DL_URL" ]; then
        # محاولة ثانية ببحث أوسع عن الاسم
        DL_URL=$(echo "$data" | grep -o '"browser_download_url": "[^"]*' | grep "$PLATFORM" | cut -d'"' -f4)
    fi

    if [ -z "$DL_URL" ]; then
        echo -e "  ${r1}✗${R}  ${W}ﺩﻮﺟﻮﻣ ﺮﻴﻏ ﻒﻠﻤﻟﺍ${R}"
        echo -e "  ${GR}Platform detected as: ${W}$PLATFORM${R}"
        exit 1
    fi

    download_with_bar "$DL_URL" "$PLATFORM"

    chmod +x "$PLATFORM"
    ./"$PLATFORM" "$@"
}

main "$@"
