# Billing scheduler: isi address-list "tagihan-reminder" utk user H-1 (baca DUE: dari comment)

# ---- opsional Telegram (kosongkan botToken utk mematikan) ----
:local botToken ""
:local chatId   ""
# daftar user yg TIDAK direminder (dipisah koma, diapit koma). Contoh: ",kantor-desa,sekolah,"
:local excludeNames ",,"
# -------------------------------------------------------------

:local tgl [/system clock get date]
:local today [:tonum [:pick $tgl 8 10]]

/ip firewall address-list remove [find list="tagihan-reminder"]

:foreach a in=[/ppp active find] do={
    :local nama [/ppp active get $a name]
    :local ip   [/ppp active get $a address]
    :local sid [/ppp secret find name=$nama]
    :if ([:len $sid] > 0) do={
        :local cmt [/ppp secret get $sid comment]
        :local dikecualikan false
        :if ([:typeof [:find $cmt "SKIP"]] = "num") do={ :set dikecualikan true }
        :if ([:typeof [:find $excludeNames ("," . $nama . ",")]] = "num") do={ :set dikecualikan true }
        :local p [:find $cmt "DUE:"]
        :if ([:typeof $p] = "num") do={
            :local rest [:pick $cmt ($p + 4) [:len $cmt]]
            :local rlen [:len $rest]
            :local dstr ""
            :local i 0
            :local stop false
            :while (($i < $rlen) && (!$stop)) do={
                :local c [:pick $rest $i ($i + 1)]
                :if (($c >= "0") && ($c <= "9")) do={
                    :set dstr ($dstr . $c); :set i ($i + 1)
                } else={
                    :if (($c = " ") && ($dstr = "")) do={ :set i ($i + 1) } else={ :set stop true }
                }
            }
            :if ([:len $dstr] > 0) do={
                :local due [:tonum $dstr]
                :if (($due = ($today + 1)) && (!$dikecualikan)) do={
                    /ip firewall address-list add list="tagihan-reminder" address=$ip comment=$nama timeout=2h
                    :if ([:len $botToken] > 0) do={
                        :local teks ("Pengingat tagihan\\nUser: " . $nama . "\\nJatuh tempo: BESOK (tgl " . $due . ")")
                        :do {
                            /tool fetch keep-result=no http-method=post \
                                http-header-field="Content-Type: application/json" \
                                url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
                                http-data=("{\"chat_id\":\"" . $chatId . "\",\"text\":\"" . $teks . "\"}")
                        } on-error={}
                    }
                }
            }
        }
    }
}
