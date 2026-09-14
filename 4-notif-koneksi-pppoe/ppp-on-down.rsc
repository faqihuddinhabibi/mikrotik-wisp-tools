# ============================================================
#  On Down — catat pelanggan yang TERPUTUS ke antrian (RINGAN)
#  Tempel isi file ini ke kolom "On Down" pada /ppp profile.
#
#  Script ini SENGAJA tidak mengirim Telegram langsung (biar
#  tidak kena race saat sesi turun & tidak kena rate-limit).
#  Pengiriman dilakukan oleh "kirim-notif.rsc" via scheduler.
#  Anti-duplikat: nama sama tidak dicatat 2x dalam 1 interval.
# ============================================================

:global pppNotifDown
:if ([:typeof $pppNotifDown] = "nothing") do={ :set pppNotifDown "" }
:if ([:typeof [:find $pppNotifDown ($user . ", ")]] = "nothing") do={
    :set pppNotifDown ($pppNotifDown . $user . ", ")
}
