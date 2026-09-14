# ============================================================
#  Notif PPPoE TERHUBUNG (connect) -> Telegram
#  Tempel isi file ini ke kolom "On Up" pada /ppp profile.
#  Berjalan OTOMATIS & REAL-TIME setiap pelanggan menyambung.
#
#  Variabel yang tersedia di On Up:
#    $user, $"remote-address", $"caller-id", $"interface", $"local-address"
# ============================================================

# ---- GANTI dua baris ini ----
:local botToken "ISI_TOKEN_BOT"
:local chatId   "ISI_CHAT_ID"
# -----------------------------

:local nama   $user
:local ip     $"remote-address"
:local mac    $"caller-id"
:local waktu  "$[/system clock get date] $[/system clock get time]"

# ---- TEMPLATE PESAN (boleh diubah) ----
:local teks ("✅ TERHUBUNG\\n" . \
             "User  : " . $nama . "\\n" . \
             "IP    : " . $ip . "\\n" . \
             "MAC   : " . $mac . "\\n" . \
             "Waktu : " . $waktu)
# ---------------------------------------

:do {
    /tool fetch keep-result=no http-method=post \
        http-header-field="Content-Type: application/json" \
        url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
        http-data=("{\"chat_id\":\"" . $chatId . "\",\"text\":\"" . $teks . "\"}")
} on-error={}
