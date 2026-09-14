# ============================================================
#  Setup Walled-Garden Reminder Tagihan (SEKALI JALAN)
#  Web-proxy bawaan RouterOS untuk me-redirect HTTP user yang
#  masuk address-list "tagihan-reminder" ke halaman pengingat.
#
#  VERSI CONTAINER: halaman di-host di container DALAM MikroTik.
#  Default IP container = 172.17.0.2 (lihat README folder ini).
#
#  Target : RouterOS 7.x. Tanpa layanan luar.
#
#  CATATAN: hanya HTTP (port 80) yang bisa di-redirect. HTTPS tidak
#  (butuh sertifikat MITM). Tapi captive-portal detection HP
#  (Android/iOS) memakai HTTP -> popup "Sign in" tetap muncul.
# ============================================================

# ---- URL halaman reminder (IP container). TANPA http:// ----
:local redirectUrl "172.17.0.2/"
# ------------------------------------------------------------

# 1) Aktifkan web-proxy (transparan lewat NAT di bawah)
/ip proxy set enabled=yes port=8080 cache-on-disk=no max-cache-size=none \
    max-client-connections=1000 max-server-connections=1000

# 2) Aturan akses proxy (bersihkan aturan lama milik script ini dulu)
/ip proxy access remove [find comment~"^wg-"]
#    redirect semua HTTP user 'tagihan-reminder' ke halaman
/ip proxy access add comment="wg-redirect" action=deny redirect-to=$redirectUrl

# 3) NAT: belokkan HTTP (port 80) milik user 'tagihan-reminder' ke proxy 8080
/ip firewall nat remove [find comment="wg-reminder-redirect"]
/ip firewall nat add chain=dstnat action=redirect to-ports=8080 \
    protocol=tcp dst-port=80 src-address-list=tagihan-reminder \
    comment="wg-reminder-redirect"

# 4) siapkan address-list (kosong; diisi otomatis oleh billing-scheduler)
/ip firewall address-list remove [find list="tagihan-reminder"]

:put "Setup walled-garden (container) selesai."
:put ("Halaman reminder: http://" . $redirectUrl)
:put "Pastikan container web sudah running (lihat README)."
:put "Lalu pasang billing-scheduler.rsc via scheduler."
