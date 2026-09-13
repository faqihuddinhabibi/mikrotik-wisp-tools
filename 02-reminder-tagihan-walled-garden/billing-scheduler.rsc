# ============================================================
#  Billing Scheduler — isi address-list "tagihan-reminder"
#  Baca tanggal jatuh tempo (DUE:NN) dari comment tiap
#  /ppp secret. Kalau BESOK jatuh tempo (H-1),
#  masukkan IP user yang sedang online ke address-list
#  "tagihan-reminder" -> otomatis kena redirect walled-garden.
#  (Hari-H sengaja dilewati: yang sudah bayar tidak terganggu.)
#
#  Target : RouterOS 7.24.2 (x86)
#  Jalan  : scheduler tiap 1 jam (granularitas billing = harian)
#
#  Format comment secret (contoh):
#     Budi RT03 - 20Mbps | DUE:15
#  -> jatuh tempo tanggal 15. Pakai tanggal 1-28 saja.
#
#  Opsional: kirim Telegram H-1 (isi TOKEN & CHATID).
# ============================================================

# ---- opsional Telegram (kosongkan botToken utk mematikan) ----
:local botToken ""
:local chatId   ""
# --------------------------------------------------------------

# ---- daftar user yang TIDAK pernah direminder ----
# Cara ini alternatif dari tag "SKIP" di comment: cukup tulis nama
# persis (sama seperti di /ppp secret), dipisah koma, DIAPIT koma
# di awal & akhir. Kosongkan (",,") kalau tidak dipakai.
# Contoh: ",kantor-desa,sekolah-01,puskesmas,"
:local excludeNames ",,"
# --------------------------------------------------------------

# tanggal hari ini (RouterOS 7: format YYYY-MM-DD)
:local tgl [/system clock get date]
:local today [:tonum [:pick $tgl 8 10]]

# bersihkan daftar yang dikelola script ini
/ip firewall address-list remove [find list="tagihan-reminder"]

:foreach a in=[/ppp active find] do={
    :local nama [/ppp active get $a name]
    :local ip   [/ppp active get $a address]

    :local sid [/ppp secret find name=$nama]
    :if ([:len $sid] > 0) do={
        :local cmt [/ppp secret get $sid comment]

        # PENGECUALIAN (2 cara, salah satu cukup):
        #  a) comment mengandung kata "SKIP"
        #  b) nama user terdaftar di excludeNames di atas
        :local dikecualikan false
        :if ([:typeof [:find $cmt "SKIP"]] = "num") do={ :set dikecualikan true }
        :if ([:typeof [:find $excludeNames ("," . $nama . ",")]] = "num") do={ :set dikecualikan true }

        # cari token "DUE:" lalu ambil angka setelahnya
        :local key "DUE:"
        :local p [:find $cmt $key]
        :if ([:typeof $p] = "num") do={
            :local rest [:pick $cmt ($p + [:len $key]) [:len $cmt]]
            :local rlen [:len $rest]
            :local dstr ""
            :local i 0
            :local stop false
            :while (($i < $rlen) && (!$stop)) do={
                :local c [:pick $rest $i ($i + 1)]
                :if (($c >= "0") && ($c <= "9")) do={
                    :set dstr ($dstr . $c)
                    :set i ($i + 1)
                } else={
                    # toleran spasi sebelum angka (mis. "DUE: 15")
                    :if (($c = " ") && ($dstr = "")) do={
                        :set i ($i + 1)
                    } else={
                        :set stop true
                    }
                }
            }

            :if ([:len $dstr] > 0) do={
                :local due [:tonum $dstr]
                :local kena false
                :local kapan ""

                # HANYA H-1 (besok jatuh tempo). Hari-H sengaja dilewati
                # supaya pelanggan yang sudah bayar tidak terganggu.
                :if ($due = ($today + 1)) do={ :set kena true; :set kapan "BESOK" }

                :if ($kena && (!$dikecualikan)) do={
                    # timeout 2 jam: kalau user bayar & dihapus manual, tetap auto-bersih.
                    # Scheduler jam berikutnya akan menambah lagi bila masih jatuh tempo.
                    /ip firewall address-list add list="tagihan-reminder" \
                        address=$ip comment=$nama timeout=2h

                    :log info ("billing: " . $nama . " jatuh tempo " . $kapan . " (ip " . $ip . ")")

                    # opsional Telegram
                    :if ([:len $botToken] > 0) do={
                        :local teks ("Pengingat tagihan\\nUser: " . $nama . \
                                     "\\nJatuh tempo: " . $kapan . " (tgl " . $due . ")")
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
