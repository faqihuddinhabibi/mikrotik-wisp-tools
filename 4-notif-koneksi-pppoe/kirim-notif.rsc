# ============================================================
#  Kirim Notif Koneksi (batch) -> Telegram
#  Pasang sebagai /system script, jalankan via scheduler
#  (mis. tiap 30 detik).
#
#  Cara kerja:
#   - Ambil user yang BARU berubah (dari antrian on-up/on-down),
#     hitung "berapa kali kedip" tiap user dalam interval ini.
#   - Cek STATUS SAAT INI tiap user itu (online/offline),
#     kelompokkan ke UP / DOWN.
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

# gabung antrian up+down (mentah, dengan pengulangan), lalu kosongkan
:local q ""
:if ([:typeof $pppNotifUp] != "nothing")   do={ :set q ($q . $pppNotifUp) }
:if ([:typeof $pppNotifDown] != "nothing") do={ :set q ($q . $pppNotifDown) }
:set pppNotifUp ""
:set pppNotifDown ""

:if ([:len $q] > 0) do={
    # hitung jumlah kejadian per nama
    :local cnt [:toarray ""]
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
        :if ([:len $nm] > 0) do={
            :local c ($cnt->$nm)
            :if ([:typeof $c] = "nothing") do={ :set c 0 }
            :set ($cnt->$nm) ($c + 1)
        }
    }

    # kelompokkan per status terkini, sertakan jumlah kedip.
    # Batasi jumlah nama yang ditulis (hindari batas 4096 karakter Telegram);
    # sisanya diringkas jadi "… +X lagi". Angka total (nUp/nDown) tetap akurat.
    :local maxList 30
    :local up ""
    :local down ""
    :local nUp 0
    :local nDown 0
    :local lUp 0
    :local lDown 0
    :foreach nm,c in=$cnt do={
        :if ([:len [/ppp active find where name=$nm]] > 0) do={
            :set nUp ($nUp + 1)
            :if ($lUp < $maxList) do={ :set up ($up . $nm . " (" . $c . "), "); :set lUp ($lUp + 1) }
        } else={
            :set nDown ($nDown + 1)
            :if ($lDown < $maxList) do={ :set down ($down . $nm . " (" . $c . "), "); :set lDown ($lDown + 1) }
        }
    }
    :if ([:len $up] > 0)   do={ :set up   [:pick $up 0 ([:len $up] - 2)] }     else={ :set up "-" }
    :if ([:len $down] > 0) do={ :set down [:pick $down 0 ([:len $down] - 2)] } else={ :set down "-" }
    :if ($nUp > $lUp)     do={ :set up   ($up . " … +" . ($nUp - $lUp) . " lagi") }
    :if ($nDown > $lDown) do={ :set down ($down . " … +" . ($nDown - $lDown) . " lagi") }

    :local total [/ppp secret print count]
    :local aktif [/ppp active print count]
    :local waktu "$[/system clock get date] $[/system clock get time]"

    # ---- TEMPLATE PESAN (boleh diubah; pakai format HTML Telegram) ----
    # CATATAN: karena pakai parse_mode HTML (untuk bold), username PPPoE JANGAN
    # mengandung karakter < > & (bisa bikin SELURUH pesan ditolak Telegram).
    # Kalau ada username begitu, matikan format: hapus <b> & </b> di bawah, dan
    # hapus bagian \"parse_mode\":\"HTML\", pada http-data (jadi teks biasa).
    :local teks ("<b>Update Koneksi</b>\\n" . $waktu . "\\n" . \
                 "Aktif: " . $aktif . "/" . $total . "\\n\\n" . \
                 "🟢 <b>UP</b> (" . $nUp . "): " . $up . "\\n" . \
                 "🔴 <b>DOWN</b> (" . $nDown . "): " . $down)
    # ------------------------------------------------------------------

    :do {
        /tool fetch keep-result=no http-method=post \
            http-header-field="Content-Type: application/json" \
            url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
            http-data=("{\"chat_id\":\"" . $chatId . "\",\"parse_mode\":\"HTML\",\"text\":\"" . $teks . "\"}")
    } on-error={}
}
