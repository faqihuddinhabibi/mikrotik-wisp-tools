# ============================================================
#  Setup ISOLIR Walled-Garden (SEKALI JALAN)
#  User dengan profile "ISOLIR" (subnet 10.1.1.0/24) akan:
#   - internet DIBLOKIR total
#   - semua HTTP diarahkan ke halaman isolir
#   - hanya boleh akses DNS + halaman isolir (GitHub Pages)
#
#  Target : RouterOS 7.24.2 (x86) — DISTRIBUSI MUSUK
#  Cocok dgn config existing:
#   - Profile ISOLIR sudah ada (pool ISOLIR 10.1.1.2-10.1.1.254)
#   - Firewall filter kosong, web-proxy belum nyala (aman)
#
#  Cara pakai isolir: teknisi tinggal ubah profile user
#  di /ppp secret jadi "ISOLIR", lalu putus/konek ulang.
#  Balikin ke profile paket semula untuk reaktivasi.
# ============================================================

# ---- konfigurasi ----
:local redirectUrl "faqihuddinhabibi.github.io/mikrotik-wisp-tools/isolir.html"
:local isolirNet   "10.1.1.0/24"
# ---------------------

# 1) Aktifkan web-proxy (dipakai untuk redirect transparan)
/ip proxy set enabled=yes port=8080 cache-on-disk=no max-cache-size=none

# 2) IP GitHub Pages (biar halaman isolir tetap bisa kebuka saat diblokir)
/ip firewall address-list remove [find list="ALLOW-ISOLIR"]
/ip firewall address-list add list="ALLOW-ISOLIR" address=185.199.108.153 comment="github-pages"
/ip firewall address-list add list="ALLOW-ISOLIR" address=185.199.109.153 comment="github-pages"
/ip firewall address-list add list="ALLOW-ISOLIR" address=185.199.110.153 comment="github-pages"
/ip firewall address-list add list="ALLOW-ISOLIR" address=185.199.111.153 comment="github-pages"

# 3) Aturan akses proxy
/ip proxy access remove [find comment~"^iso-"]
#    a. izinkan host GitHub (hindari loop saat follow redirect)
/ip proxy access add comment="iso-allow-github" dst-host="*.github.io" action=allow
/ip proxy access add comment="iso-allow-github2" dst-host="*.githubusercontent.com" action=allow
#    b. redirect semua HTTP dari subnet isolir ke halaman isolir
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

:put "Setup ISOLIR selesai."
:put ("Subnet isolir : " . $isolirNet)
:put ("Halaman       : http://" . $redirectUrl)
:put "Cara isolir user: ubah profile /ppp secret -> ISOLIR, lalu putus/konek ulang."
:put "Reaktivasi     : balikin profile ke paket semula, putus/konek ulang."
