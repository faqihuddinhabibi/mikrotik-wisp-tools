# 1 · Notifikasi Perubahan Profil PPPoE → Telegram

Kirim pesan **Telegram otomatis** saat:
1. **Profil** pelanggan diubah (contoh: dari `AKTIF` ke `ISOLIR`, atau sebaliknya),
2. Ada **PPPoE baru** (secret pelanggan baru dibuat), dan
3. Ada **PPPoE dihapus** (secret pelanggan dihapus).

Cocok untuk pemilik jaringan yang ingin **tahu setiap kali teknisi mengganti
profil, menambah, atau menghapus pelanggan** — tanpa harus mengecek router satu per satu.

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
- **Tahu saat pelanggan dihapus.** Setiap secret PPPoE dihapus → notif "PPPoE DIHAPUS".
- **Bukti/jejak.** Setiap perubahan tercatat dengan waktu (dari Telegram).
- **Ringan.** Tidak butuh aplikasi tambahan, tidak butuh server, tidak butuh
  container. Semua berjalan di dalam MikroTik.

> Ini mendeteksi **perubahan profil & pelanggan baru** di `/ppp secret`
> (mis. diisolir/diaktifkan), bukan koneksi naik/turun.

---

## Bagaimana cara kerjanya?

RouterOS **tidak punya "alarm" bawaan** yang berbunyi saat profil sebuah secret
diedit atau saat secret baru dibuat. Jadi script ini bekerja dengan cara
**mengecek berkala** (penjadwal, mis. tiap 30 menit):

1. Setiap cek, script membaca profil semua pelanggan.
2. Ia menyimpan "profil terakhir yang diketahui" di memori (RAM).
3. Kalau ada profil yang **berbeda** dari cek sebelumnya → dicatat **"berubah"**.
4. Kalau ada **nama baru** yang belum pernah tercatat → dicatat **"BARU"**.
5. Kalau ada nama yang **hilang** (tadinya tercatat, sekarang tidak ada) → dicatat **"DIHAPUS"**.
6. Semua catatan itu **digabung jadi 1 pesan Telegram** (kalau sangat panjang,
   dipecah beberapa pesan dengan jeda 3 detik). Tidak ada perubahan → tidak kirim.

Kenapa digabung? Telegram membatasi ~20 pesan/menit ke satu grup. Kalau teknisi
mengisolir 80 pelanggan sekaligus dan tiap pelanggan jadi 1 pesan, pesan ke-21 dst
akan **ditolak dan hilang**. Dengan digabung, 80 perubahan = 1–2 pesan saja.

**Kalau kirim gagal** (internet putus, Telegram error), daftar di memori **tidak
dimajukan** → di cek berikutnya perubahan yang sama dikirim lagi. Jadi notifikasi
**tidak pernah hilang**, paling telat. (Kalau gagalnya di pesan ke-2 dari pecahan,
pesan ke-1 bisa terkirim dua kali — wajar.)

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
3. Chat ID grup biasanya diawali tanda minus, mis. `-4001234567`.

---

## Langkah 3 — Pasang script di MikroTik

1. Buka **Winbox** → menu kiri **System → Scripts** → tombol **Add** (`+`).
2. **Name:** `pppoe-profile-watch`
3. **Source:** salin seluruh isi file [`pppoe-profile-watch.rsc`](pppoe-profile-watch.rsc).
4. Di bagian atas script, **ganti dua baris ini** dengan milik Anda:
   ```rsc
   :local botToken "GANTI_BOT_TOKEN"
   :local chatId   "GANTI_CHAT_ID"
   ```
   Contoh setelah diisi:
   ```rsc
   :local botToken "123456789:AAExxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
   :local chatId   "-4001234567"
   ```
5. Klik **OK** untuk menyimpan.

> ⚠️ Jangan pakai `/import file-name=...` untuk memasang script ini — `/import`
> hanya **menjalankan** isi file sekali, **tidak** membuat entri di System → Scripts,
> sehingga scheduler nanti tidak menemukan apa-apa. Tempel lewat Winbox seperti di atas.

---

## Langkah 4 — Pasang scheduler (penjadwal)

Agar script jalan otomatis tiap 30 menit. 🪟 **System → Scheduler → Add (+)**:
- **Name:** `pppoe-profile-watch`
- **Interval:** `00:30:00`
- **On Event:** `/system script run pppoe-profile-watch`
- **OK**.

> Alternatif via terminal (1 baris):
> `/system scheduler add name=pppoe-profile-watch interval=30m on-event="/system script run pppoe-profile-watch" comment="Cek perubahan profil PPPoE -> Telegram"`

---

## Langkah 5 — Uji coba

1. Jalankan sekali manual (untuk "mencatat" kondisi awal): 🪟 **System → Scripts**
   → klik `pppoe-profile-watch` → tombol **Run Script**.
2. Ubah profil salah satu pelanggan di **PPP → Secrets** (mis. dari `AKTIF` ke `ISOLIR`).
3. **Run Script** lagi.
4. Pesan seperti ini harus masuk Telegram:
   ```
   Perubahan PPPoE (1)
   budi: AKTIF -> ISOLIR
   ```
Kalau muncul → berhasil. Selanjutnya berjalan otomatis tiap 30 menit.

---

## Contoh pesan & cara mengubah templatenya

