# ============================================================
#  Notif PPPoE TERHUBUNG (connect) -> Telegram
#  Tempel isi file ini ke kolom "On Up" pada /ppp profile.
#  Berjalan OTOMATIS & REAL-TIME setiap pelanggan menyambung.
#
#  Isi pesan: nama PPPoE yang connect + total PPPoE + jumlah
#  yang mati + daftar nama yang mati.
# ============================================================

# ---- GANTI dua baris ini ----
:local botToken "ISI_TOKEN_BOT"
:local chatId   "ISI_CHAT_ID"
# -----------------------------

:local nama  $user
:local waktu "$[/system clock get date] $[/system clock get time]"

# hitung total PPPoE, yang mati, dan daftar nama yang mati
:local total [/ppp secret print count]
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
:local teks ("✅ TERHUBUNG\\n" . \
             "PPPoE : " . $nama . "\\n" . \
             "Total : " . $total . "   Mati : " . $mati . "\\n" . \
             "Yang mati: " . $daftar . "\\n" . \
             "Jam   : " . $waktu)
# ---------------------------------------

:do {
    /tool fetch keep-result=no http-method=post \
        http-header-field="Content-Type: application/json" \
        url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
        http-data=("{\"chat_id\":\"" . $chatId . "\",\"text\":\"" . $teks . "\"}")
} on-error={}
