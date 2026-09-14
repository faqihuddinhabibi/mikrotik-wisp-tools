# 4 · Notifikasi Koneksi PPPoE (Connect / Disconnect) → Telegram

Kirim **ringkasan** pelanggan PPPoE yang **terhubung** (connect) & **terputus**
(disconnect) ke Telegram, dikirim rutin tiap beberapa detik dalam **1 pesan**.
Berguna untuk memantau kondisi jaringan & gangguan dari HP.

> **Kenapa model "ringkasan", bukan kirim per-kejadian?**
> Mengirim Telegram **langsung** dari `on-down` **tidak andal**: saat sesi putus,
> RouterOS sedang membereskan sesi itu, sehingga pengiriman sering **ke-cut** (kadang
> masuk, kadang tidak — terlihat acak). Kirim beruntun juga gampang **kena limit**
> Telegram. Model ini menghindari kedua masalah itu, dan **lebih ringan** untuk
> jaringan besar (ratusan pelanggan).

---

## Daftar isi
- [Apa gunanya? (dan beda dengan Alat 1)](#apa-gunanya-dan-beda-dengan-alat-1)
- [Bagaimana cara kerjanya?](#bagaimana-cara-kerjanya)
- [Yang perlu disiapkan](#yang-perlu-disiapkan)
- [Langkah 1 — Buat bot Telegram](#langkah-1--buat-bot-telegram)
- [Langkah 2 — Pasang pencatat di profil (On Up/On Down)](#langkah-2--pasang-pencatat-di-profil-on-upon-down)
- [Langkah 3 — Pasang pengirim + scheduler](#langkah-3--pasang-pengirim--scheduler)
- [Langkah 4 — Uji coba](#langkah-4--uji-coba)
- [Contoh pesan & cara ubah template](#contoh-pesan--cara-ubah-template)
- [Atur kecepatan (interval)](#atur-kecepatan-interval)
- [Catatan](#catatan)
- [Kalau ada masalah](#kalau-ada-masalah)
- [Cara mencopot](#cara-mencopot)

---

## Apa gunanya? (dan beda dengan Alat 1)

- **Pantau real-ish-time** siapa saja yang online/offline → cepat tahu gangguan.
- Kalau banyak putus bersamaan dalam 1 ringkasan → indikasi gangguan kabel/ODP.

> **Beda dengan [Alat 1](../1-notif-profil-pppoe):**
> - **Alat 1** = notif saat **profil** diubah (mis. diisolir). Pengecekan berkala.
> - **Alat 4 (ini)** = ringkasan **connect/disconnect**.
> Boleh pakai **bot yang sama**, tapi **disarankan grup berbeda** (Alat 4 lebih rame).

---

## Bagaimana cara kerjanya?

```
Tiap pelanggan connect  → On Up   : catat namanya ke "antrian UP"   (ringan, tanpa kirim)
Tiap pelanggan disconnect → On Down: catat namanya ke "antrian DOWN" (ringan, tanpa kirim)

Scheduler tiap ~30 detik jalankan "kirim-notif":
   - antrian kosong?  -> selesai, tidak kirim apa-apa (nyaris nol kerja)
   - ada isi?         -> kirim 1 pesan ringkasan, lalu kosongkan antrian
```

- **On Up/On Down** cuma menambah 1 nama ke daftar (variabel global). Tidak ada
  loop berat, tidak ada `fetch` → tidak kena race saat sesi turun.
- **Pengiriman** dilakukan scheduler di konteks sistem → `fetch` selalu tuntas.
- **Maksimal 1 pesan per interval** → jauh di bawah limit Telegram.
- Saat mengirim, tiap nama yang berubah **dicek status terkininya** (masih online
  / offline), lalu dikelompokkan ke **UP** atau **DOWN** — jadi teknisi tahu
  **kondisi sekarang**, bukan cuma "ada kejadian". Hanya user yang berubah yang
  dicek → tetap ringan walau ratusan pelanggan.

---

## Yang perlu disiapkan
- Akses **MikroTik** (Winbox).
- **Bot Telegram** + **Chat ID** (boleh sama dengan Alat 1; disarankan grup terpisah).
- Router bisa akses internet.

---

## Langkah 1 — Buat bot Telegram
Sama seperti Alat 1: @BotFather `/newbot` → token; kirim pesan ke bot →
`https://api.telegram.org/bot<TOKEN>/getUpdates` → ambil Chat ID.
Detail: [README Alat 1](../1-notif-profil-pppoe#langkah-1--buat-bot-telegram).

> **Token TIDAK diisi di On Up/On Down** — cukup di script pengirim (Langkah 3).

---

## Langkah 2 — Pasang pencatat di profil (On Up/On Down)

Pasang di **profil paket** yang dipakai pelanggan (mis. `PAKET100`, dst). Ulangi per profil.

1. 🪟 Winbox → **PPP → Profiles** → **double-click** profil.
2. Kolom **On Up** → tempel isi [`ppp-on-up.rsc`](ppp-on-up.rsc).
3. Kolom **On Down** → tempel isi [`ppp-on-down.rsc`](ppp-on-down.rsc).
4. **OK**. Ulangi untuk profil paket lain.

Isinya cuma 3 baris — tidak ada token, tidak ada fetch.

---

## Langkah 3 — Pasang pengirim + scheduler

1. 🖥️ Buka [`kirim-notif.rsc`](kirim-notif.rsc), ganti `ISI_TOKEN_BOT` & `ISI_CHAT_ID`.
2. 🪟 Winbox → **System → Scripts → Add (+)**. **Name:** `kirim-notif`, tempel
   isinya ke **Source** → **OK**.
3. 🪟 Winbox → **New Terminal**, pasang scheduler (tiap 30 detik):
   ```rsc
   /system scheduler
   add name=kirim-notif interval=30s \
       on-event="/system script run kirim-notif" \
       comment="Kirim ringkasan koneksi PPPoE ke Telegram"
   ```

---

## Langkah 4 — Uji coba
1. Putus 1–2 user (🪟 PPP → Active Connections → tombol **–**), biarkan menyambung lagi.
2. Tunggu ≤ 30 detik → 1 pesan ringkasan masuk Telegram berisi UP & DOWN.
3. Tes manual pengirim (tanpa nunggu scheduler):
   ```rsc
   /system script run kirim-notif
   ```

---

## Contoh pesan & cara ubah template

Tampil di Telegram (judul & UP/DOWN **tebal**):

> **Update Koneksi**
> 2026-09-14 22:00:00
> Aktif: 116/120
>
> 🟢 **UP** (2): budi (5), andi (1)
> 🔴 **DOWN** (1): siti (3)

Cara baca:
- **Aktif: 116/120** → jumlah PPPoE **online / total** semua PPPoE. Sekali lihat tahu
  kesehatan jaringan.
- Angka di **samping nama** = **berapa kali user itu kedip** (connect/disconnect) dalam
  interval itu. Mis. `budi (5)` = budi kedip 5×  → koneksinya labil. `andi (1)` = sekali
  (normal).
- Angka di **samping UP/DOWN** = jumlah user di daftar itu.
- **UP / DOWN = status SAAT INI** (dicek pas kirim). Jadi yang **masih mati** ada di
  daftar DOWN; yang sudah balik ada di UP.
- Kalau salah satu kosong → `-`. Kalau tidak ada perubahan sama sekali → tidak ada pesan.

**Template** ada di baris `:local teks (...)` dalam [`kirim-notif.rsc`](kirim-notif.rsc).
Pakai **format HTML Telegram** (`parse_mode=HTML`):
- `<b>...</b>` = tebal. `\\n` = ganti baris, `\\n\\n` = baris kosong.
- Nilai yang tersedia:
  | Kode | Arti |
  |------|------|
  | `$waktu` | tanggal & jam saat pengiriman |
  | `$aktif` | jumlah PPPoE yang online sekarang |
  | `$total` | jumlah total PPPoE (semua secret) |
  | `$up` | daftar `nama (kedip)` yang **sekarang online** |
  | `$nUp` | jumlah user di daftar UP |
  | `$down` | daftar `nama (kedip)` yang **sekarang offline** |
  | `$nDown` | jumlah user di daftar DOWN |

**Contoh ubah** (cuma yang masih mati + total):
```rsc
:local teks ("🔴 <b>DOWN</b> (" . $nDown . "): " . $down . "\\nAktif: " . $aktif . "/" . $total)
```

---

## Atur kecepatan (interval)
Ganti `interval=30s` di scheduler:
- `interval=20s` → lebih cepat (tetap aman).
- `interval=1m` → lebih hemat & lebih jarang.
Makin panjang interval = makin sedikit pesan (kejadian digabung jadi 1). Tetap 1
pesan per interval, jadi tetap aman dari limit.

---

## Catatan
- **Nama muncul sekali + angka kedip.** User yang putus-sambung berkali-kali tetap
  muncul **sekali**, dengan angka berapa kali dia kedip (mis. `budi (5)`), di posisi
  **status terkininya** (UP/DOWN). Pesan tetap rapi & langsung kelihatan yang labil.
- **Batas panjang pesan (penting).** Telegram membatasi **4096 karakter/pesan**.
  Nama PPPoE bisa panjang (20–30 karakter), jadi daftar dipotong otomatis:
  maksimal **30 nama** per daftar, sisanya diringkas `… +355 lagi`. Angka total
  `(395)` tetap akurat, pesan tidak ditolak. Ubah batas di `kirim-notif.rsc`:
  `:local maxList 30` (jangan terlalu besar kalau nama panjang).
- **Karakter khusus di username (penting).** Karena pesan pakai format **HTML**
  (untuk bold), username PPPoE **jangan mengandung `<`, `>`, atau `&`** — kalau ada
  **1 saja**, Telegram menolak **seluruh** pesan (notif jadi tidak terkirim).
  Username normal (huruf, angka, `. _ -`) aman. Kalau terpaksa ada karakter itu,
  matikan format: di `kirim-notif.rsc` hapus tag `<b>`/`</b>` dan hapus
  `\"parse_mode\":\"HTML\",` pada baris `http-data` (pesan jadi teks biasa, tapi
  kebal karakter khusus).
- **Mati lampu / gangguan massal:** semua user putus → dikirim **1 pesan**, mis.
  `🔴 DOWN (395): budi (1), siti (1), … +365 lagi`. Interval berikutnya **tidak ada
  kejadian baru → tidak kirim apa-apa** (tidak spam). Saat listrik pulih & semua
  nyambung → **1 pesan** daftar UP. Jadi hanya dikirim saat ada perubahan.
- **Jangan kirim password** pelanggan (bocor privasi) — template ini tidak memakainya.
- SSL error? `/ip dns set servers=1.1.1.1,8.8.8.8` (lihat catatan CA di
  [README Alat 1](../1-notif-profil-pppoe#kalau-ada-masalah)).

---

## Kalau ada masalah
| Gejala | Solusi |
|--------|--------|
| Tidak ada pesan sama sekali | Tes `/system script run kirim-notif`. Cek token & chat id di `kirim-notif.rsc`. |
| Pesan kosong / tidak ada nama | Pastikan On Up/On Down benar-benar tertempel di profil yang dipakai pelanggan (cek `/ppp profile print detail`). |
| Hanya UP atau hanya DOWN | Salah satu kolom (On Up / On Down) belum diisi. |
| Ingin lebih jarang/ramai | Ubah `interval` scheduler. |

---

## Cara mencopot
```rsc
/system scheduler remove [find name=kirim-notif]
/system script remove [find name=kirim-notif]
:global pppNotifUp; :set pppNotifUp ""
:global pppNotifDown; :set pppNotifDown ""
```
Lalu 🪟 PPP → Profiles → kosongkan kolom **On Up** & **On Down** tiap profil.
