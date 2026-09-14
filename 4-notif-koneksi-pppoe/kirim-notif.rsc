# Notif koneksi PPPoE (snapshot) -> Telegram. Jalankan via scheduler ~30 detik.
# Kirim HANYA saat daftar offline berubah: siapa yang baru nyala + daftar yang mati.

# ---- GANTI ----
:local botToken "ISI_TOKEN_BOT"
:local chatId   "ISI_CHAT_ID"
# ---------------
:local maxList 40

:global pppOfflinePrev
:local firstRun false
:if ([:typeof $pppOfflinePrev] = "nothing") do={ :set firstRun true; :set pppOfflinePrev [:toarray ""] }

# kumpulan nama yang AKTIF sekarang
:local activeSet [:toarray ""]
:foreach a in=[/ppp active find] do={ :set ($activeSet->[/ppp active get $a name]) 1 }

# kumpulan yang OFFLINE sekarang
:local offNow [:toarray ""]
:local nMati 0
:foreach s in=[/ppp secret find] do={
    :local nm [/ppp secret get $s name]
    :if ([:typeof ($activeSet->$nm)] = "nothing") do={
        :set ($offNow->$nm) 1
        :set nMati ($nMati + 1)
    }
}

# deteksi perubahan + daftar "baru nyala" (tadinya mati, sekarang aktif)
:local changed false
:local recovered ""
:local nRec 0
:foreach nm,v in=$pppOfflinePrev do={
    :if ([:typeof ($offNow->$nm)] = "nothing") do={
        :set changed true
        :set nRec ($nRec + 1)
        :if ($nRec <= $maxList) do={ :set recovered ($recovered . $nm . ", ") }
    }
}
:foreach nm,v in=$offNow do={
    :if ([:typeof ($pppOfflinePrev->$nm)] = "nothing") do={ :set changed true }
}

:if ($firstRun) do={
    :set pppOfflinePrev $offNow
} else={
    :if ($changed) do={
        :local mati ""
        :local lm 0
        :foreach nm,v in=$offNow do={
            :if ($lm < $maxList) do={ :set mati ($mati . $nm . ", "); :set lm ($lm + 1) }
        }
        :if ([:len $mati] > 0) do={ :set mati [:pick $mati 0 ([:len $mati] - 2)] } else={ :set mati "-" }
        :if ($nMati > $lm) do={ :set mati ($mati . " … +" . ($nMati - $lm) . " lagi") }

        :if ([:len $recovered] > 0) do={ :set recovered [:pick $recovered 0 ([:len $recovered] - 2)] } else={ :set recovered "-" }
        :if ($nRec > $maxList) do={ :set recovered ($recovered . " … +" . ($nRec - $maxList) . " lagi") }

        :local total [/ppp secret print count]
        :local aktif [/ppp active print count]
        :local waktu "$[/system clock get date] $[/system clock get time]"

        :local teks ("<b>Update Koneksi</b>\\n" . $waktu . "\\n" . \
                     "Aktif: " . $aktif . "/" . $total . "\\n\\n" . \
                     "🟢 <b>Baru nyala</b>: " . $recovered . "\\n" . \
                     "🔴 <b>Yang mati</b> (" . $nMati . "): " . $mati)

        :do {
            /tool fetch keep-result=no http-method=post \
                http-header-field="Content-Type: application/json" \
                url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
                http-data=("{\"chat_id\":\"" . $chatId . "\",\"parse_mode\":\"HTML\",\"text\":\"" . $teks . "\"}")
        } on-error={}

        :set pppOfflinePrev $offNow
    }
}
