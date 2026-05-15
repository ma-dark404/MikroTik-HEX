```markdown
<div align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/7/7d/MikroTik_logo.svg" width="80" height="80" alt="MikroTik">
  <h1>🥷 HEX PHANTOM 🥷</h1>
  <h3>إطار عمل احترافي لاختبار أمان هوتسبوت المايكروتك</h3>
  <a href="https://t.me/GoToHEX">
    <img src="https://img.shields.io/badge/Telegram-القناة-blue?style=for-the-badge&logo=telegram" alt="Telegram">
  </a>
  <a href="https://github.com/ma-dark404/MikroTik-HEX">
    <img src="https://img.shields.io/badge/GitHub-المستودع-black?style=for-the-badge&logo=github" alt="GitHub">
  </a>
  <p>
    <img src="https://img.shields.io/badge/الإصدار-v2.0.0-red?style=for-the-badge" alt="version">
    <img src="https://img.shields.io/badge/المنصات-Windows%20%7C%20Linux%20%7C%20Android-blue?style=for-the-badge" alt="platform">
    <img src="https://img.shields.io/badge/الترخيص-MIT-green?style=for-the-badge" alt="license">
  </p>
</div>

---

## 📖 **عن الأداة**
**HEX PHANTOM** هي أداة أتمتة للهجوم بالقوة العمياء (Brute-Force) على توثيق هوتسبوت مايكروتك. صممت لمتخصصي الأمن واختبار الاختراق.

---

## ✨ **الميزات**
- ⚡ **هجوم فائق السرعة** متعدد الخيوط (Multi-threading)
- 🧠 **اكتشاف تلقائي** لراوترات المايكروتك على الشبكة
- 💻 **ملف تنفيذي ذاتي** - لا يحتاج إلى بايثون أو مكتبات إضافية
- 📁 **حفظ واستئناف** جلسات الهجوم
- 🌍 **دعم ثنائي اللغة** (العربية / English)

---

## 🖥️ **الأنظمة المدعومة**

| المنصة | المعمارية | الملف التنفيذي |
|--------|-----------|----------------|
| <img src="https://upload.wikimedia.org/wikipedia/commons/3/35/Tux.svg" width="18" height="18"> Linux | x64 | `hex_phantom_linux_x64` |
| <img src="https://upload.wikimedia.org/wikipedia/commons/c/c4/Raspberry_Pi_Logo.svg" width="18" height="18"> Raspberry Pi 4/5 | ARM64 | `hex_phantom_linux_arm64` |
| <img src="https://upload.wikimedia.org/wikipedia/commons/c/c4/Raspberry_Pi_Logo.svg" width="18" height="18"> Raspberry Pi 2/3 | ARMv7 | `hex_phantom_linux_armv7` |
| <img src="https://upload.wikimedia.org/wikipedia/commons/d/db/Termux_logo.svg" width="18" height="18"> Android (Termux) | ARM64 | `hex_phantom_android_arm64` |
| <img src="https://upload.wikimedia.org/wikipedia/commons/8/87/Windows_logo_-_2021.svg" width="18" height="18"> Windows 10/11 | x64 | `hex_phantom_windows_x64.exe` |
| <img src="https://upload.wikimedia.org/wikipedia/commons/8/87/Windows_logo_-_2021.svg" width="18" height="18"> Windows 7/8 | x86 | `hex_phantom_windows_x86.exe` |

---

## 🚀 **التثبيت والتشغيل**

### <img src="https://upload.wikimedia.org/wikipedia/commons/3/35/Tux.svg" width="18" height="18"> **لينكس (Debian/Ubuntu)**
```bash
sudo apt update -y && sudo apt install git -y && \
git clone https://github.com/ma-dark404/MikroTik-HEX && \
cd MikroTik-HEX && \
chmod +x hex_installer.sh && \
sudo bash hex_installer.sh -y
```

<img src="https://upload.wikimedia.org/wikipedia/commons/d/db/Termux_logo.svg" width="18" height="18"> أندرويد (Termux)

```bash
pkg install git -y && \
git clone https://github.com/ma-dark404/MikroTik-HEX && \
cd MikroTik-HEX && \
chmod +x hex_installer.sh && \
bash hex_installer.sh -y
```

<img src="https://upload.wikimedia.org/wikipedia/commons/8/87/Windows_logo_-_2021.svg" width="18" height="18"> ويندوز (تشغيل كمسؤول في CMD)

```cmd
git clone https://github.com/ma-dark404/MikroTik-HEX && cd MikroTik-HEX && hex_phantom_windows_x64.exe
```

---

⚡ التشغيل السريع

بعد التثبيت، يمكنك تشغيل الأداة في أي وقت باستخدام الأمر:

```bash
HEX-M
```

---

📄 الترخيص

رخصة MIT - للاستخدام التعليمي واختبار الاختراق فقط.

---

<div align="center">
  <p>تم التطوير بواسطة 🥷 <a href="https://github.com/ma-dark404">ma-dark404</a></p>
</div>
```
