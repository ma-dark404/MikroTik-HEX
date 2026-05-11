#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os, sys, platform, subprocess, time, urllib.request, json, threading, re, signal

# ── ANSI ────────────────────────────────────────────────
R  = "\033[0m";  B = "\033[1m"
W  = "\033[97m"; GR = "\033[90m"
G1 = "\033[38;5;46m";  Y1 = "\033[93m"
C1 = "\033[38;5;51m";  r1 = "\033[38;5;196m"

if os.name == 'nt':
    try: import colorama; colorama.init()
    except: pass

def tw():
    try: return os.get_terminal_size().columns
    except: return 80
def th():
    try: return os.get_terminal_size().lines
    except: return 24
def hide(): sys.stdout.write("\033[?25l"); sys.stdout.flush()
def show(): sys.stdout.write("\033[?25h"); sys.stdout.flush()
def clear(): sys.stdout.write("\033[2J\033[H"); sys.stdout.flush()

# ── إعادة الرسم عند تغيير حجم الطرفية ──────────────────
_resize_flag = [False]

def _on_resize(sig, frame):
    """عند تغيير حجم الطرفية: نزل سطراً جديداً حتى لا تختلط السطور"""
    _resize_flag[0] = True
    sys.stdout.write("\n")
    sys.stdout.flush()

if hasattr(signal, 'SIGWINCH'):          # Linux/macOS فقط
    signal.signal(signal.SIGWINCH, _on_resize)

# ── مساعدات المحاذاة ────────────────────────────────────
_ANSI = re.compile(r'\033\[[0-9;]*m')

def vlen(s):
    """العرض المرئي الفعلي: بدون ANSI، والإيموجي بعرض 2"""
    clean = _ANSI.sub('', s)
    w = 0
    for ch in clean:
        cp = ord(ch)
        if (0x2300 <= cp <= 0x27BF) or (0x1F000 <= cp <= 0x1FFFF):
            w += 2
        else:
            w += 1
    return w

