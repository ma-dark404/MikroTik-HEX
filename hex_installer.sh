#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# HEX RED PHANTOM Installer – Bash version (منقول حرفيّاً بدون حذف)
set -euo pipefail

# ── ANSI color and style definitions ───────────────────────────────
R="\033[0m";    B="\033[1m"
W="\033[97m";   GR="\033[90m"
G1="\033[38;5;46m";  Y1="\033[93m"
C1="\033[38;5;51m";  r1="\033[38;5;196m"
BAR_COL="\033[38;5;196m"

# ── Terminal size ──────────────────────────────────────────────────
tcols() { tput cols 2>/dev/null || echo 80; }
tlines(){ tput lines 2>/dev/null || echo 24; }

# ── Cursor and screen control ──────────────────────────────────────
hide_cursor()  { printf "\033[?25l"; }
show_cursor()  { printf "\033[?25h"; }
clear_screen() { printf "\033[2J\033[H"; }
clrline()      { printf "\033[2K\r"; }

# ── Visual length of a string (strips ANSI, emoji width=2) ─────────
# (تستخدم للتموضع، هنا نكتفي بالطول الفعلي لأن النصوص كلها ASCII + عربية معكوسة بدون ANSI في دالة التوسيط)
vlen() {
    local s="$1" clean len=0 ch cp
    clean=$(printf "%s" "$s" | sed -E 's/\x1b\[[0-9;]*m//g')
    while IFS= read -r -n1 ch; do
        [ -z "$ch" ] && continue
        cp=$(printf "%d" "'$ch")
        if ( [ "$cp" -ge 0x2300 ] && [ "$cp" -le 0x27BF ] ) || \
           ( [ "$cp" -ge 0x1F000 ] && [ "$cp" -le 0x1FFFF ] ); then
            len=$((len+2))
        else
            len=$((len+1))
        fi
    done <<< "$clean"
    echo "$len"
}

# مركز نص (دون ANSI)
center() {
    local msg="$1"
    local cols=$(tcols)
    local pad=$(( (cols - $(vlen "$msg")) / 2 ))
    [ $pad -lt 0 ] && pad=0
    printf "%*s" $pad ""
    printf "%s" "$msg"
}

# ── إعادة الرسم عند تغيير حجم الطرفية ─────────────────────────────
resize_flag=0
on_resize() {
    resize_flag=1
    printf "\n"   # سطر جديد حتى لا تختلط السطور
}
trap on_resize SIGWINCH 2>/dev/null || true

# ── شعار ASCII ─────────────────────────────────────────────────────
BANNER=(
    "  ██╗  ██╗███████╗██╗  ██╗   "
    "  ██║  ██║██╔════╝╚██╗██╔╝  "
    "  ███████║█████╗   ╚███╔╝    "    
    "  ██╔══██║██╔══╝   ██╔██╗    "
    "  ██║  ██║███████╗██╔╝ ██╗  "
    "  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝  "

)
BANNER_W=33   # أقصى عرض

PULSE_SEQ=(
  "\033[38;5;52m"  "\033[38;5;88m"  "\033[38;5;124m"
  "\033[38;5;160m" "\033[38;5;196m" "\033[38;5;203m"
  "\033[38;5;209m" "\033[38;5;203m" "\033[38;5;196m"
  "\033[38;5;160m" "\033[38;5;124m" "\033[38;5;88m"
  "\033[38;5;52m"
)

draw_banner() {
    local col="$1" pad_top="$2"
    printf "\033[H"
    local i; for ((i=0;i<$pad_top;i++)); do printf "\n"; done
    local cols=$(tcols)
    local side=$(( (cols - BANNER_W) / 2 ))
    [ $side -lt 0 ] && side=0
    local spc=$(printf "%*s" $side "")
    for line in "${BANNER[@]}"; do
        printf "%s%b%b%s%b\n" "$spc" "$col" "$B" "$line" "$R"
    done
}

