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
    local clean=$(echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g')
    echo ${#clean}
}

cpad() {
    local text="$1"
    local width=$(tw)
    local len=$(vlen "$text")
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
        local side=$(( ( $(tw) - BANNER_W ) / 2 ))
        [ $side -lt 0 ] && side=0
        printf "%${side}s${col}${B}${line}${R}\n" " "
    done
}

banner_pulse() {
    hide; clear_scr
    local pad_top=$(( ( $(th) - 15 ) / 2 ))
    [ $pad_top -lt 2 ] && pad_top=2
    local colors=("\e[38;5;52m" "\e[38;5;88m" "\e[38;5;124m" "\e[38;5;160m" "\e[38;5;196m")
    for c in "${colors[@]}"; do _draw_banner "$c" "$pad_top"; sleep 0.05; done
    _draw_banner "$r1" "$pad_top"
    local sep=$(printf '─%.0s' $(seq 1 $((BANNER_W + 6))))
    local side=$(( ( $(tw) - ${#sep} ) / 2 ))
    printf "\n%${side}s${GR}${sep}${R}\n" " "
}

# ── UI COMPONENTS ──────────────────────────────────────
info_box() {
    echo
    local m1="${r1}${B}✪${R} ${W}${B}HEX PHANTOM INSTALLER${R} ${r1}${B}✪${R}"
    cpad "$m1"; echo -e "$m1"
    local m2="${GR}... ﺭﺎﻈﺘﻧﻻﺍ ﺀﺎﺟﺮﻟﺍ${R}"
    cpad "$m1"; echo -e "$m2"
    echo
}

# ── SMART DOWNLOADER ───────────────────────────────────
download_smart() {
    local url="$1"
    local dest="$2"
    
    local total_size=$(curl -sIL "$url" | grep -i Content-Length | tail -n1 | awk '{print $2}' | tr -d '\r')
    [ -z "$total_size" ] && total_size=0

    echo -e "  ${G1}${B}✓${R}  ${W}${B}ﻝﺎﺼﺗﻻﺍ ﻢﺗ${R}"
    echo
    local l_msg="${Y1}⌛  ...ﻞﻴﻤﺤﺘﻟﺍ ﻱﺭﺎﺟ${R}"
    cpad "$l_msg"; echo -e "$l_msg"
    echo

    local start_t=$(date +%s%N)

    while true; do
        curl -L -s -C - -o "$dest" "$url" &
        local pid=$!

        while kill -0 $pid 2>/dev/null; do
            local cur_size=$(stat -c%s "$dest" 2>/dev/null || echo 0)
            local width=$(tw)
            local bar_w=$(( width - 50 ))
            [ $bar_w -lt 15 ] && bar_w=15

            if [ "$total_size" -gt 0 ]; then
                local pct=$(( cur_size * 100 / total_size ))
                local filled=$(( pct * bar_w / 100 ))
                local empty=$(( bar_w - filled ))
                
                local now=$(date +%s%N)
                local elapsed=$(( (now - start_t) / 1000000000 ))
                [ $elapsed -le 0 ] && elapsed=1
                local speed=$(( (cur_size / elapsed) / 1024 ))

                clr_line
                printf "  ${r1}▌${R}"
                [ $filled -gt 0 ] && printf "${r1}%0.s█${R}" $(seq 1 $filled)
                [ $empty -gt 0 ] && printf "${GR}%0.s░${R}" $(seq 1 $empty)
                printf "${r1}▐${R} ${r1}${B}%3d%%${R}  ${W}%sMB/%sMB${R}  ${C1}%sKB/s${R}" \
                       "$pct" "$((cur_size/1048576))" "$((total_size/1048576))" "$speed"
            else
                clr_line; printf "  ${r1}▌${R}${r1}▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒${R}${r1}▐${R} ${W}...ﻞﻴﻤﺤﺘﻟﺍ ﻱﺭﺎﺟ${R}"
            fi
            sleep 0.2
        done

        wait $pid
        local res=$?

        if [ $res -eq 0 ]; then
            break
        else
            clr_line
            printf "  ${r1}${B}⟳${R}  ${W}ﺔﻜﺒﺸﻟﺍ ﺭﺎﻈﺘﻧﺍ${R}"
            sleep 5
            clr_line
        fi
    done

    echo -e "\n"
    local ok_msg="  ✓  ﻞﻴﻤﺤﺘﻟﺍ ﻢﺗ  ✓  "
    for col in "$G1" "$W" "$G1" "$W" "$G1"; do
        clr_line; cpad "$ok_msg"; printf "${col}${B}${ok_msg}${R}"
        sleep 0.1
    done
    echo -e "\n"
}

# ── SYSTEM DETECTION ───────────────────────────────────
detect_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m | tr '[:upper:]' '[:lower:]')
    
    if [ -n "$PREFIX" ] || [ -d "/system/app" ]; then
        if [[ "$arch" == *"64"* ]] || [[ "$arch" == *"aarch64"* ]]; then
            echo "hex_phantom_android_arm64"
        else
            echo "hex_phantom_android_armv7"
        fi
    elif [[ "$os" == *"linux"* ]]; then
        if [[ "$arch" == *"x86_64"* ]] || [[ "$arch" == *"amd64"* ]]; then echo "HEX6_Linux_x64"
        elif [[ "$arch" == *"i686"* ]] || [[ "$arch" == *"i386"* ]]; then echo "HEX6_Linux_x86"
        elif [[ "$arch" == *"aarch64"* ]] || [[ "$arch" == *"arm64"* ]]; then echo "HEX6_Linux_ARM64"
        elif [[ "$arch" == *"armv7"* ]]; then echo "HEX6_Linux_ARMv7"
        else echo "HEX6_Linux_x86"; fi
    elif [[ "$os" == *"mingw"* ]] || [[ "$os" == *"msys"* ]]; then
        [[ "$arch" == *"64"* ]] && echo "HEX6_Windows_x64.exe" || echo "HEX6_Windows_x86.exe"
    fi
}

# ── MAIN ───────────────────────────────────────────────
main() {
    banner_pulse
    info_box

    printf "  ${C1}⣾${R}  ${W}Detecting Platform${GR} ...${R}"
    PLATFORM=$(detect_platform)
    clr_line

    if [ -z "$PLATFORM" ]; then
        echo -e "  ${r1}✗${R}  ${W}Unsupported System${R}"; exit 1
    fi

    # التحقق من وجود الملف في bin أولاً لتشغيله كأمر
    if command -v HEX-M &> /dev/null; then
         echo -e "  ${G1}${B}→${R}  ${W}...ﺮﺷﺎﺒﻣ ﻞﻴﻐﺸﺗ${R}"
         HEX-M "$@"
         exit 0
    fi

    local api_url="https://api.github.com/repos/ma-dark404/MikroTik-HEX/releases/latest"
    local data=""
    
    while [ -z "$data" ]; do
        data=$(curl -sL "$api_url")
        if [ $? -ne 0 ] || [[ "$data" != *"browser_download_url"* ]]; then
            data=""
            clr_line
            printf "  ${r1}${B}⟳${R}  ${W}ﺔﻜﺒﺸﻟﺍ ﺭﺎﻈﺘﻧﺍ${R}"
            sleep 5
            clr_line
        else
            break
        fi
    done

    local dl_url=$(echo "$data" | grep -oP "https://github.com/ma-dark404/MikroTik-HEX/releases/download/[^\"]+" | grep "$PLATFORM" | head -n1)

    if [ -z "$dl_url" ]; then
        echo -e "  ${r1}✗${R}  ${W}ﺩﻮﺟﻮﻣ ﺮﻴﻏ ﻒﻠﻤﻟﺍ${R}"
        exit 1
    fi

    download_smart "$dl_url" "$PLATFORM"

    
    chmod +x "$PLATFORM"
    mv "$PLATFORM" "$PREFIX/bin/HEX-M" 2>/dev/null
    chmod +x "$PREFIX/bin/HEX-M"

    # تشغيل الأداة
    HEX-M "$@"
}

main "$@"