**Bentuk pesan bawaan** — semua perubahan dalam 1 cek digabung jadi 1 pesan:
```
Perubahan PPPoE (3)
budi: AKTIF -> ISOLIR
siti: BARU (PAKET100)
andi: DIHAPUS (ISOLIR)
```
- `nama: LAMA -> BARU` = profil berubah.
- `nama: BARU (profil)` = secret baru dibuat.
- `nama: DIHAPUS (profil terakhir)` = secret dihapus.
- Angka di judul = jumlah perubahan. Kalau daftarnya sangat panjang (>3500 huruf),
  dipecah jadi beberapa pesan; pesan lanjutan berjudul `(lanjutan)`.

**Bagian yang mengatur teks itu** ada di `pppoe-profile-watch.rsc`, tiga baris `:set baris (...)`:
```rsc
:set baris ($baris . [$bersih $nama] . ": BARU (" . [$bersih $prof] . ")\\n")
:set baris ($baris . [$bersih $nama] . ": " . [$bersih $old] . " -> " . [$bersih $prof] . "\\n")
:set baris ($baris . [$bersih $nm] . ": DIHAPUS (" . [$bersih $pr] . ")\\n")
```
dan judulnya di baris `"Perubahan PPPoE (" . $jml . ")\\n"`.

Aturannya:
- Tulisan di dalam tanda kutip `"..."` = teks tetap (boleh Anda ganti).
- `\\n` = ganti baris (enter). **Tiap baris perubahan harus diakhiri `\\n`** — itu
  yang dipakai untuk memecah pesan panjang.
- `[$bersih $nama]` = nama user (sudah dibersihkan dari tanda `"` dan `\` supaya
  pesan tidak rusak). `$old` = profil lama, `$prof` = profil baru.
- Tanda `. ` menyambung potongan teks.

**Contoh mengganti template** — versi lebih panjang untuk baris "berubah":
```rsc
:set baris ($baris . "Profil " . [$bersih $nama] . " diubah dari " . [$bersih $old] . " menjadi " . [$bersih $prof] . "\\n")
```
Hasilnya:
```
Perubahan PPPoE (1)
Profil budi diubah dari AKTIF menjadi ISOLIR
```

**Data lain yang bisa ditambahkan** (dari `$r`, hasil `print as-value`), contoh:
```rsc
:local paket ($r->"comment")     ;# isi comment (mis. paket/tanggal)
:local svc   ($r->"service")     ;# tipe layanan (pppoe, dst)
```
lalu sisipkan ke baris, mis. `. " [" . [$bersih $paket] . "]"`. Selalu bungkus
dengan `[$bersih ...]` untuk data yang diketik manusia (comment, nama).

> Jangan pakai tanda kutip `"` di dalam teks template — itu merusak format
> pengiriman. Gunakan kata biasa & `\\n` untuk baris baru.

## Mengubah kecepatan cek
Ganti `interval=30m` jadi `interval=5m` (5 menit) di scheduler kalau ingin lebih
cepat. Makin sering = makin banyak kerja router (untuk perubahan profil, 30 menit
biasanya sudah cukup). Script punya pengaman: kalau cek sebelumnya belum selesai,
cek berikutnya dilewati (tidak tumpang-tindih).

---

## Kalau ada masalah

| Gejala | Penyebab / solusi |
|--------|-------------------|
| Tidak ada pesan sama sekali | Cek `botToken` & `chatId` benar. Tes kirim manual (lihat di bawah). Cek juga `/log print where message~"pppoe-watch"`. |
| Log: `pppoe-watch: gagal kirim Telegram, diulang run berikutnya` | Internet/DNS putus atau Telegram menolak. Tidak ada yang hilang — dikirim ulang di cek berikutnya. Kalau terus-menerus: set DNS `/ip dns set servers=1.1.1.1,8.8.8.8`; kalau error sertifikat, lihat catatan CA di bawah. |
| Pesan yang sama masuk dua kali | Pesan panjang dipecah, pecahan ke-2 gagal → seluruh daftar diulang di cek berikutnya. Wajar, jarang. |
| Pesan sama berulang tiap 30 menit untuk user yang sama | Ada **dua secret dengan nama sama**? Cek `/ppp secret print where name=NAMA`. Script melewati duplikat & menulis peringatan di log — hapus salah satunya. Atau: jangan hapus/rename script tiap kali jalan. |
| Log: `pppoe-watch: run sebelumnya masih jalan, dilewati` | Cek sebelumnya belum selesai (biasanya karena kirim lambat). Aman; kalau sering, perbesar `interval`. |
| Setelah router restart tidak ada notif untuk perubahan lama | Normal — daftar di RAM dicatat ulang saat pertama, tidak dikirim. |
| Nama user mengandung `"` atau `\` | Otomatis diganti `'` di pesan. Tidak merusak apa-apa. |

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
> (Source), bukan schedulernya. Variabel global baru (mis. `pppoeWatchBusy`)
> otomatis dibuat saat jalan; daftar profil yang sudah tersimpan tetap terpakai,
> jadi update **tidak** memicu banjir "BARU".

---

## Cara mencopot
```rsc
/system scheduler remove [find name=pppoe-profile-watch]
/system script remove [find name=pppoe-profile-watch]
:global pppoeProfileState; :set pppoeProfileState
:global pppoeWatchBusy; :set pppoeWatchBusy
:global pppoeInit; :set pppoeInit
```
(`pppoeInit` hanya ada di versi lama — kalau tidak ada, baris itu tidak berpengaruh.)
