# Setup reminder + isolir (JALANKAN SEKALI via /import). Aman diulang: aturan lama dihapus dulu.

# ---- GANTI ----
# pageHost = host GitHub Pages TANPA "/" ; pageUrl = alamat halaman reminder, ADA "/" di akhir, TANPA "http://"
:local pageHost  "USERNAME.github.io"
:local pageUrl   "USERNAME.github.io/mikrotik-wisp-tools/"
# subnet pool isolir (cek: /ip pool print)
:local isolirNet "10.1.1.0/24"
# ---------------

/ip proxy set enabled=yes port=8080 cache-on-disk=no max-cache-size=none \
    max-client-connections=1000 max-server-connections=1000

# urutan PENTING: isolir dulu (deny -> error.html), lalu izinkan host halaman (anti loop), lalu reminder
/ip proxy access remove [find comment~"^iso-"]
/ip proxy access remove [find comment~"^wg-"]
/ip proxy access add comment="iso-deny"      src-address=$isolirNet action=deny
/ip proxy access add comment="wg-allow-page" dst-host=$pageHost action=allow
/ip proxy access add comment="wg-redirect"   action=deny redirect-to=$pageUrl

# belokkan HTTP (port 80) ke proxy: isolir selalu, reminder hanya yang ada di daftar
/ip firewall nat remove [find comment~"^iso-"]
/ip firewall nat remove [find comment~"^wg-"]
/ip firewall nat add chain=dstnat comment="iso-redirect80" protocol=tcp dst-port=80 \
    src-address=$isolirNet action=redirect to-ports=8080
/ip firewall nat add chain=dstnat comment="wg-redirect80" protocol=tcp dst-port=80 \
    src-address-list=tagihan-reminder action=redirect to-ports=8080

# isolir: blokir semua kecuali DNS (HTTP-nya sudah dibelokkan ke proxy sebelum sampai sini)
/ip firewall filter remove [find comment~"^iso-"]
/ip firewall filter add chain=forward comment="iso-allow-dns"     src-address=$isolirNet protocol=udp dst-port=53 action=accept
/ip firewall filter add chain=forward comment="iso-allow-dns-tcp" src-address=$isolirNet protocol=tcp dst-port=53 action=accept
/ip firewall filter add chain=forward comment="iso-drop"          src-address=$isolirNet action=drop

/ip firewall address-list remove [find list="tagihan-reminder"]
:put "Selesai. Lanjut: upload error.html ke Files -> webproxy/ (lihat README Bagian B)."
