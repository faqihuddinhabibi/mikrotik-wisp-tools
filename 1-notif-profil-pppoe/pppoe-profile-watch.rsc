# ============================================================
#  PPPoE Profile Watcher -> Telegram
#  Deteksi 2 hal di /ppp secret, lalu kirim notifikasi Telegram:
#    1. PROFIL berubah (mis. AKTIF -> ISOLIR)
#    2. PPPoE BARU (secret baru dibuat)
#
#  Target : RouterOS 7.x
#  Jalan  : via scheduler, interval 30 menit
#  State  : global variable (RAM). Reset saat reboot = aman
#           (baseline ulang, tidak spam).
# ============================================================

# ---- GANTI DUA BARIS INI ----
:local botToken "GANTI_BOT_TOKEN"
:local chatId   "GANTI_CHAT_ID"
# ------------------------------

# state antar-run
:global pppoeProfileState
:global pppoeInit
:if ([:typeof $pppoeProfileState] = "nothing") do={ :set pppoeProfileState [:toarray ""] }

# run pertama (baseline): catat semua tanpa kirim, biar tidak spam
:local firstRun false
:if ([:typeof $pppoeInit] = "nothing") do={ :set firstRun true; :set pppoeInit true }

:foreach s in=[/ppp secret find] do={
    :local nama [/ppp secret get $s name]
    :local prof [/ppp secret get $s profile]
    :local old  ($pppoeProfileState->$nama)

    :if ([:typeof $old] = "nothing") do={
        # nama belum pernah tercatat = PPPoE baru
        :if (!$firstRun) do={
            :local teks ("PPPoE BARU\\nUser: " . $nama . "\\nProfile: " . $prof)
            :do {
                /tool fetch keep-result=no http-method=post \
                    http-header-field="Content-Type: application/json" \
                    url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
                    http-data=("{\"chat_id\":\"" . $chatId . "\",\"text\":\"" . $teks . "\"}")
            } on-error={ :log warning ("pppoe-profile-watch: gagal kirim (baru) " . $nama) }
        }
        :set ($pppoeProfileState->$nama) $prof
    } else={
        :if ($old != $prof) do={
            :local teks ("PPPoE profile berubah\\nUser: " . $nama . \
                         "\\nDari: " . $old . "\\nJadi: " . $prof)
            :do {
                /tool fetch keep-result=no http-method=post \
                    http-header-field="Content-Type: application/json" \
                    url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
                    http-data=("{\"chat_id\":\"" . $chatId . "\",\"text\":\"" . $teks . "\"}")
            } on-error={ :log warning ("pppoe-profile-watch: gagal kirim (ubah) " . $nama) }
            :set ($pppoeProfileState->$nama) $prof
        }
    }
}
