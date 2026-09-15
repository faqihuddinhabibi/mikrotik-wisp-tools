# Reminder H-1: isi address-list "tagihan-reminder" (baca DUE:NN dari comment). Scheduler tiap 1 jam.

# ---- opsional Telegram (kosongkan botToken untuk mematikan) ----
:local botToken ""
:local chatId   ""
# nama yang TIDAK direminder, dipisah & diapit koma. Contoh: ",kantor-desa,sekolah,"
:local excludeNames ",,"
# ----------------------------------------------------------------

:local tgl [/system clock get date]
:local ys [:pick $tgl 0 4]
:local ms [:pick $tgl 5 7]
:local ds [:pick $tgl 8 10]
:if ([:pick $ms 0 1] = "0") do={ :set ms [:pick $ms 1 2] }
:if ([:pick $ds 0 1] = "0") do={ :set ds [:pick $ds 1 2] }
:local yr    [:tonum $ys]
:local mo    [:tonum $ms]
:local today [:tonum $ds]

:local dim 31
:if ($mo = 4 || $mo = 6 || $mo = 9 || $mo = 11) do={ :set dim 30 }
:if ($mo = 2) do={
    :set dim 28
    :if (($yr - (($yr / 4) * 4)) = 0) do={ :set dim 29 }
    :if ((($yr - (($yr / 100) * 100)) = 0) && (($yr - (($yr / 400) * 400)) != 0)) do={ :set dim 28 }
}
:local besok ($today + 1)
:if ($today >= $dim) do={ :set besok 1 }

:local cmtOf [:toarray ""]
:foreach s in=[/ppp secret print as-value] do={ :set ($cmtOf->($s->"name")) ($s->"comment") }

/ip firewall address-list remove [find list="tagihan-reminder"]

:local daftar ""
:local jml 0
:foreach a in=[/ppp active print as-value] do={
    :local nama ($a->"name")
    :local ip   ($a->"address")
    :local cmt  ($cmtOf->$nama)
    :if ([:typeof $cmt] != "str") do={ :set cmt "" }
    :local skip false
    :if ([:typeof [:find $cmt "SKIP"]] = "num") do={ :set skip true }
    :if ([:typeof [:find $excludeNames ("," . $nama . ",")]] = "num") do={ :set skip true }
    :local p [:find $cmt "DUE:"]
    :if (([:typeof $p] = "num") && (!$skip)) do={
        :local rest [:pick $cmt ($p + 4) [:len $cmt]]
        :local dstr ""
        :local i 0
        :local stop false
        :while (($i < [:len $rest]) && (!$stop)) do={
            :local c [:pick $rest $i ($i + 1)]
            :if (($c >= "0") && ($c <= "9")) do={
                :set dstr ($dstr . $c); :set i ($i + 1)
            } else={
                :if (($c = " ") && ($dstr = "")) do={ :set i ($i + 1) } else={ :set stop true }
            }
        }
        :while (([:len $dstr] > 1) && ([:pick $dstr 0 1] = "0")) do={ :set dstr [:pick $dstr 1 [:len $dstr]] }
        :if (([:len $dstr] > 0) && ([:tonum $dstr] = $besok)) do={
            :do {
                /ip firewall address-list add list="tagihan-reminder" address=$ip comment=$nama timeout=2h
                :set daftar ($daftar . $nama . ", ")
                :set jml ($jml + 1)
            } on-error={}
        }
    }
}

:if (([:len $botToken] > 0) && ($jml > 0)) do={
    :set daftar [:pick $daftar 0 ([:len $daftar] - 2)]
    :local teks ("Reminder tagihan H-1 (" . $jml . ")\\nJatuh tempo besok, tgl " . $besok . ":\\n" . $daftar)
    :do {
        /tool fetch keep-result=no http-method=post \
            http-header-field="Content-Type: application/json" \
            url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
            http-data=("{\"chat_id\":\"" . $chatId . "\",\"text\":\"" . $teks . "\"}")
    } on-error={ :log warning "billing-scheduler: gagal kirim Telegram" }
}
