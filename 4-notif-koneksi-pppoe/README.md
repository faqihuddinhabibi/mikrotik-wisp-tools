# 4 · Notifikasi Koneksi PPPoE (Connect / Disconnect) → Telegram

Kirim pesan **Telegram real-time** setiap pelanggan PPPoE **terhubung** (connect)
atau **terputus** (disconnect). Berguna untuk memantau kondisi jaringan &
gangguan dari HP.

---

## Daftar isi
- [Apa gunanya? (dan beda dengan Alat 1)](#apa-gunanya-dan-beda-dengan-alat-1)
- [Bagaimana cara kerjanya?](#bagaimana-cara-kerjanya)
- [Yang perlu disiapkan](#yang-perlu-disiapkan)
- [Langkah 1 — Buat bot Telegram](#langkah-1--buat-bot-telegram)
- [Langkah 2 — Pasang di profil (lewat Winbox)](#langkah-2--pasang-di-profil-lewat-winbox)
- [Langkah 3 — Uji coba](#langkah-3--uji-coba)
- [Contoh pesan & cara ubah template](#contoh-pesan--cara-ubah-template)
- [Catatan penting](#catatan-penting)
- [Kalau ada masalah](#kalau-ada-masalah)
- [Cara mencopot](#cara-mencopot)

---

## Apa gunanya? (dan beda dengan Alat 1)

- **Tahu real-time** saat pelanggan online/offline → cepat mendeteksi gangguan.
- Pas ada laporan "internet mati", Anda bisa cek riwayat connect/disconnect-nya.

> **Beda dengan [Alat 1](../1-notif-profil-pppoe):**
> - **Alat 1** = notif saat **profil** pelanggan diubah (mis. diisolir). Pakai
>   pengecekan berkala (scheduler).
> - **Alat 4 (ini)** = notif saat pelanggan **connect/disconnect**. Pakai event
>   bawaan RouterOS (`on-up`/`on-down`), jadi **real-time**.
>
> Keduanya bisa dipakai bersamaan dan boleh memakai **bot Telegram yang sama**.

---

## Bagaimana cara kerjanya?

RouterOS punya "pemicu" bawaan di tiap **profil PPPoE**:
- **On Up** → dijalankan saat sesi pelanggan **naik** (connect).
- **On Down** → dijalankan saat sesi **turun** (disconnect).

Kita isi kedua kolom itu dengan script yang mengirim pesan ke Telegram. Karena ini
event bawaan, notif datang **seketika** (tidak perlu scheduler).

---

## Yang perlu disiapkan

- Akses **MikroTik** (Winbox).
- **Bot Telegram** + **Chat ID** (boleh pakai yang sama dengan Alat 1).
- Router bisa akses internet (untuk kirim ke Telegram).

---

## Langkah 1 — Buat bot Telegram

Sama seperti Alat 1. Ringkasnya:
1. Chat **@BotFather** → `/newbot` → dapat **token**.
2. Kirim pesan ke bot Anda, buka `https://api.telegram.org/bot<TOKEN>/getUpdates`,
   cari `"chat":{"id":...}` → itu **Chat ID**.

Detail lengkap ada di [README Alat 1](../1-notif-profil-pppoe#langkah-1--buat-bot-telegram).

---

## Langkah 2 — Pasang di profil (lewat Winbox)

Notif ini dipasang **per profil**. Pasang di profil paket yang dipakai pelanggan
(mis. `PAKET100`, `PAKET150`, dst). Ulangi langkah untuk tiap profil.

1. 🖥️ Buka file [`ppp-on-up.rsc`](ppp-on-up.rsc) & [`ppp-on-down.rsc`](ppp-on-down.rsc),
   ganti `ISI_TOKEN_BOT` & `ISI_CHAT_ID` dengan milik Anda. Salin isinya.
2. 🪟 Winbox → menu **PPP** → tab **Profiles** → **double-click** profil (mis. `PAKET100`).
3. Cari kolom **On Up** → **tempel** seluruh isi `ppp-on-up.rsc`.
4. Cari kolom **On Down** → **tempel** seluruh isi `ppp-on-down.rsc`.
5. **OK**. Ulangi untuk profil paket lain.

> Tips: cukup pasang di profil paket aktif. Tidak perlu di profil `ISOLIR`
> (kecuali Anda memang ingin notif saat sesi isolir naik/turun).

---

## Langkah 3 — Uji coba

- Minta salah satu pelanggan (atau perangkat tes) reconnect, **atau** putuskan
  sesinya dari **PPP → Active Connections** (tombol **–**) lalu biarkan menyambung lagi.
- Pesan **TERPUTUS** lalu **TERHUBUNG** harus masuk Telegram dalam hitungan detik.

---

## Contoh pesan & cara ubah template

**Saat connect (On Up):**
```
✅ TERHUBUNG

PPPoE : budi
Profile : PAKET100
Waktu : 2026-09-14 21:30:11

Disconnect (3):
andi, siti, warkop-rt5
```
**Saat disconnect (On Down):**
```
❌ TERPUTUS

PPPoE : budi
Profile : PAKET100
Waktu : 2026-09-14 21:30:11

Disconnect (4):
andi, siti, warkop-rt5, budi
```

**Isinya:** nama PPPoE + waktu + profile di atas; lalu **daftar yang sedang
disconnect** beserta jumlahnya di bawah. Berguna di lapangan: sekali lihat langsung
tahu siapa saja yang mati (kalau banyak yang drop bareng → kemungkinan gangguan
kabel/ODP, bukan cuma 1 pelanggan).

**Bagian yang mengatur teks** ada di baris `:local teks (...)` dalam masing-masing file.
Aturannya:
- Teks dalam kutip `"..."` = tetap (boleh diganti).
- `\\n` = ganti baris, `\\n\\n` = baris kosong (jarak 1 enter).
- Nilai yang sudah dihitung script:
  | Kode | Arti |
  |------|------|
  | `$nama` | nama PPPoE yang connect/disconnect |
  | `$waktu` | tanggal & jam |
  | `$profil` | profile pelanggan (mis. PAKET100 / ISOLIR) |
  | `$mati` | jumlah PPPoE yang sedang disconnect |
  | `$daftar` | daftar nama PPPoE yang disconnect |

**Contoh mengubah template** (lebih ringkas):
```rsc
:local teks ("🔴 " . $nama . " (" . $profil . ") putus. Total mati: " . $mati)
```
Hasil: `🔴 budi (PAKET100) putus. Total mati: 4`

---

## Catatan penting

- **JANGAN kirim password pelanggan** ke grup Telegram. Secara teknis bisa dibaca
  (`/ppp secret get ... password`), tapi itu **bocor privasi** — jangan lakukan.
  Template di sini sengaja tidak menyertakannya.
- **Bisa jadi ramai.** Kalau banyak pelanggan atau jaringan sering "kedip"
  (flapping), pesan connect/disconnect bisa membanjiri. Pertimbangkan mengirim ke
  **grup khusus** yang bisa di-mute, atau pasang hanya di sebagian profil.
- Kalau fetch error SSL, set DNS dulu: `/ip dns set servers=1.1.1.1,8.8.8.8`
  (lihat catatan CA di [README Alat 1](../1-notif-profil-pppoe#kalau-ada-masalah)).

---

## Kalau ada masalah

| Gejala | Solusi |
|--------|--------|
| Tidak ada pesan | Cek token & chat id. Tes kirim manual (lihat README Alat 1). Pastikan script benar-benar tertempel di kolom On Up/On Down profil yang dipakai pelanggan. |
| Hanya connect / hanya disconnect yang masuk | Berarti salah satu kolom (On Up **atau** On Down) belum diisi. |
| Pesan membanjiri | Jaringan flapping. Kirim ke grup yang di-mute, atau kurangi profil yang dipasangi. |
| Daftar "yang mati" sangat panjang | Kalau pelanggan sangat banyak & banyak yang mati, daftar bisa panjang (batas Telegram 4096 karakter). Bisa hapus baris `Yang mati` dari template dan cukup tampilkan angka `$mati`. |
| Angka `Mati` seperti telat 1 saat disconnect | Wajar — saat On Down, sesi yang baru putus kadang masih terhitung sesaat. Selisih 1 tidak masalah. |

---

## Cara mencopot
🪟 Winbox → **PPP → Profiles** → double-click tiap profil → **kosongkan** kolom
**On Up** dan **On Down** → **OK**.
