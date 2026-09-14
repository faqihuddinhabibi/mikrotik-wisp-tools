# PPPoE Profile Watcher -> Telegram (profil berubah / baru / dihapus)

# ---- GANTI ----
:local botToken "GANTI_BOT_TOKEN"
:local chatId   "GANTI_CHAT_ID"
# ---------------

:global pppoeProfileState
:global pppoeInit
:if ([:typeof $pppoeProfileState] = "nothing") do={ :set pppoeProfileState [:toarray ""] }
:local firstRun false
:if ([:typeof $pppoeInit] = "nothing") do={ :set firstRun true; :set pppoeInit true }

:local current  [:toarray ""]
:local newState [:toarray ""]

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
        } on-error={}
    }
    :set ($newState->$nama) $prof
}

:foreach nm,pr in=$pppoeProfileState do={
    :if ([:typeof ($current->$nm)] = "nothing") do={
        :if (!$firstRun) do={
            :local teks ("PPPoE DIHAPUS\\nUser: " . $nm . "\\nProfile terakhir: " . $pr)
            :do {
                /tool fetch keep-result=no http-method=post \
                    http-header-field="Content-Type: application/json" \
                    url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
                    http-data=("{\"chat_id\":\"" . $chatId . "\",\"text\":\"" . $teks . "\"}")
            } on-error={}
        }
    }
}

:set pppoeProfileState $newState
