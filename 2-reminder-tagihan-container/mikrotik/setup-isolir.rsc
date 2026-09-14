# ============================================================
#  Setup ISOLIR Walled-Garden (SEKALI JALAN) — VERSI CONTAINER
#  User dengan profile isolir (subnet pool isolir) akan:
#   - internet DIBLOKIR total
#   - semua HTTP diarahkan ke halaman isolir
#   - hanya boleh akses DNS + halaman isolir (container lokal)
#
#  Target : RouterOS 7.x
#  Halaman di-host di container DALAM MikroTik (default 172.17.0.2)
#  -> tidak butuh internet sama sekali untuk menampilkan halaman.
#
#  Cara pakai isolir: teknisi ubah profile user di /ppp secret
#  jadi profile isolir, lalu putus/konek ulang.
#  Balikin ke profile paket semula untuk reaktivasi.
# ============================================================

# ---- konfigurasi (SESUAIKAN dengan setup-mu) ----
# IP container halaman isolir:
:local redirectUrl "172.17.0.2/isolir.html"
:local pageIp      "172.17.0.2"
# Subnet pool profile isolir. Cari dengan: /ip pool print
# Contoh kalau pool isolir 10.1.1.2-10.1.1.254 -> subnet "10.1.1.0/24"
:local isolirNet   "10.1.1.0/24"
# -------------------------------------------------

# 1) Aktifkan web-proxy
/ip proxy set enabled=yes port=8080 cache-on-disk=no max-cache-size=none

# 2) Whitelist IP halaman (container) supaya tetap kebuka saat diblokir
/ip firewall address-list remove [find list="ALLOW-ISOLIR"]
/ip firewall address-list add list="ALLOW-ISOLIR" address=$pageIp comment="halaman-isolir"

# 3) Aturan akses proxy: redirect HTTP subnet isolir ke halaman isolir
/ip proxy access remove [find comment~"^iso-"]
/ip proxy access add comment="iso-redirect" src-address=$isolirNet action=deny redirect-to=$redirectUrl

# 4) NAT: belokkan HTTP (port 80) subnet isolir ke proxy 8080
/ip firewall nat remove [find comment="iso-redirect80"]
/ip firewall nat add chain=dstnat action=redirect to-ports=8080 \
    protocol=tcp dst-port=80 src-address=$isolirNet comment="iso-redirect80"

# 5) Firewall filter: blok internet subnet isolir kecuali DNS + halaman
#    (chain forward. Urutan penting: accept dulu, drop paling akhir.)
/ip firewall filter remove [find comment~"^iso-"]
/ip firewall filter add chain=forward comment="iso-allow-page" \
    src-address=$isolirNet dst-address-list=ALLOW-ISOLIR action=accept
/ip firewall filter add chain=forward comment="iso-allow-dns" \
    src-address=$isolirNet protocol=udp dst-port=53 action=accept
/ip firewall filter add chain=forward comment="iso-allow-dns-tcp" \
    src-address=$isolirNet protocol=tcp dst-port=53 action=accept
/ip firewall filter add chain=forward comment="iso-drop-rest" \
    src-address=$isolirNet action=drop

:put "Setup ISOLIR (container) selesai."
:put ("Subnet isolir : " . $isolirNet)
:put ("Halaman       : http://" . $redirectUrl)
:put "Cara isolir user: ubah profile /ppp secret -> profile isolir, lalu putus/konek ulang."
