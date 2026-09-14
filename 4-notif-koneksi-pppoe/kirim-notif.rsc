# ============================================================
#  Kirim Notif Koneksi (batch) -> Telegram
#  Pasang sebagai /system script, jalankan via scheduler
#  (mis. tiap 30 detik).
#
#  Cara kerja:
#   - Ambil user yang BARU berubah (dari antrian on-up/on-down).
#   - Angka "kedip" per user = BERAPA KALI PUTUS (disconnect) dalam
#     interval ini (1 putus + nyambung dihitung 1).
#   - Cek STATUS SAAT INI tiap user (online/offline) -> UP / DOWN.
#   - Tampilkan juga jumlah aktif vs total PPPoE.
#   - Kirim 1 pesan.
#
#   - Antrian kosong -> tidak kirim apa-apa (ringan).
#   - 1 pesan per interval -> aman dari rate-limit.
#   - Hanya user yang berubah yang dicek -> tetap ringan.
# ============================================================

# ---- GANTI dua baris ini ----
:local botToken "ISI_TOKEN_BOT"
:local chatId   "ISI_CHAT_ID"
# -----------------------------

:global pppNotifUp
:global pppNotifDown

# ambil antrian up & down (terpisah), lalu kosongkan
:local upq ""
:local downq ""
:if ([:typeof $pppNotifUp] != "nothing")   do={ :set upq $pppNotifUp }
:if ([:typeof $pppNotifDown] != "nothing") do={ :set downq $pppNotifDown }
:set pppNotifUp ""
:set pppNotifDown ""

:if (([:len $upq] > 0) || ([:len $downq] > 0)) do={
    :local kedip   [:toarray ""]   ;# nama -> jumlah disconnect (kedip)
    :local changed [:toarray ""]   ;# nama -> 1 (gabungan up+down)

    # parse antrian DOWN: hitung kedip + tandai berubah
    :local rest $downq
    :while ([:len $rest] > 0) do={
        :local p [:find $rest ", "]
        :local nm ""
        :if ([:typeof $p] = "num") do={ :set nm [:pick $rest 0 $p]; :set rest [:pick $rest ($p + 2) [:len $rest]] } else={ :set nm $rest; :set rest "" }
        :if ([:len $nm] > 0) do={
            :local c ($kedip->$nm)
            :if ([:typeof $c] = "nothing") do={ :set c 0 }
            :set ($kedip->$nm) ($c + 1)
            :set ($changed->$nm) 1
        }
    }
    # parse antrian UP: cukup tandai berubah (tidak menambah kedip)
    :set rest $upq
    :while ([:len $rest] > 0) do={
        :local p [:find $rest ", "]
        :local nm ""
        :if ([:typeof $p] = "num") do={ :set nm [:pick $rest 0 $p]; :set rest [:pick $rest ($p + 2) [:len $rest]] } else={ :set nm $rest; :set rest "" }
        :if ([:len $nm] > 0) do={ :set ($changed->$nm) 1 }
    }

    # kelompokkan per status terkini. Batasi jumlah nama (hindari 4096 char),
    # sisanya diringkas "… +X lagi". Angka total (nUp/nDown) tetap akurat.
    :local maxList 30
    :local up ""
    :local down ""
    :local nUp 0
    :local nDown 0
    :local lUp 0
    :local lDown 0
    :foreach nm,x in=$changed do={
        :local kd ($kedip->$nm)
        :if ([:typeof $kd] = "nothing") do={ :set kd 0 }
        :if ([:len [/ppp active find where name=$nm]] > 0) do={
            :set nUp ($nUp + 1)
            :if ($lUp < $maxList) do={ :set up ($up . $nm . " (" . $kd . "), "); :set lUp ($lUp + 1) }
        } else={
            :set nDown ($nDown + 1)
            :if ($lDown < $maxList) do={ :set down ($down . $nm . " (" . $kd . "), "); :set lDown ($lDown + 1) }
        }
    }
    :if ([:len $up] > 0)   do={ :set up   [:pick $up 0 ([:len $up] - 2)] }     else={ :set up "-" }
    :if ([:len $down] > 0) do={ :set down [:pick $down 0 ([:len $down] - 2)] } else={ :set down "-" }
    :if ($nUp > $lUp)     do={ :set up   ($up . " … +" . ($nUp - $lUp) . " lagi") }
    :if ($nDown > $lDown) do={ :set down ($down . " … +" . ($nDown - $lDown) . " lagi") }

    :local total [/ppp secret print count]
    :local aktif [/ppp active print count]
    :local waktu "$[/system clock get date] $[/system clock get time]"

    # ---- TEMPLATE PESAN (boleh diubah; format HTML Telegram) ----
    # CATATAN: karena pakai parse_mode HTML (untuk bold), username PPPoE JANGAN
    # mengandung karakter < > & (bisa bikin SELURUH pesan ditolak Telegram).
    # Kalau ada, hapus <b>/</b> dan hapus \"parse_mode\":\"HTML\", (jadi teks biasa).
    :local teks ("<b>Update Koneksi</b>\\n" . $waktu . "\\n" . \
                 "Aktif: " . $aktif . "/" . $total . "\\n\\n" . \
                 "🟢 <b>UP</b> (" . $nUp . "): " . $up . "\\n" . \
                 "🔴 <b>DOWN</b> (" . $nDown . "): " . $down)
    # ------------------------------------------------------------

    :do {
        /tool fetch keep-result=no http-method=post \
            http-header-field="Content-Type: application/json" \
            url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
            http-data=("{\"chat_id\":\"" . $chatId . "\",\"parse_mode\":\"HTML\",\"text\":\"" . $teks . "\"}")
    } on-error={}
}
