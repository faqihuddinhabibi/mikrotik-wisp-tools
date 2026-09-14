# Notif koneksi PPPoE -> Telegram. Jalankan via scheduler ~30 detik.
# Terhubung kembali + Masih mati (snapshot) + Sering putus (dari on-down counter).

# ---- GANTI ----
:local botToken "ISI_TOKEN_BOT"
:local chatId   "ISI_CHAT_ID"
# ---------------
:local maxList 30
:local flapMin 2

# lock anti-tumpang-tindih (kalau run sebelumnya belum selesai, mis. uplink lambat)
:global pppNotifBusy
:if ([:typeof $pppNotifBusy] = "nothing") do={ :set pppNotifBusy false }
:if ($pppNotifBusy = true) do={
    :log warning "kirim-notif: run sebelumnya masih jalan, dilewati"
} else={
:set pppNotifBusy true

:global pppOfflinePrev
:global pppFlap
:local firstRun false
:if ([:typeof $pppOfflinePrev] = "nothing") do={ :set firstRun true; :set pppOfflinePrev [:toarray ""] }

# ambil & reset counter flap (dari on-down); simpan salinan buat restore kalau gagal kirim
:local flap [:toarray ""]
:if ([:typeof $pppFlap] != "nothing") do={ :set flap $pppFlap }
:set pppFlap [:toarray ""]

# nama yang AKTIF sekarang (snapshot atomik, hindari race find+get)
:local activeSet [:toarray ""]
:foreach r in=[/ppp active print as-value] do={ :set ($activeSet->($r->"name")) 1 }
:local aktif [:len $activeSet]

# yang OFFLINE sekarang (secret enabled yang tidak aktif) + total enabled
:local offNow [:toarray ""]
:local nMati 0
:local total 0
:foreach r in=[/ppp secret print as-value where disabled=no] do={
    :set total ($total + 1)
    :local nm ($r->"name")
    :if ([:typeof ($activeSet->$nm)] = "nothing") do={
        :set ($offNow->$nm) 1
        :set nMati ($nMati + 1)
    }
}

# terhubung kembali = ada di prev DAN sekarang benar-benar aktif (bukan dihapus)
:local recovered ""
:local nRec 0
:local changed false
:foreach nm,v in=$pppOfflinePrev do={
    :if ([:typeof ($activeSet->$nm)] != "nothing") do={
        :set changed true
        :set nRec ($nRec + 1)
        :if ($nRec <= $maxList) do={ :set recovered ($recovered . $nm . ", ") }
    }
}
# ada yang baru mati?
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

:local adaKirim ((!$firstRun) && ($changed || ($nFlap > 0)))
:local ok false

:if ($adaKirim) do={
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

    :local waktu "$[/system clock get date] $[/system clock get time]"

    :local teks ("<b>Update Koneksi</b>\\n" . $waktu . "\\n" . \
                 "Aktif: " . $aktif . "/" . $total . "\\n\\n" . \
                 "<b>Terhubung kembali</b>:\\n" . $recovered . "\\n\\n" . \
                 "<b>Masih mati</b> (" . $nMati . "):\\n" . $mati . "\\n\\n" . \
                 "<b>Sering putus</b> (30 dtk):\\n" . $flapStr)

    # pagar 4096 Telegram: kalau kepanjangan, kirim ringkas (angka saja)
    :if ([:len $teks] > 3900) do={
        :set teks ("<b>Update Koneksi</b>\\n" . $waktu . "\\n" . \
                   "Aktif: " . $aktif . "/" . $total . "\\n" . \
                   "Terhubung kembali: " . $nRec . "\\n" . \
                   "Masih mati: " . $nMati . "\\n" . \
                   "Sering putus: " . $nFlap . "\\n(daftar terlalu panjang, cek Winbox)")
    }

    :do {
        /tool fetch keep-result=no http-method=post \
            http-header-field="Content-Type: application/json" \
            url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
            http-data=("{\"chat_id\":\"" . $chatId . "\",\"parse_mode\":\"HTML\",\"text\":\"" . $teks . "\"}")
        :set ok true
    } on-error={ :log warning "kirim-notif: gagal kirim Telegram" }
}

# Majukan state HANYA kalau aman: firstRun, atau tidak ada yang dikirim, atau sukses.
# Kalau ada yang mau dikirim tapi GAGAL: jangan maju (biar dikirim ulang), kembalikan flap.
:if (($firstRun) || (!$adaKirim) || ($ok)) do={
    :set pppOfflinePrev $offNow
} else={
    :foreach nm,c in=$flap do={
        :local cur ($pppFlap->$nm)
        :if ([:typeof $cur] = "nothing") do={ :set cur 0 }
        :set ($pppFlap->$nm) ($cur + $c)
    }
}

:set pppNotifBusy false
}
