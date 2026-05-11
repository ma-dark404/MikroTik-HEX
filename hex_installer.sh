#!/usr/bin/env bash
set -e

# ── الألوان ────────────────────────────────────────────────
R='\033[0m';    B='\033[1m'
W='\033[97m';   GR='\033[90m'
G1='\033[38;5;46m';  Y1='\033[93m'
C1='\033[38;5;51m';  r1='\033[38;5;196m'

# ─ـ الشعار (ASCII) ─────────────────────────────────────────
BANNER=(
"  ██╗  ██╗███████╗██╗  ██╗  "
"  ██║  ██║██╔════╝╚██╗██╔╝  "
"  ███████║█████╗   ╚███╔╝   "
"  ██╔══██║██╔══╝   ██╔██╗   "
"  ██║  ██║███████╗██╔╝ ██╗  "
"  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝  "
)

# ─ـ اكتشاف النظام ──────────────────────────────────────────
detect_platform() {
    local os arch
    os=$(uname -s)
    arch=$(uname -m)

    # Android/Termux detection
    if [ -n "$PREFIX" ] && [[ "$PREFIX" == *com.termux* ]] || uname -o 2>/dev/null | grep -qi android; then
        case "$arch" in
            aarch64|arm64)  echo "hex_phantom_android_arm64" ;;
            *)              echo "hex_phantom_android_armv7" ;;
        esac
        return
    fi

    case "$os" in
        Linux)
            case "$arch" in
                x86_64|amd64)   echo "hex_phantom_linux_x64" ;;
                aarch64|arm64)  echo "hex_phantom_linux_arm64" ;;
                armv7l)         echo "hex_phantom_linux_armv7" ;;
                *)              echo "hex_phantom_linux_x86" ;;
            esac
            ;;
        Darwin)
            # macOS – نستخدم نسخة لينكس x64 مؤقتاً (قد تضطر لبناء نسخة خاصة)
            echo "hex_phantom_linux_x64"
            ;;
        *)
            echo ""
            ;;
    esac
}

# ─ـ تحميل الملف ────────────────────────────────────────────
download_and_run() {
    local file="$1"
    local url="https://github.com/ma-dark404/MikroTik-HEX/releases/latest/download/$file"
    local retries=10 delay=5

    echo -e "  ${C1}→${R} ${W}ﻞﻴﻤﺤﺗ ${file}...${R}"

    # حلقة إعادة المحاولة
    for ((i=1; i<=retries; i++)); do
        echo -e "  ${GR}ﺔﻟﻭﺎﺤﻣ[ $i/$retries]${R}"
        # curl -# يظهر شريط تقدم ═══════
        curl -# -L -o "$file" "$url" && break
        if [ $i -eq $retries ]; then
            echo -e "  ${r1}✗${R} ${W}ﺕﻻﻭﺎﺤﻣ ﺓﺪﻋ ﺪﻌﺑ ﻞﻴﻤﺤﺘﻟﺍ ﻞﺸﻓ${R}"
            exit 1
        fi
        echo -e "  ${Y1}⟳${R} ${W}ﺪﻌﺑ ﺔﻟﻭﺎﺤﻤﻟﺍ ﺓﺩﺎﻋﺇ ${delay} ...ٍﻥﺍﻮﺛ${R}"
        sleep $delay
    done

    echo -e "  ${G1}✓${R} ${W}ﺡﺎﺠﻨﺑ ﻞﻴﻤﺤﺘﻟﺍ ﻢﺗ${R}"
    chmod +x "$file"
    echo -e "  ${G1}▶${R} ${W}...ﻞﻴﻐﺸﺗ${R}\n"
    ./"$file" "$@"
    exit 0
}

# ─ـ الواجهة الرئيسية ──────────────────────────────────────
main() {
    # تنظيف الشاشة وعرض الشعار
    clear
    local i col pad
    for i in "${!BANNER[@]}"; do
        col='\033[38;5;196m'   # أحمر ثابت للشعار
        pad=$(( ( $(tput cols) - 43 ) / 2 ))
        [ $pad -lt 0 ] && pad=0
        printf "%${pad}s" ""
        echo -e "${col}${B}${BANNER[$i]}${R}"
    done

    # خط فاصل
    local sep_len=$(( $(tput cols) - 4 ))
    [ $sep_len -lt 10 ] && sep_len=43
    pad=$(( ( $(tput cols) - sep_len ) / 2 ))
    [ $pad -lt 0 ] && pad=0
    printf "%${pad}s" ""
    echo -e "${GR}$(printf '─%.0s' $(seq 1 $sep_len))${R}"

    echo ""
    # صف المعلومات
    local info="✪ HEX PHANTOM INSTALLER ✪"
    pad=$(( ( $(tput cols) - ${#info} ) / 2 ))
    [ $pad -lt 0 ] && pad=0
    printf "%${pad}s" ""
    echo -e "${r1}${B}✦${R} ${W}${B}HEX PHANTOM INSTALLER${R} ${r1}${B}✦${R}"

    local sub="...ﺭﺎﻈﺘﻧﻻﺍ ﻮﺟﺮﻤﻟﺍ"
    pad=$(( ( $(tput cols) - ${#sub} ) / 2 ))
    [ $pad -lt 0 ] && pad=0
    printf "%${pad}s" ""
    echo -e "${GR}${sub}${R}"
    echo ""

    # كشف النظام
    local plat
    plat=$(detect_platform)
    if [ -z "$plat" ]; then
        echo -e "  ${r1}✗${R} ${W}ًﺎﻴﻟﺎﺣ ﻡﻮﻋﺪﻣ ﺮﻴﻏ ﻞﻴﻐﺸﺘﻟﺍ ﻡﺎﻈﻧ.${R}"
        exit 1
    fi
    echo -e "  ${C1}→${R} ${W}:ﻑﺎﺸﺘﻛﺍ ﻢﺗ ${B}$plat${R}"

    # تحميل مباشر
    download_and_run "$plat" "$@"
}

# ─ـ بدء البرنامج ──────────────────────────────────────────
main "$@"
