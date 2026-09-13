# ============================================================
#  Setup Walled-Garden Reminder Tagihan (SEKALI JALAN)
#  Web-proxy bawaan RouterOS untuk redirect HTTP user
#  yang masuk address-list "tagihan-reminder" ke halaman
#  pengingat tagihan di GitHub Pages.
#
#  Target : RouterOS 7.24.2 (x86)
#  Tanpa container. Semua fitur bawaan.
#
#  CATATAN PENTING:
#  - Hanya HTTP (port 80) yang bisa di-redirect. HTTPS tidak
#    (butuh sertifikat MITM). Tapi captive-portal detection HP
#    (Android/iOS) memakai HTTP -> popup "Sign in" tetap muncul.
#  - Ganti URL halaman di baris REDIRECT_URL bila nama repo beda.
# ============================================================

# ---- URL halaman reminder (GitHub Pages). TANPA https:// ----
:local redirectUrl "faqihuddinhabibi.github.io/mikrotik-wisp-tools/"
# -------------------------------------------------------------

# 1) Aktifkan web-proxy (transparan lewat NAT di bawah)
/ip proxy set enabled=yes port=8080 cache-on-disk=no max-cache-size=none \
    max-client-connections=1000 max-server-connections=1000

# 2) Aturan akses proxy
#    Bersihkan aturan lama milik script ini dulu
/ip proxy access remove [find comment~"^wg-"]

#    a. Izinkan host GitHub Pages supaya tidak loop
#       (saat browser follow redirect ke github.io)
/ip proxy access add comment="wg-allow-github" dst-host="*.github.io" action=allow
/ip proxy access add comment="wg-allow-github2" dst-host="*.githubusercontent.com" action=allow

#    b. Redirect semua sisanya ke halaman reminder
/ip proxy access add comment="wg-redirect" action=deny redirect-to=$redirectUrl

# 3) NAT: belokkan HTTP (port 80) milik user 'tagihan-reminder' ke proxy 8080
/ip firewall nat remove [find comment="wg-reminder-redirect"]
/ip firewall nat add chain=dstnat action=redirect to-ports=8080 \
    protocol=tcp dst-port=80 src-address-list=tagihan-reminder \
    comment="wg-reminder-redirect"

# 4) (opsional) Buat address-list kosong biar terlihat di menu
/ip firewall address-list remove [find list="tagihan-reminder"]

:put "Setup walled-garden selesai."
:put ("Halaman reminder: http://" . $redirectUrl)
:put "Jalankan billing-scheduler.rsc via scheduler untuk mengisi address-list otomatis."
