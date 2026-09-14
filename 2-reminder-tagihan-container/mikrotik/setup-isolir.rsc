# Setup ISOLIR walled-garden (SEKALI JALAN) - versi CONTAINER

# ---- GANTI sesuai setup-mu ----
# redirectUrl = alamat halaman isolir (ADA /isolir.html)
# pageIp = IP halaman (tanpa /). isolirNet = subnet pool isolir (cek: /ip pool print)
:local redirectUrl "172.17.0.2/isolir.html"
:local pageIp      "172.17.0.2"
:local isolirNet   "10.1.1.0/24"
# -------------------------------

/ip proxy set enabled=yes port=8080 cache-on-disk=no max-cache-size=none

/ip firewall address-list remove [find list="ALLOW-ISOLIR"]
/ip firewall address-list add list="ALLOW-ISOLIR" address=$pageIp comment="halaman-isolir"

/ip proxy access remove [find comment~"^iso-"]
/ip proxy access add comment="iso-redirect" src-address=$isolirNet action=deny redirect-to=$redirectUrl

/ip firewall nat remove [find comment="iso-redirect80"]
/ip firewall nat add chain=dstnat action=redirect to-ports=8080 \
    protocol=tcp dst-port=80 src-address=$isolirNet comment="iso-redirect80"

/ip firewall filter remove [find comment~"^iso-"]
/ip firewall filter add chain=forward comment="iso-allow-page" src-address=$isolirNet dst-address-list=ALLOW-ISOLIR action=accept
/ip firewall filter add chain=forward comment="iso-allow-dns" src-address=$isolirNet protocol=udp dst-port=53 action=accept
/ip firewall filter add chain=forward comment="iso-allow-dns-tcp" src-address=$isolirNet protocol=tcp dst-port=53 action=accept
/ip firewall filter add chain=forward comment="iso-drop-rest" src-address=$isolirNet action=drop

:put "Setup ISOLIR (container) selesai."