def cpad(s):
    return " " * max(0, (tw() - vlen(s)) // 2)

def clr_line():
    """مسح السطر الحالي بالكامل"""
    sys.stdout.write("\033[2K\r")
    sys.stdout.flush()

# ── شعار ASCII ─────────────────────────────────────────
BANNER = [
    "  ██╗  ██╗███████╗██╗  ██╗  ",
    "  ██║  ██║██╔════╝╚██╗██╔╝  ",
    "  ███████║█████╗   ╚███╔╝   ",
    "  ██╔══██║██╔══╝   ██╔██╗   ",
    "  ██║  ██║███████╗██╔╝ ██╗  ",
    "  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝  ",
]
BANNER_W = max(len(l) for l in BANNER)

PULSE_SEQ = [
    "\033[38;5;52m", "\033[38;5;88m",  "\033[38;5;124m",
    "\033[38;5;160m","\033[38;5;196m", "\033[38;5;203m",
    "\033[38;5;209m","\033[38;5;203m", "\033[38;5;196m",
    "\033[38;5;160m","\033[38;5;124m", "\033[38;5;88m",
    "\033[38;5;52m",
]

def _draw_banner(col, pad_top):
    sys.stdout.write("\033[H" + "\n" * pad_top)
    for line in BANNER:
        side = " " * max(0, (tw() - BANNER_W) // 2)
        sys.stdout.write(side + col + B + line + R + "\n")
    sys.stdout.flush()

def banner_pulse():
    hide(); clear()
    pad_top = max(2, (th() - len(BANNER) - 10) // 2)
    for col in PULSE_SEQ[:7]:
        _draw_banner(col, pad_top); time.sleep(0.055)
    for _ in range(3):
        for col in PULSE_SEQ:
            _draw_banner(col, pad_top); time.sleep(0.042)
    _draw_banner("\033[38;5;196m", pad_top)
    sep  = "─" * min(tw() - 4, BANNER_W + 6)
    side = " " * max(0, (tw() - len(sep)) // 2)
    sys.stdout.write("\n" + side + GR + sep + R + "\n")
    sys.stdout.flush(); show()

# ── صندوق المعلومات ──────────────────────────────────────
def info_box():
    print()
    msg1 = f"{r1}{B}✦{R} {W}{B}HEX RED PHANTOM INSTALLER{R} {r1}{B}✦{R}"
    sys.stdout.write(cpad(msg1) + msg1 + "\n"); sys.stdout.flush()
    time.sleep(0.05)
    msg2 = f"{GR}ﺭﺎﻈﺘﻧﻻﺍ ﻮﺟﺮﻤﻟﺍ ...{R}"
    sys.stdout.write(cpad(msg1) + msg2 + "\n"); sys.stdout.flush()
    print()

# ── صندوق انتظار ─────────────────────────────────────────
def waiting_box():
    inner = f"{Y1}⏳  ...ﻞﻴﻤﺤﺘﻟﺍ ﻱﺭﺎﺟ{R}"
    print()
    sys.stdout.write(cpad(inner) + inner + "\n"); sys.stdout.flush()
    print()

# ── Spinner ──────────────────────────────────────────────
class Spinner:
    _F = ["⣾","⣽","⣻","⢿","⡿","⣟","⣯","⣷"]

    def __init__(self, msg, col=C1):
        self.msg = msg; self.col = col
        self.on = False; self._t = None; self._i = 0

    def _run(self):
        hide()
        while self.on:
            f = self._F[self._i % len(self._F)]
            sys.stdout.write(f"\033[2K\r  {self.col}{B}{f}{R}  {W}{self.msg}{GR} ...{R}   ")
            sys.stdout.flush(); self._i += 1; time.sleep(0.08)
        clr_line(); show()

    def start(self):
        self.on = True
        self._t = threading.Thread(target=self._run, daemon=True)
        self._t.start()

    def stop(self, ok=True, msg=""):
        self.on = False
        if self._t: self._t.join(timeout=0.5)
        ic = f"{G1}{B}✓{R}" if ok else f"{r1}{B}✗{R}"
        if msg:
            sys.stdout.write(f"\033[2K\r  {ic}  {W}{msg}{R}\n")
            sys.stdout.flush()

# ── ثوابت التحميل ───────────────────────────────────────
RETRY_WAIT  = 5    # ثواني بين كل محاولة إعادة اتصال
NET_TIMEOUT = 20   # timeout لكل طلب HTTP بالثواني
BAR_COL     = "\033[38;5;196m"   # أحمر فقط

# ── تحميل مع شريط تقدم + استئناف + إعادة اتصال تلقائي ──
def download_with_progress(url, dest):

    def fz(b):
        if b < 1024:  return f"{b}B"
        if b < 1<<20: return f"{b/1024:.1f}KB"
        return f"{b/(1<<20):.1f}MB"

    def fs(s):
        if s <= 0:    return "───"
        if s < 1024:  return f"{s:.0f}B/s"
        if s < 1<<20: return f"{s/1024:.1f}KB/s"
        return f"{s/(1<<20):.2f}MB/s"

    t0             = [time.time()]
    spd            = []
    total_size     = [0]
    downloaded     = [os.path.getsize(dest) if os.path.exists(dest) else 0]
    supports_res   = [False]

    # ── رسم شريط التقدم ──
    def show_progress(dl, tot):
        # إذا تغيّرت الطرفية للتو، نحن بالفعل على سطر جديد
        if not _resize_flag[0]:
            clr_line()
        _resize_flag[0] = False

        cols   = tw()
        bw     = max(10, cols - 48)

        if tot <= 0:
            bar  = BAR_COL + "█" * bw + R
            line = (f"  {BAR_COL}▌{bar}{BAR_COL}▐{R}  "
                    f"{W}...ﻞﻴﻤﺤﺘﻟﺍ ﻱﺭﺎﺟ{R}  {C1}{fz(dl)}{R}")
            sys.stdout.write(line); sys.stdout.flush()
            return

        pct    = min(100, int(dl * 100 / tot))
        filled = int(bw * pct / 100)

        elapsed = max(0.001, time.time() - t0[0])
        spd.append(dl / elapsed)
        if len(spd) > 8: spd.pop(0)
        avg = sum(spd) / len(spd)

        # شريط أحمر صلب — بدون ترعيش
        bar = BAR_COL
        for i in range(bw):
            bar += "█" if i < filled else GR + "░"
        bar += R

        line = (
            f"  {BAR_COL}▌{bar}{BAR_COL}▐{R} "
            f"{BAR_COL}{B}{pct:3d}%{R}  "
            f"{W}{fz(dl)}{GR}/{W}{fz(tot)}{R}  "
            f"{C1}{fs(avg)}{R}"
        )
        sys.stdout.write(line); sys.stdout.flush()

    # ── عرض عداد إعادة الاتصال ──
    def show_reconnect(attempt, secs_left):
        if not _resize_flag[0]:
            clr_line()
        _resize_flag[0] = False
        dots = "·" * (secs_left % 4)
        line = (
            f"  {r1}{B}⟳{R}  {W}ﺔﻜﺒﺸﻟﺍ ﺭﺎﻈﺘﻧﺍ{R}  "
            f"{GR}ﺔﻴﻧﺎﺛ {Y1}{B}{secs_left:2d}{R}  "
            f"{GR}ﺔﻟﻭﺎﺤﻣ #{Y1}{attempt}{R}  {r1}{dots}{R}"
        )
        sys.stdout.write(line); sys.stdout.flush()

    # ── HEAD: الحجم الكلي ودعم الاستئناف ──
    def head_check():
        try:
            req = urllib.request.Request(url, method='HEAD')
            with urllib.request.urlopen(req, timeout=NET_TIMEOUT) as r:
                cl = r.getheader('Content-Length')
                if cl: total_size[0] = int(cl)
                supports_res[0] = (
                    r.getheader('Accept-Ranges', '').lower() == 'bytes'
                )
        except:
            pass

    # ── التحقق من ملف جزئي مسبق ──
    if downloaded[0] > 0:
        head_check()
        if not supports_res[0]:
            os.remove(dest); downloaded[0] = 0
    else:
        head_check()

    # اكتمل مسبقاً؟
    if total_size[0] > 0 and downloaded[0] >= total_size[0]:
        ok_msg = "  ✓  ﻞﻴﻤﺤﺘﻟﺍ ﻢﺗ  ✓  "
        for col in [G1, W, G1, W, G1]:
            pad = " " * max(0, (tw() - len(ok_msg)) // 2)
            sys.stdout.write(f"\033[2K\r{pad}{col}{B}{ok_msg}{R}")
            sys.stdout.flush(); time.sleep(0.13)
        print("\n"); return

    waiting_box()

    # ── حلقة التحميل مع إعادة الاتصال اللانهائية ──
    attempt = 0
    while True:
        try:
            mode = 'ab' if downloaded[0] > 0 else 'wb'
            req  = urllib.request.Request(url)
            if downloaded[0] > 0:
                req.add_header('Range', f'bytes={downloaded[0]}-')

            with urllib.request.urlopen(req, timeout=NET_TIMEOUT) as resp:

                if resp.status == 206:
                    cr = resp.getheader('Content-Range', '')
                    if cr:
                        parts = cr.split('/')
                        if len(parts) == 2 and parts[-1].isdigit():
                            total_size[0] = int(parts[-1])

                elif resp.status == 200:
                    # الخادم تجاهل Range → أعد من الصفر
                    if downloaded[0] > 0:
                        resp.close()
                        if os.path.exists(dest): os.remove(dest)
                        downloaded[0] = 0; mode = 'wb'
                        req2 = urllib.request.Request(url)
                        resp = urllib.request.urlopen(req2, timeout=NET_TIMEOUT)
                    cl = resp.getheader('Content-Length')
                    if cl: total_size[0] = int(cl)

                with open(dest, mode) as f:
                    while True:
                        chunk = resp.read(8192)
                        if not chunk: break
                        f.write(chunk); f.flush()
                        downloaded[0] += len(chunk)
                        show_progress(downloaded[0], total_size[0])

            break  # اكتمل

        except Exception:
            # ── انقطع الاتصال: عدّ تنازلي ثم إعادة المحاولة ──
            attempt += 1
            for s in range(RETRY_WAIT, 0, -1):
                show_reconnect(attempt, s)
                time.sleep(1)

            # فحص HEAD قبل المحاولة التالية
            head_check()
            if downloaded[0] > 0 and not supports_res[0]:
                if os.path.exists(dest): os.remove(dest)
                downloaded[0] = 0

    # ── رسالة الاكتمال ──
    ok_msg = "  ✓  ﻞﻴﻤﺤﺘﻟﺍ ﻢﺗ  ✓  "
    for col in [G1, W, G1, W, G1]:
        pad = " " * max(0, (tw() - len(ok_msg)) // 2)
        sys.stdout.write(f"\033[2K\r{pad}{col}{B}{ok_msg}{R}")
        sys.stdout.flush(); time.sleep(0.13)
    print("\n")

# ── حالة ────────────────────────────────────────────────
def st(icon, col, text, d=0.2):
    print(f"  {col}{B}{icon}{R}  {W}{text}{R}"); time.sleep(d)

# ── كشف النظام ──────────────────────────────────────────
def detect_platform():
    s = platform.system().lower(); m = platform.machine().lower()
    android = 'android' in platform.platform().lower() or hasattr(sys,'getandroidapilevel')
    if android:
        return 'hex_phantom_android_arm64' if ('64' in m or 'aarch64' in m) else 'hex_phantom_android_armv7'
    if s == 'windows':
        return 'hex_phantom_windows_x64.exe' if ('64' in m or 'amd64' in m) else 'hex_phantom_windows_x86.exe'
    if s == 'linux':
        if 'x86_64' in m or 'amd64'  in m: return 'hex_phantom_linux_x64'
        if 'aarch64' in m or 'arm64' in m: return 'hex_phantom_linux_arm64'
        if 'armv7'   in m:                 return 'hex_phantom_linux_armv7'
        return 'hex_phantom_linux_x86'
    return None

# ── main ─────────────────────────────────────────────────
def main():
    banner_pulse()
    info_box()

    sp = Spinner(" ", C1)
    sp.start(); time.sleep(1.0)
    plat = detect_platform()
    sp.stop(ok=False, msg="")
    if not plat: sys.exit(1)

    src = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'src', plat)
    if os.path.exists(src):
        st("→", G1, "...ﺮﺷﺎﺒﻣ ﻞﻴﻐﺸﺗ"); time.sleep(1)
        if plat.startswith('hex_phantom_windows'):
            subprocess.run([src] + sys.argv[1:], shell=True)
        else:
            os.chmod(src, 0o755); subprocess.run(['./' + src] + sys.argv[1:])
        sys.exit(0)

    # ── الاتصال بالمخدم مع إعادة محاولة لانهائية ──
    attempt = 0
    data    = None
    while data is None:
        sp2 = Spinner(" ...ﻝﺎﺼﺗﻻﺍ ﻱﺭﺎﺟ", r1)
        sp2.start()
        try:
            with urllib.request.urlopen(
                "https://api.github.com/repos/ma-dark404/MikroTik-HEX/releases/latest",
                timeout=NET_TIMEOUT
            ) as resp:
                data = json.loads(resp.read().decode())
            sp2.stop(ok=True, msg="ﻝﺎﺼﺗﻻﺍ ﻢﺗ")
        except Exception:
            sp2.stop(ok=False, msg="")
            attempt += 1
            for s in range(RETRY_WAIT, 0, -1):
                sys.stdout.write(
                    f"\033[2K\r  {r1}{B}⟳{R}  {W}ﺔﻜﺒﺸﻟﺍ ﺭﺎﻈﺘﻧﺍ{R}  "
                    f"{Y1}{B}{s:2d}s{R}  {GR}#{attempt}{R}"
                )
                sys.stdout.flush(); time.sleep(1)
            clr_line()

    dl_url = next(
        (a['browser_download_url'] for a in data.get('assets', []) if a['name'] == plat),
        None
    )
    if not dl_url:
        st("✗", r1, "ﺩﻮﺟﻮﻣ ﺮﻴﻏ ﻒﻠﻤﻟﺍ"); sys.exit(1)

    download_with_progress(dl_url, plat)

    sp3 = Spinner("...ﻞﻴﻐﺸﺘﻟﺍ ﻱﺭﺎﺟ", G1)
    sp3.start(); time.sleep(1.3)
    sp3.stop(ok=True, msg="ﻞﻴﻐﺸﺘﻟﺍ ﻢﺗ")
    if plat.startswith('hex_phantom_windows'):
        subprocess.run([plat] + sys.argv[1:], shell=True)
    else:
        os.chmod(plat, 0o755); subprocess.run(['./' + plat] + sys.argv[1:])

if __name__ == "__main__":
    main()
