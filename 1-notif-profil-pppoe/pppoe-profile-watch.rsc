# ============================================================
#  PPPoE Profile Watcher -> Telegram
#  Deteksi 3 hal di /ppp secret, lalu kirim notifikasi Telegram:
#    1. PROFIL berubah (mis. AKTIF -> ISOLIR)
#    2. PPPoE BARU (secret baru dibuat)
#    3. PPPoE DIHAPUS (secret dihapus)
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

:local current   [:toarray ""]
:local newState  [:toarray ""]

# ---- cek secret yang ADA sekarang: BARU / BERUBAH ----
:foreach s in=[/ppp secret find] do={
    :local nama [/ppp secret get $s name]
    :local prof [/ppp secret get $s profile]
    :set ($current->$nama) 1
    :local old ($pppoeProfileState->$nama)
    :local teks ""

    :if ([:typeof $old] = "nothing") do={
        :if (!$firstRun) do={ :set teks ("PPPoE BARU\\nUser: " . $nama . "\\nProfile: " . $prof) }
    } else={
        :if ($old != $prof) do={ :set teks ("PPPoE profile berubah\\nUser: " . $nama . "\\nDari: " . $old . "\\nJadi: " . $prof) }
    }

    :if ([:len $teks] > 0) do={
        :do {
            /tool fetch keep-result=no http-method=post \
                http-header-field="Content-Type: application/json" \
                url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
                http-data=("{\"chat_id\":\"" . $chatId . "\",\"text\":\"" . $teks . "\"}")
        } on-error={ :log warning ("pppoe-profile-watch: gagal kirim " . $nama) }
    }

    :set ($newState->$nama) $prof
}

# ---- cek nama yang HILANG dari state = DIHAPUS ----
:foreach nm,pr in=$pppoeProfileState do={
    :if ([:typeof ($current->$nm)] = "nothing") do={
        :if (!$firstRun) do={
            :local teks ("PPPoE DIHAPUS\\nUser: " . $nm . "\\nProfile terakhir: " . $pr)
            :do {
                /tool fetch keep-result=no http-method=post \
                    http-header-field="Content-Type: application/json" \
                    url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
                    http-data=("{\"chat_id\":\"" . $chatId . "\",\"text\":\"" . $teks . "\"}")
            } on-error={ :log warning ("pppoe-profile-watch: gagal kirim (hapus) " . $nm) }
        }
    }
}

# ganti state dengan yang terbaru (nama dihapus otomatis hilang, yang baru masuk)
:set pppoeProfileState $newState
