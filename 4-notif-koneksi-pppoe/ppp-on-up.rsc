# ============================================================
#  On Up — catat pelanggan yang TERHUBUNG ke antrian (RINGAN)
#  Tempel isi file ini ke kolom "On Up" pada /ppp profile.
#
#  Script ini SENGAJA tidak mengirim Telegram langsung (biar
#  tidak kena race saat sesi naik/turun & tidak kena rate-limit).
#  Pengiriman dilakukan oleh "kirim-notif.rsc" via scheduler.
#  Anti-duplikat: nama sama tidak dicatat 2x dalam 1 interval.
# ============================================================

:global pppNotifUp
:if ([:typeof $pppNotifUp] = "nothing") do={ :set pppNotifUp "" }
:if ([:typeof [:find $pppNotifUp ($user . ", ")]] = "nothing") do={
    :set pppNotifUp ($pppNotifUp . $user . ", ")
}
