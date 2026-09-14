# 1 · Notifikasi Perubahan Profil PPPoE → Telegram

Kirim pesan **Telegram otomatis** saat:
1. **Profil** pelanggan diubah (contoh: dari `AKTIF` ke `ISOLIR`, atau sebaliknya), dan
2. Ada **PPPoE baru** (secret pelanggan baru dibuat).

Cocok untuk pemilik jaringan yang ingin **tahu setiap kali teknisi mengganti
profil atau menambah pelanggan** — tanpa harus mengecek router satu per satu.

---

## Daftar isi
- [Apa gunanya?](#apa-gunanya)
- [Bagaimana cara kerjanya?](#bagaimana-cara-kerjanya)
- [Yang perlu disiapkan](#yang-perlu-disiapkan)
- [Langkah 1 — Buat bot Telegram](#langkah-1--buat-bot-telegram)
- [Langkah 2 — Dapatkan Chat ID](#langkah-2--dapatkan-chat-id)
- [Langkah 3 — Pasang script di MikroTik](#langkah-3--pasang-script-di-mikrotik)
- [Langkah 4 — Pasang scheduler (penjadwal)](#langkah-4--pasang-scheduler-penjadwal)
- [Langkah 5 — Uji coba](#langkah-5--uji-coba)
- [Mengubah isi pesan / kecepatan cek](#mengubah-isi-pesan--kecepatan-cek)
- [Kalau ada masalah](#kalau-ada-masalah)
- [Cara mencopot](#cara-mencopot)

---

## Apa gunanya?

- **Tahu saat profil pelanggan berubah.** Misal teknisi meng-isolir pelanggan
  atau mengaktifkannya kembali — Anda langsung dapat pesan Telegram.
- **Tahu saat ada pelanggan baru.** Setiap secret PPPoE baru dibuat → notif "PPPoE BARU".
- **Bukti/jejak.** Setiap perubahan tercatat dengan waktu (dari Telegram).
- **Ringan.** Tidak butuh aplikasi tambahan, tidak butuh server, tidak butuh
  container. Semua berjalan di dalam MikroTik.

> Ini **berbeda** dari script "user connect/disconnect" (Alat 4). Yang ini mendeteksi
> **perubahan profil & pelanggan baru** di `/ppp secret`, bukan koneksi naik/turun.

---

## Bagaimana cara kerjanya?

RouterOS **tidak punya "alarm" bawaan** yang berbunyi saat profil sebuah secret
diedit atau saat secret baru dibuat. Jadi script ini bekerja dengan cara
**mengecek berkala** (penjadwal, mis. tiap 30 menit):

1. Setiap cek, script membaca profil semua pelanggan.
2. Ia menyimpan "profil terakhir yang diketahui" di memori (RAM).
3. Kalau ada profil yang **berbeda** dari cek sebelumnya → kirim **"profil berubah"**.
4. Kalau ada **nama baru** yang belum pernah tercatat → kirim **"PPPoE BARU"**.

Konsekuensinya: perubahan bisa telat diberitahu **maksimal 1 interval** (mis. 30
menit; bisa dipercepat, lihat bagian kustomisasi). Setelah router **restart**,
daftar di memori kosong; saat cek pertama sesudah restart script hanya **mencatat
ulang semua** (tidak mengirim apa pun), supaya tidak spam ratusan "baru".

---

## Yang perlu disiapkan

- Akses ke MikroTik (Winbox atau WebFig).
- Aplikasi **Telegram** di HP.
- Router bisa akses internet (untuk mengirim ke Telegram).

---

## Langkah 1 — Buat bot Telegram

1. Buka Telegram, cari **@BotFather**, mulai chat.
2. Ketik `/newbot` lalu ikuti: beri **nama** dan **username** bot (username harus
   diakhiri `bot`, mis. `tagihan_musuk_bot`).
3. BotFather memberi **token**, bentuknya seperti:
   `123456789:AAExxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
   **Simpan token ini.** (Rahasia — jangan sebar.)

---

## Langkah 2 — Dapatkan Chat ID

Chat ID = alamat tujuan pesan (bisa chat pribadi atau grup).

**Untuk chat pribadi:**
1. Kirim satu pesan apa saja ke bot Anda.
2. Buka di browser (ganti `<TOKEN>`):
   `https://api.telegram.org/bot<TOKEN>/getUpdates`
3. Cari bagian `"chat":{"id":123456789,...}` → angka itu **Chat ID** Anda.

**Untuk grup:**
1. Tambahkan bot ke grup, kirim satu pesan di grup.
2. Buka URL `getUpdates` yang sama.
3. Chat ID grup biasanya diawali tanda minus, mis. `-4830124543`.

---

## Langkah 3 — Pasang script di MikroTik

1. Buka **Winbox** → menu kiri **System → Scripts** → tombol **Add** (`+`).
2. **Name:** `pppoe-profile-watch`
3. **Source:** salin seluruh isi file [`pppoe-profile-watch.rsc`](pppoe-profile-watch.rsc).
4. Di bagian atas script, **ganti dua baris ini** dengan milik Anda:
   ```rsc
   :local botToken "ISI_TOKEN_BOT"
   :local chatId   "ISI_CHAT_ID"
   ```
5. Klik **OK** untuk menyimpan.

> Alternatif via terminal: upload file `.rsc` ke menu **Files** (drag-drop), lalu
> di **New Terminal** ketik `/import file-name=pppoe-profile-watch.rsc`.

---

## Langkah 4 — Pasang scheduler (penjadwal)

Agar script jalan otomatis tiap 30 menit. Buka **New Terminal**, tempel (1 baris):

```rsc
/system scheduler add name=pppoe-profile-watch interval=30m on-event="/system script run pppoe-profile-watch" comment="Cek perubahan profil PPPoE -> Telegram"
```

---

## Langkah 5 — Uji coba

1. Jalankan sekali manual (untuk "mencatat" kondisi awal):
   ```rsc
   /system script run pppoe-profile-watch
   ```
2. Ubah profil salah satu pelanggan di **PPP → Secrets** (mis. dari `AKTIF` ke `ISOLIR`).
3. Jalankan lagi:
   ```rsc
   /system script run pppoe-profile-watch
   ```
4. Pesan seperti ini harus masuk Telegram:
   ```
   PPPoE profile berubah
   User: budi
   Dari: AKTIF
   Jadi: ISOLIR
   ```
Kalau muncul → berhasil. Selanjutnya berjalan otomatis tiap jam.

---

## Contoh pesan & cara mengubah templatenya

**Bentuk pesan bawaan** yang masuk ke Telegram:

Saat profil berubah:
```
PPPoE profile berubah
User: budi
Dari: AKTIF
Jadi: ISOLIR
```
Saat ada pelanggan baru:
```
PPPoE BARU
User: siti
Profile: PAKET100
```

**Bagian yang mengatur teks itu** ada di dalam `pppoe-profile-watch.rsc`, di baris ini:
```rsc
:local teks ("PPPoE profile berubah\\nUser: " . $nama . \
             "\\nDari: " . $old . "\\nJadi: " . $prof)
```
Aturannya:
- Tulisan di dalam tanda kutip `"..."` = teks tetap (boleh Anda ganti).
- `\\n` = ganti baris (enter).
- `$nama`, `$old`, `$prof` = data yang diisi otomatis (nama user, profil lama, profil baru).
- Tanda `. ` menyambung potongan teks.

**Contoh mengganti template** — misalnya versi lebih ramah:
```rsc
:local teks ("⚠️ Perubahan Profil Pelanggan\\n\\n" . \
             "Nama   : " . $nama . "\\n" . \
             "Semula : " . $old . "\\n" . \
             "Menjadi: " . $prof)
```
Hasilnya:
```
⚠️ Perubahan Profil Pelanggan

Nama   : budi
Semula : AKTIF
Menjadi: ISOLIR
```

**Data lain yang bisa ditambahkan** (baca dari secret pakai `$s`), contoh:
```rsc
:local paket [/ppp secret get $s comment]     ;# isi comment (mis. paket/tanggal)
:local svc   [/ppp secret get $s service]      ;# tipe layanan (pppoe, dst)
```
lalu sisipkan ke `teks`, mis. `. "\\nPaket: " . $paket`.

> Jangan pakai tanda kutip `"` di dalam teks template — itu bisa merusak format
> pengiriman. Gunakan kata biasa & `\\n` untuk baris baru.

## Mengubah kecepatan cek
Ganti `interval=30m` jadi `interval=5m` (5 menit) di scheduler kalau ingin lebih
cepat. Makin sering = makin banyak kerja router (untuk perubahan profil, 1 jam
biasanya sudah cukup).

---

## Kalau ada masalah

| Gejala | Penyebab / solusi |
|--------|-------------------|
| Tidak ada pesan sama sekali | Cek `botToken` & `chatId` benar. Tes kirim manual (lihat di bawah). |
| `fetch failed` / error SSL | Set DNS dulu: `/ip dns set servers=1.1.1.1,8.8.8.8`. Kalau masih error sertifikat, lihat catatan CA di bawah. |
| Spam pesan tiap jam untuk user sama | Jangan hapus/rename script tiap kali jalan; biarkan berjalan normal. |
| Setelah router restart tidak ada notif untuk perubahan lama | Normal — daftar di RAM dicatat ulang saat pertama, tidak dikirim. |
| Nama user mengandung tanda kutip `"` | Bisa merusak format pesan. Hindari `"` pada nama secret. |

**Tes kirim manual** (ganti TOKEN & CHATID):
```rsc
/tool fetch keep-result=no http-method=post \
    http-header-field="Content-Type: application/json" \
    url="https://api.telegram.org/bot<TOKEN>/sendMessage" \
    http-data="{\"chat_id\":\"<CHATID>\",\"text\":\"tes\"}"
```
Kalau "tes" masuk Telegram → token & chat id benar.

**Catatan sertifikat (opsional):** kalau fetch gagal soal TLS, impor CA sekali:
```rsc
/tool fetch url="https://curl.se/ca/cacert.pem" dst-path=cacert.pem
/certificate import file-name=cacert.pem passphrase=""
```

---

## Cara update (kalau script diperbarui)

Script yang jalan itu **yang tersimpan di router** (di System → Scripts), bukan file
di GitHub. File GitHub cuma sumber/salinan. Jadi untuk memperbarui:

1. 🪟 Winbox → **System → Scripts** → **double-click** `pppoe-profile-watch`.
2. **Hapus** isi kolom **Source**, **paste** versi baru.
3. Isi lagi `botToken` & `chatId`, klik **OK**.

**Scheduler tidak perlu diubah** — dia cuma memanggil script berdasarkan nama.
Cukup update Source script-nya saja.

> Berlaku sama untuk semua alat: yang di-update cukup **isi script di router**
> (Source), bukan schedulernya. Kalau versi baru menambah variabel global baru
> (mis. `pppoeInit`), tidak perlu tindakan khusus — otomatis dibuat saat jalan.

---

## Cara mencopot
```rsc
/system scheduler remove [find name=pppoe-profile-watch]
/system script remove [find name=pppoe-profile-watch]
:global pppoeProfileState; :set pppoeProfileState
:global pppoeInit; :set pppoeInit
```
