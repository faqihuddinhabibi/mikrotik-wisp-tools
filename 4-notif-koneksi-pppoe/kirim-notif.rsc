# ============================================================
#  Kirim Notif Koneksi (batch) -> Telegram
#  Pasang sebagai /system script, jalankan via scheduler
#  (mis. tiap 30 detik).
#
#  Cara kerja:
#   - Ambil daftar user yang BARU berubah (dari antrian on-up/on-down).
#   - Untuk tiap user itu, cek STATUS SAAT INI (masih online / offline).
#   - Kirim 1 pesan: UP (x): ... / DOWN (y): ...
#   Jadi teknisi tahu kondisi terkini, bukan cuma "ada kejadian".
#
#   - Antrian kosong -> tidak kirim apa-apa (ringan).
#   - 1 pesan per interval -> aman dari rate-limit.
#   - Hanya user yang BERUBAH yang dicek -> tetap ringan walau ratusan user.
# ============================================================

# ---- GANTI dua baris ini ----
:local botToken "ISI_TOKEN_BOT"
:local chatId   "ISI_CHAT_ID"
# -----------------------------

:global pppNotifUp
:global pppNotifDown

# gabung antrian up+down, lalu langsung kosongkan
:local q ""
:if ([:typeof $pppNotifUp] != "nothing")   do={ :set q ($q . $pppNotifUp) }
:if ([:typeof $pppNotifDown] != "nothing") do={ :set q ($q . $pppNotifDown) }
:set pppNotifUp ""
:set pppNotifDown ""

:if ([:len $q] > 0) do={
    :local up ""
    :local down ""
    :local nUp 0
    :local nDown 0
    :local seen ""

    # pisah nama (dipisah ", "), buang duplikat, cek status terkini
    :local rest $q
    :while ([:len $rest] > 0) do={
        :local p [:find $rest ", "]
        :local nm ""
        :if ([:typeof $p] = "num") do={
            :set nm [:pick $rest 0 $p]
            :set rest [:pick $rest ($p + 2) [:len $rest]]
        } else={
            :set nm $rest
            :set rest ""
        }
        :if (([:len $nm] > 0) && ([:typeof [:find $seen ("," . $nm . ",")]] = "nothing")) do={
            :set seen ($seen . "," . $nm . ",")
            :if ([:len [/ppp active find where name=$nm]] > 0) do={
                :set up ($up . $nm . ", ")
                :set nUp ($nUp + 1)
            } else={
                :set down ($down . $nm . ", ")
                :set nDown ($nDown + 1)
            }
        }
    }

    :if ([:len $up] > 0)   do={ :set up   [:pick $up 0 ([:len $up] - 2)] }     else={ :set up "-" }
    :if ([:len $down] > 0) do={ :set down [:pick $down 0 ([:len $down] - 2)] } else={ :set down "-" }
    :local waktu "$[/system clock get date] $[/system clock get time]"

    # ---- TEMPLATE PESAN (boleh diubah) ----
    :local teks ("📡 Update Koneksi\\n" . $waktu . "\\n\\n" . \
                 "✅ UP (" . $nUp . "): " . $up . "\\n" . \
                 "❌ DOWN (" . $nDown . "): " . $down)
    # ---------------------------------------

    :do {
        /tool fetch keep-result=no http-method=post \
            http-header-field="Content-Type: application/json" \
            url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
            http-data=("{\"chat_id\":\"" . $chatId . "\",\"text\":\"" . $teks . "\"}")
    } on-error={}
}