banner_pulse() {
    hide_cursor; clear_screen
    local pad_top=$(( ( $(tlines) - ${#BANNER[@]} - 10 ) / 2 ))
    [ $pad_top -lt 2 ] && pad_top=2

    local i col
    for ((i=0;i<7;i++)); do
        draw_banner "${PULSE_SEQ[$i]}" $pad_top
        sleep 0.055
    done
    for i in {1..3}; do
        for col in "${PULSE_SEQ[@]}"; do
            draw_banner "$col" $pad_top
            sleep 0.042
        done
    done
    draw_banner "\033[38;5;196m" $pad_top

    # سطر فاصل
    local sep=""; local c
    for ((c=0;c<BANNER_W+6;c++)); do sep+="─"; done
    local side2=$(( ($(tcols) - ${#sep}) / 2 ))
    [ $side2 -lt 0 ] && side2=0
    printf "\n%*s%b%s%b\n" $side2 "" "$GR" "$sep" "$R"
    show_cursor
}

# ── صندوق المعلومات ────────────────────────────────────────────────
info_box() {
    printf "\n"
    local msg1="${r1}${B}✦${R} ${W}${B}HEX PHANTOM INSTALLER${R} ${r1}${B}✦${R}"
    printf "%b\n" "$(center "$msg1")$msg1"
    sleep 0.05
    local msg2="${GR}ﺭﺎﻈﺘﻧﻻﺍ ﻮﺟﺮﻤﻟﺍ ...${R}"
    printf "%b\n" "$(center "$msg2")$msg2"
    printf "\n"
}

# ── صندوق انتظار ───────────────────────────────────────────────────
waiting_box() {
    printf "\n"
    local inner="${Y1}⏳  ...ﻞﻴﻤﺤﺘﻟﺍ ﻱﺭﺎﺟ${R}"
    printf "%b\n" "$(center "$inner")$inner"
    printf "\n"
}

# ── Spinner ────────────────────────────────────────────────────────
SPIN_FRAMES=("⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷")
spinner_running=false
spinner_pid=""

start_spinner() {
    local msg="$1" col="${2:-$C1}"
    spinner_running=true
    (
        hide_cursor
        local i=0
        while $spinner_running; do
            local frame="${SPIN_FRAMES[$((i % 8))]}"
            printf "\033[2K\r  %b%b%s%b  %b%s%b %b...%b   " \
                   "$col" "$B" "$frame" "$R" "$W" "$msg" "$GR" "$R"
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

# ── حالة (status line) ─────────────────────────────────────────────
status_line() {
    local icon="$1" col="$2" text="$3" delay="${4:-0.2}"
    printf "  %b%b%s%b  %b%s%b\n" "$col" "$B" "$icon" "$R" "$W" "$text" "$R"
    sleep "$delay"
}

# ── كشف النظام (مطابق تماماً للمنطق في Python) ─────────────────────
detect_platform() {
    local sys=$(uname -s | tr '[:upper:]' '[:lower:]')
    local mach=$(uname -m | tr '[:upper:]' '[:lower:]')
    local android=false

    if [ "${ANDROID_ROOT:-}" != "" ] || echo "$sys" | grep -qi android; then
        android=true
    fi

    if $android; then
        case "$mach" in
            aarch64|arm64|armv8*) echo "hex_phantom_android_arm64" ;;
            *)                     echo "hex_phantom_android_armv7" ;;
        esac
    elif [[ "$sys" =~ (mingw|cygwin|msys|windows) ]]; then
        if [[ "$mach" =~ (64|amd64) ]]; then echo "hex_phantom_windows_x64.exe"
        else echo "hex_phantom_windows_x86.exe"; fi
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

# ── دوال تنسيق الحجم والسرعة (مثل Python) ──────────────────────────
format_size() {
    local b=$1
    if [ $b -lt 1024 ]; then
        echo "${b}B"
    elif [ $b -lt $((1024*1024)) ]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $b/1024}")KB"
    else
        echo "$(awk "BEGIN {printf \"%.1f\", $b/(1024*1024)}")MB"
    fi
}

format_speed() {
    local s=$1
    if [ $s -le 0 ]; then echo "───"
    elif [ $s -lt 1024 ]; then echo "${s}B/s"
    elif [ $s -lt $((1024*1024)) ]; then echo "$(awk "BEGIN {printf \"%.1f\", $s/1024}")KB/s"
    else echo "$(awk "BEGIN {printf \"%.2f\", $s/(1024*1024)}")MB/s"
    fi
}

# ── شريط التقدم المخصص (مطابق لبايثون) ─────────────────────────────
draw_progress_bar() {
    local dl=$1 tot=$2 speed=$3
    # إذا حدث تغيير في حجم الطرفية، ننزل سطراً جديداً
    if [ $resize_flag -eq 1 ]; then
        printf "\n"
        resize_flag=0
    fi
    clrline

    local cols=$(tcols)
    local bar_width=$((cols - 48))
    [ $bar_width -lt 10 ] && bar_width=10

    if [ $tot -le 0 ]; then
        # لا نعرف الحجم الكلي
        local bar_fill=""; local c
        for ((c=0;c<$bar_width;c++)); do bar_fill+="█"; done
        printf "  %b▌%b%s%b▐%b  %b...ﻞﻴﻤﺤﺘﻟﺍ ﻱﺭﺎﺟ%b  %b%s%b" \
               "$BAR_COL" "$BAR_COL" "$bar_fill" "$BAR_COL" "$R" \
               "$W" "$R" "$C1" "$(format_size $dl)" "$R"
        return
    fi

    local pct=$(( dl * 100 / tot ))
    [ $pct -gt 100 ] && pct=100
    local filled=$(( bar_width * pct / 100 ))
    local bar=""
    local i
    for ((i=0;i<$bar_width;i++)); do
        if [ $i -lt $filled ]; then bar+="█"
        else bar+="${GR}░"; fi
    done
    bar+="$R"

    printf "  %b▌%b%s%b▐%b %b%b%3d%%%b  %b%s%b/%b%s%b  %b%s%b" \
           "$BAR_COL" "$BAR_COL" "$bar" "$BAR_COL" "$R" \
           "$BAR_COL" "$B" "$pct" "$R" \
           "$W" "$(format_size $dl)" "$GR" "$W" "$(format_size $tot)" "$R" \
           "$C1" "$(format_speed $speed)" "$R"
}

# ─ـ تحميل الملف مع شريط تقدم واستئناف وإعادة اتصال (مطابق للنسخة الأصلية) ─
NET_TIMEOUT=20
RETRY_WAIT=5

download_with_progress() {
    local url="$1" dest="$2"

    # دوال داخلية مساعدة
    head_check() {
        # يعيد: total_size (bytes) و supports_resume (true/false)
        local headers
        headers=$(curl -sI --connect-timeout $NET_TIMEOUT "$url" 2>/dev/null || true)
        if [ -z "$headers" ]; then
            echo "0 false"
            return
        fi
        local cl=$(echo "$headers" | grep -i '^Content-Length:' | tail -1 | awk '{print $2}' | tr -d '\r')
        local ar=$(echo "$headers" | grep -i '^Accept-Ranges:' | tail -1 | tr -d '\r')
        local tot=0 resume=false
        if [ -n "$cl" ]; then tot=$cl; fi
        if echo "$ar" | grep -qi 'bytes'; then resume=true; fi
        echo "$tot $resume"
    }

    show_reconnect() {
        local attempt="$1" secs_left="$2"
        if [ $resize_flag -eq 1 ]; then
            printf "\n"
            resize_flag=0
        fi
        clrline
        local dots=""
        local i
        for ((i=0;i<secs_left%4;i++)); do dots+="·"; done
        printf "  %b%b⟳%b  %bﺔﻜﺒﺸﻟﺍ ﺭﺎﻈﺘﻧﺍ%b  %bﺔﻴﻧﺎﺛ %b%b%2d%b  %bﺔﻟﻭﺎﺤﻣ #%b%d%b  %b%s%b" \
               "$r1" "$B" "$R" "$W" "$R" "$Y1" "$B" "$secs_left" "$R" \
               "$GR" "$Y1" "$attempt" "$R" "$r1" "$dots" "$R"
    }

    # المرحلة الأولى: فحص HEAD
    local total_size=0 supports_resume=false
    local head_out
    head_out=$(head_check)
    read total_size supports_resume <<< "$head_out"

    local downloaded=0
    [ -f "$dest" ] && downloaded=$(stat -c%s "$dest" 2>/dev/null || echo 0)

    # إذا يوجد ملف جزئي لكن الخادم لا يدعم الاستئناف، نحذف الملف
    if [ $downloaded -gt 0 ] && ! $supports_resume; then
        rm -f "$dest"
        downloaded=0
    fi

    # إذا اكتمل الملف مسبقاً
    if [ $total_size -gt 0 ] && [ $downloaded -ge $total_size ]; then
        local ok_msg="  ✓  ﻞﻴﻤﺤﺘﻟﺍ ﻢﺗ  ✓  "
        local col
        for col in "$G1" "$W" "$G1" "$W" "$G1"; do
            clrline
            local pad=$(center "$ok_msg")
            printf "%s%b%b%s%b" "$pad" "$col" "$B" "$ok_msg" "$R"
            sleep 0.13
        done
        printf "\n\n"
        return
    fi

    waiting_box

    # حلقة التحميل مع إعادة الاتصال اللانهائية
    local attempt=0
    while true; do
        # فحص HEAD قبل كل محاولة لإعادة الاتصال
        head_out=$(head_check)
        read total_size supports_resume <<< "$head_out"
        if [ $downloaded -gt 0 ] && ! $supports_resume; then
            rm -f "$dest"
            downloaded=0
        fi

        # بدء عملية التحميل في الخلفية
        local resume_flag=""
        [ $downloaded -gt 0 ] && resume_flag="-C -"

        # نستخدم curl مع إخراج صامت، وسنراقب حجم الملف
        curl -L -s -S --connect-timeout $NET_TIMEOUT $resume_flag \
             -o "$dest" "$url" &
        local curl_pid=$!

        local start_time=$SECONDS
        local last_dl=0
        while kill -0 $curl_pid 2>/dev/null; do
            if [ -f "$dest" ]; then
                downloaded=$(stat -c%s "$dest" 2>/dev/null || echo 0)
            fi
            local elapsed=$((SECONDS - start_time))
            [ $elapsed -eq 0 ] && elapsed=1
            local speed=$((downloaded / elapsed))
            draw_progress_bar $downloaded $total_size $speed
            sleep 0.1
        done
        wait $curl_pid
        local rc=$?

        # قراءة الحجم النهائي
        [ -f "$dest" ] && downloaded=$(stat -c%s "$dest" 2>/dev/null || echo 0)

        if [ $rc -eq 0 ]; then
            # نجاح
            local elapsed_final=$((SECONDS - start_time))
            [ $elapsed_final -eq 0 ] && elapsed_final=1
            local final_speed=$((downloaded / elapsed_final))
            draw_progress_bar $downloaded $total_size $final_speed
            break
        fi

        # فشل: عداد إعادة الاتصال
        attempt=$((attempt+1))
        local s
        for ((s=RETRY_WAIT; s>0; s--)); do
            show_reconnect $attempt $s
            sleep 1
        done
        # إعادة فحص الرؤوس في بداية الحلقة التالية
    done

    # رسالة الاكتمال
    local ok_msg="  ✓  ﻞﻴﻤﺤﺘﻟﺍ ﻢﺗ  ✓  "
    local col
    for col in "$G1" "$W" "$G1" "$W" "$G1"; do
        clrline
        local pad=$(center "$ok_msg")
        printf "%s%b%b%s%b" "$pad" "$col" "$B" "$ok_msg" "$R"
        sleep 0.13
    done
    printf "\n\n"
}

# ── main ────────────────────────────────────────────────────────────
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
        echo "Unsupported platform"; exit 1
    fi

    local src_dir
    src_dir="$(dirname "$(readlink -f "$0")")/src"
    local local_path="$src_dir/$plat"

    # إذا الملف موجود محلياً نشغله مباشرة
    if [ -f "$local_path" ]; then
        status_line "→" "$G1" "...ﺮﺷﺎﺒﻣ ﻞﻴﻐﺸﺗ" 1
        if [[ "$plat" == hex_phantom_windows* ]]; then
            "$local_path" "$@"   # قد لا يعمل في WSL لكنه مطابق للأصل
        else
            chmod +x "$local_path"
            "$local_path" "$@"
        fi
        exit 0
    fi

    # وإلا نحمّل من GitHub
    local attempt=0 data tag
    while true; do
        start_spinner " ...ﻝﺎﺼﺗﻻﺍ ﻱﺭﺎﺟ" "$r1"
        data=$(curl -s --connect-timeout $NET_TIMEOUT \
                "https://api.github.com/repos/ma-dark404/MikroTik-HEX/releases/latest") || true
        if [ -n "$data" ]; then
            tag=$(echo "$data" | grep -Po '"tag_name": *"\K[^"]+') || true
            if [ -n "$tag" ]; then
                stop_spinner true "ﻝﺎﺼﺗﻻﺍ ﻢﺗ"
                break
            fi
        fi
        stop_spinner false ""
        attempt=$((attempt+1))
        local s
        for ((s=RETRY_WAIT; s>0; s--)); do
            clrline
            printf "  %b%b⟳%b  %bﺔﻜﺒﺸﻟﺍ ﺭﺎﻈﺘﻧﺍ%b  %b%b%2ds%b  %b#%d%b" \
                   "$r1" "$B" "$R" "$W" "$R" "$Y1" "$B" "$s" "$R" "$GR" "$attempt" "$R"
            sleep 1
        done
        clrline
    done

    local dl_url="https://github.com/ma-dark404/MikroTik-HEX/releases/download/${tag}/${plat}"

    # تحقق من أن الملف موجود في الإصدارة
    local check_url
    check_url=$(curl -s -o /dev/null -w "%{http_code}" "$dl_url" || echo 404)
    if [ "$check_url" != "200" ]; then
        status_line "✗" "$r1" "ﺩﻮﺟﻮﻣ ﺮﻴﻏ ﻒﻠﻤﻟﺍ" 0.5
        exit 1
    fi

    download_with_progress "$dl_url" "$plat"

    status_line "✓" "$G1" "ﻞﻴﻐﺸﺘﻟﺍ ﻢﺗ" 0.3
    if [[ "$plat" == hex_phantom_windows* ]]; then
        ./"$plat" "$@"
    else
        chmod +x "$plat"
        ./"$plat" "$@"
    fi
}

main "$@"
