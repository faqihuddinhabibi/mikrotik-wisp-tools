# 01 — Notifikasi Perubahan Profile PPPoE ke Telegram

Kirim pesan Telegram **otomatis** setiap kali kolom **profile** di sebuah
`/ppp secret` berubah (contoh: dari `aktif` ke `isolir`, atau sebaliknya).

## Kenapa harus scheduler (bukan event/on-change)?

RouterOS **tidak punya trigger** untuk "secret diedit". Yang ada hanya:

- `on-up` / `on-down` di menu `/ppp profile` → jalan saat user **connect / disconnect**.
- **Tidak ada** hook saat kamu mengganti field `profile` di sebuah secret.

Jadi cara satu-satunya: **polling** — script mengecek berkala (tiap 1 menit),
menyimpan profile terakhir yang diketahui, lalu membandingkan. Kalau beda → kirim Telegram.

## Di mana state disimpan?

Di **global variable** (RAM), bukan di comment. Alasannya:

- Comment dipakai untuk data billing (`DUE:`) di folder 02 — biar tidak tabrakan.
- Comment tetap bersih & bisa kamu pakai untuk catatan pelanggan.

Efek samping: setelah **reboot router**, state kosong. Saat script jalan pertama kali
sesudah reboot, dia hanya **mencatat ulang** profile semua user (tidak mengirim notif).
Ini disengaja supaya **tidak spam** saat boot. Perubahan berikutnya baru dikirim.

---

## Langkah pasang

### 1. Buat bot Telegram & ambil token
1. Chat [@BotFather](https://t.me/BotFather) di Telegram → `/newbot` → ikuti sampai dapat **token**
   (bentuknya `123456789:AAExxxxxxxxxxxxxxxxxxxxxxxxxx`).
2. Ambil **chat_id** tujuan:
   - Kirim satu pesan ke bot barumu.
   - Buka `https://api.telegram.org/bot<TOKEN>/getUpdates` di browser.
   - Cari `"chat":{"id":<ANGKA>...}` → itu **chat_id** kamu.
   - Untuk grup: tambahkan bot ke grup, kirim pesan, chat_id grup biasanya diawali `-`.

### 2. Pastikan router bisa akses internet & DNS
```rsc
/ip dns set servers=1.1.1.1,8.8.8.8
:put [/tool fetch url="https://api.telegram.org" keep-result=no as-value]
```
Kalau fetch error soal sertifikat, lihat bagian **Troubleshooting** di bawah.

### 3. Pasang script
Buka **System → Scripts** di Winbox, **Add**, beri nama `pppoe-profile-watch`,
paste isi file [`pppoe-profile-watch.rsc`](pppoe-profile-watch.rsc).

**Ganti dua baris ini** di atas script:
```rsc
:local botToken "GANTI_BOT_TOKEN"
:local chatId   "GANTI_CHAT_ID"
```

Atau lewat terminal — jalankan isi file, atau import:
```rsc
# upload file ke router (drag-drop di Files), lalu:
/import file-name=pppoe-profile-watch.rsc
```

### 4. Pasang scheduler (jalan tiap 1 menit)
```rsc
/system scheduler
add name=pppoe-profile-watch interval=1m on-event="/system script run pppoe-profile-watch" \
    comment="Cek perubahan profile PPPoE -> Telegram"
```

### 5. Tes
- Ganti profile salah satu user di `/ppp secret` (misal `aktif` → `isolir`).
- Tunggu ≤ 1 menit → pesan masuk Telegram.

---

## Isi pesan Telegram

```
PPPoE profile berubah
User: budi
Dari: aktif
Jadi: isolir
```

Notif juga sudah menyertakan jam (dari Telegram sendiri). Mau tambah info lain
(paket, IP, dsb)? Tinggal ubah variabel `teks` di script.

---

## Troubleshooting

| Masalah | Penyebab / solusi |
|---------|-------------------|
| Tidak ada pesan sama sekali | Cek `botToken` & `chatId`. Uji manual: `/tool fetch url="https://api.telegram.org/bot<TOKEN>/getMe" keep-result=no as-value` |
| `fetch failed` / SSL error | Set DNS dulu. Kalau tetap gagal SSL, jalankan sekali: `/tool fetch url="https://api.telegram.org/botTOKEN/getMe" keep-result=no check-certificate=no` — untuk produksi sebaiknya install CA (lihat catatan). |
| Spam notif tiap menit untuk user sama | Jangan hapus/rename script tiap jalan. Global state harus persist antar-run (sudah otomatis). |
| Setelah reboot tidak ada notif untuk perubahan lama | Normal — state di RAM. Baseline ulang saat boot, tidak dikirim. |
| Nama user ada tanda kutip `"` | Bisa merusak JSON. Hindari `"` di nama secret. |

### Catatan sertifikat (opsional, biar aman)
`check-certificate=no` mematikan verifikasi TLS. Untuk lebih aman, import CA:
```rsc
/tool fetch url="https://curl.se/ca/cacert.pem" dst-path=cacert.pem
/certificate import file-name=cacert.pem passphrase=""
```
Lalu fetch bisa jalan dengan `check-certificate=yes-without-crl`.

---

## Uninstall
```rsc
/system scheduler remove [find name=pppoe-profile-watch]
/system script remove [find name=pppoe-profile-watch]
# hapus global state:
:global pppoeProfileState; :set pppoeProfileState
```
