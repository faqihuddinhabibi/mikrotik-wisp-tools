# Setup walled-garden reminder (SEKALI JALAN) - versi CONTAINER
# redirectUrl = IP halaman (container), pakai "/" di akhir
:local redirectUrl "172.17.0.2/"

/ip proxy set enabled=yes port=8080 cache-on-disk=no max-cache-size=none \
    max-client-connections=1000 max-server-connections=1000

/ip proxy access remove [find comment~"^wg-"]
/ip proxy access add comment="wg-redirect" action=deny redirect-to=$redirectUrl

/ip firewall nat remove [find comment="wg-reminder-redirect"]
/ip firewall nat add chain=dstnat action=redirect to-ports=8080 \
    protocol=tcp dst-port=80 src-address-list=tagihan-reminder \
    comment="wg-reminder-redirect"

/ip firewall address-list remove [find list="tagihan-reminder"]
:put "Setup walled-garden (container) selesai."
