# ============================================================
#  Notif PPPoE TERPUTUS (disconnect) -> Telegram
#  Tempel isi file ini ke kolom "On Down" pada /ppp profile.
#  Berjalan OTOMATIS & REAL-TIME setiap pelanggan terputus.
# ============================================================

# ---- GANTI dua baris ini ----
:local botToken "ISI_TOKEN_BOT"
:local chatId   "ISI_CHAT_ID"
# -----------------------------

:local nama  $user
:local waktu "$[/system clock get date] $[/system clock get time]"

# ambil profile pelanggan
:local profil ""
:local sid [/ppp secret find name=$nama]
:if ([:len $sid] > 0) do={ :set profil [/ppp secret get $sid profile] }

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

# ---- TEMPLATE PESAN (boleh diubah) ----
:local teks ("❌ TERPUTUS\\n\\n" . \
             "PPPoE : " . $nama . "\\n" . \
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
