# ============================================================
#  Notif PPPoE TERPUTUS (disconnect) -> Telegram
#  Tempel isi file ini ke kolom "On Down" pada /ppp profile.
#  Berjalan OTOMATIS & REAL-TIME setiap pelanggan terputus.
#
#  Variabel yang tersedia di On Down:
#    $user, $"remote-address", $"caller-id", $"interface", $uptime
# ============================================================

# ---- GANTI dua baris ini ----
:local botToken "ISI_TOKEN_BOT"
:local chatId   "ISI_CHAT_ID"
# -----------------------------

:local nama   $user
:local ip     $"remote-address"
:local lama   $uptime
:local waktu  "$[/system clock get date] $[/system clock get time]"

# ---- TEMPLATE PESAN (boleh diubah) ----
:local teks ("❌ TERPUTUS\\n" . \
             "User    : " . $nama . "\\n" . \
             "IP      : " . $ip . "\\n" . \
             "Durasi  : " . $lama . "\\n" . \
             "Waktu   : " . $waktu)
# ---------------------------------------

:do {
    /tool fetch keep-result=no http-method=post \
        http-header-field="Content-Type: application/json" \
        url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
        http-data=("{\"chat_id\":\"" . $chatId . "\",\"text\":\"" . $teks . "\"}")
} on-error={}
