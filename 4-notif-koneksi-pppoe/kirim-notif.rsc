# ============================================================
#  Kirim Notif Koneksi (batch) -> Telegram
#  Pasang sebagai /system script, jalankan via scheduler
#  (mis. tiap 30 detik). Mengirim RINGKASAN pelanggan yang
#  connect/disconnect sejak cek terakhir dalam 1 pesan.
#
#  - Kalau antrian kosong -> tidak melakukan apa-apa (ringan).
#  - Hanya 1 pesan per interval -> aman dari rate-limit Telegram.
#  - Andal: fetch jalan di konteks sistem (bukan sesi yang mati).
# ============================================================

# ---- GANTI dua baris ini ----
:local botToken "ISI_TOKEN_BOT"
:local chatId   "ISI_CHAT_ID"
# -----------------------------

:global pppNotifUp
:global pppNotifDown

# ambil isi antrian, lalu langsung kosongkan (biar event baru tidak hilang)
:local up ""
:local down ""
:if ([:typeof $pppNotifUp] != "nothing") do={ :set up $pppNotifUp }
:if ([:typeof $pppNotifDown] != "nothing") do={ :set down $pppNotifDown }
:set pppNotifUp ""
:set pppNotifDown ""

# kirim hanya kalau ada isinya
:if (([:len $up] > 0) || ([:len $down] > 0)) do={
    :local waktu "$[/system clock get date] $[/system clock get time]"
    :if ([:len $up] > 0)   do={ :set up   [:pick $up 0 ([:len $up] - 2)] }     else={ :set up "-" }
    :if ([:len $down] > 0) do={ :set down [:pick $down 0 ([:len $down] - 2)] } else={ :set down "-" }

    # ---- TEMPLATE PESAN (boleh diubah) ----
    :local teks ("📡 Update Koneksi\\n" . $waktu . "\\n\\n" . \
                 "✅ UP: " . $up . "\\n" . \
                 "❌ DOWN: " . $down)
    # ---------------------------------------

    :do {
        /tool fetch keep-result=no http-method=post \
            http-header-field="Content-Type: application/json" \
            url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
            http-data=("{\"chat_id\":\"" . $chatId . "\",\"text\":\"" . $teks . "\"}")
    } on-error={}
}
