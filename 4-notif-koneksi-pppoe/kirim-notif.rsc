# Notif koneksi PPPoE -> Telegram. Jalankan via scheduler ~30 detik.
# Terhubung kembali + Masih mati (snapshot) + Sering putus (dari on-down counter).

# ---- GANTI ----
:local botToken "ISI_TOKEN_BOT"
:local chatId   "ISI_CHAT_ID"
# ---------------
:local maxList 40
:local flapMin 2

:global pppOfflinePrev
:global pppFlap
:local firstRun false
:if ([:typeof $pppOfflinePrev] = "nothing") do={ :set firstRun true; :set pppOfflinePrev [:toarray ""] }

# ambil & reset counter flap (dari on-down)
:local flap [:toarray ""]
:if ([:typeof $pppFlap] != "nothing") do={ :set flap $pppFlap }
:set pppFlap [:toarray ""]

# nama yang AKTIF sekarang
:local activeSet [:toarray ""]
:foreach a in=[/ppp active find] do={
    :local an [/ppp active get $a name]
    :set ($activeSet->$an) 1
}

# yang OFFLINE sekarang
:local offNow [:toarray ""]
:local nMati 0
:foreach s in=[/ppp secret find] do={
    :local nm [/ppp secret get $s name]
    :if ([:typeof ($activeSet->$nm)] = "nothing") do={
        :set ($offNow->$nm) 1
        :set nMati ($nMati + 1)
    }
}

# terhubung kembali (tadinya mati, sekarang aktif) + deteksi perubahan
:local recovered ""
:local nRec 0
:local changed false
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

# daftar sering putus (>= flapMin kali)
:local flapStr ""
:local nFlap 0
:local lf 0
:foreach nm,c in=$flap do={
    :if ($c >= $flapMin) do={
        :set nFlap ($nFlap + 1)
        :if ($lf < $maxList) do={ :set flapStr ($flapStr . $nm . " (" . $c . "x), "); :set lf ($lf + 1) }
    }
}

:if ((!$firstRun) && ($changed || ($nFlap > 0))) do={
    :local mati ""
    :local lm 0
    :foreach nm,v in=$offNow do={
        :if ($lm < $maxList) do={ :set mati ($mati . $nm . ", "); :set lm ($lm + 1) }
    }
    :if ([:len $mati] > 0) do={ :set mati [:pick $mati 0 ([:len $mati] - 2)] } else={ :set mati "-" }
    :if ($nMati > $lm) do={ :set mati ($mati . " … +" . ($nMati - $lm) . " lagi") }

    :if ([:len $recovered] > 0) do={ :set recovered [:pick $recovered 0 ([:len $recovered] - 2)] } else={ :set recovered "-" }
    :if ($nRec > $maxList) do={ :set recovered ($recovered . " … +" . ($nRec - $maxList) . " lagi") }

    :if ([:len $flapStr] > 0) do={ :set flapStr [:pick $flapStr 0 ([:len $flapStr] - 2)] } else={ :set flapStr "-" }
    :if ($nFlap > $lf) do={ :set flapStr ($flapStr . " … +" . ($nFlap - $lf) . " lagi") }

    :local total [/ppp secret print count]
    :local aktif [/ppp active print count]
    :local waktu "$[/system clock get date] $[/system clock get time]"

    :local teks ("<b>Update Koneksi</b>\\n" . $waktu . "\\n" . \
                 "Aktif: " . $aktif . "/" . $total . "\\n\\n" . \
                 "<b>Terhubung kembali</b>:\\n" . $recovered . "\\n\\n" . \
                 "<b>Masih mati</b> (" . $nMati . "):\\n" . $mati . "\\n\\n" . \
                 "<b>Sering putus</b> (30 dtk):\\n" . $flapStr)

    :do {
        /tool fetch keep-result=no http-method=post \
            http-header-field="Content-Type: application/json" \
            url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
            http-data=("{\"chat_id\":\"" . $chatId . "\",\"parse_mode\":\"HTML\",\"text\":\"" . $teks . "\"}")
    } on-error={}
}

:set pppOfflinePrev $offNow
