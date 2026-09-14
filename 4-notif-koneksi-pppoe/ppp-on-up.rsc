# ============================================================
#  Notif PPPoE TERHUBUNG (connect) -> Telegram
#  Tempel isi file ini ke kolom "On Up" pada /ppp profile.
#  Berjalan OTOMATIS & REAL-TIME setiap pelanggan menyambung.
# ============================================================

# ---- GANTI dua baris ini ----
:local botToken "ISI_TOKEN_BOT"
:local chatId   "ISI_CHAT_ID"
# -----------------------------

# ---- alarm gangguan massal ----
# Kalau jumlah PPPoE yang disconnect >= angka ini, pesan diberi peringatan
# "BANYAK DISCONNECT" (indikasi gangguan kabel/ODP, bukan cuma 1 pelanggan).
:local alarmMati 5
# -------------------------------

:local nama  $user
:local waktu "$[/system clock get date] $[/system clock get time]"

# ambil profile & lokasi (lokasi = teks sebelum "/" di comment)
:local profil ""
:local lokasi "-"
:local sid [/ppp secret find name=$nama]
:if ([:len $sid] > 0) do={
    :set profil [/ppp secret get $sid profile]
    :local cmt [/ppp secret get $sid comment]
    :local slash [:find $cmt "/"]
    :local loc $cmt
    :if ([:typeof $slash] = "num") do={ :set loc [:pick $cmt 0 $slash] }
    # buang spasi di ujung
    :while (([:len $loc] > 0) && ([:pick $loc ([:len $loc] - 1) [:len $loc]] = " ")) do={ :set loc [:pick $loc 0 ([:len $loc] - 1)] }
    :if ([:len $loc] > 0) do={ :set lokasi $loc }
}

# hitung yang sedang mati (disconnect) + daftar namanya
:local mati 0
:local daftar ""
:foreach s in=[/ppp secret find] do={
    :local nm [/ppp secret get $s name]
    :if ([:len [/ppp active find where name=$nm]] = 0) do={
        :set mati ($mati + 1)
        :set daftar ($daftar . $nm . ", ")
    }
}
:if ([:len $daftar] > 0) do={ :set daftar [:pick $daftar 0 ([:len $daftar] - 2)] } else={ :set daftar "-" }

# peringatan bila banyak yang mati
:local alarm ""
:if ($mati >= $alarmMati) do={ :set alarm ("⚠️ BANYAK DISCONNECT — cek jaringan/ODP!\\n\\n") }

# ---- TEMPLATE PESAN (boleh diubah) ----
:local teks ("✅ TERHUBUNG\\n\\n" . $alarm . \
             "PPPoE : " . $nama . "\\n" . \
             "Lokasi : " . $lokasi . "\\n" . \
             "Profile : " . $profil . "\\n" . \
             "Waktu : " . $waktu . "\\n\\n" . \
             "Disconnect (" . $mati . "):\\n" . $daftar)
# ---------------------------------------

:do {
    /tool fetch keep-result=no http-method=post \
        http-header-field="Content-Type: application/json" \
        url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
        http-data=("{\"chat_id\":\"" . $chatId . "\",\"text\":\"" . $teks . "\"}")
} on-error={}
