# ============================================================
#  PPPoE Profile Watcher -> Telegram
#  Deteksi perubahan field "profile" di /ppp secret,
#  lalu kirim notifikasi Telegram.
#
#  Target : RouterOS 7.24.2 (x86 / HP ProDesk 600 G5)
#  Jalan  : via scheduler, interval 1 menit
#  State  : global variable (RAM). Reset saat reboot = aman
#           (baseline ulang, tidak spam).
# ============================================================

# ---- GANTI DUA BARIS INI ----
:local botToken "GANTI_BOT_TOKEN"
:local chatId   "GANTI_CHAT_ID"
# ------------------------------

# state antar-run
:global pppoeProfileState
:if ([:typeof $pppoeProfileState] = "nothing") do={
    :set pppoeProfileState [:toarray ""]
}

:foreach s in=[/ppp secret find] do={
    :local nama [/ppp secret get $s name]
    :local prof [/ppp secret get $s profile]
    :local old  ($pppoeProfileState->$nama)

    :if ([:typeof $old] = "nothing") do={
        # pertama kali lihat user ini -> catat saja, jangan kirim
        :set ($pppoeProfileState->$nama) $prof
    } else={
        :if ($old != $prof) do={
            # susun pesan (pakai \\n = newline literal di dalam JSON)
            :local teks ("PPPoE profile berubah\\nUser: " . $nama . \
                         "\\nDari: " . $old . "\\nJadi: " . $prof)

            :do {
                /tool fetch keep-result=no http-method=post \
                    http-header-field-value="Content-Type: application/json" \
                    url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
                    http-data=("{\"chat_id\":\"" . $chatId . "\",\"text\":\"" . $teks . "\"}")
            } on-error={
                :log warning ("pppoe-profile-watch: gagal kirim Telegram utk user " . $nama)
            }

            # update state ke nilai baru
            :set ($pppoeProfileState->$nama) $prof
        }
    }
}
