# 4 · Notifikasi Koneksi PPPoE → Telegram

Kirim ke Telegram, tiap ~30 detik (hanya saat ada aktivitas):
- **Terhubung kembali** — yang tadinya mati, sekarang balik.
- **Masih mati** — yang offline sekarang.
- **Sering putus** — yang flap (putus berkali-kali) → tanda wifi/kabel bermasalah.

> **Kenapa modelnya begini?**
> - **on-down cuma MENGHITUNG** tiap putus (tanpa kirim) → menangkap **semua** flap
>   (termasuk yang cepat), tanpa race & tanpa spam.
> - **scheduler** yang mengirim, **1 pesan per interval, hanya saat ada aktivitas** →
>   reliable & **aman dari rate-limit / ban**.
> Gabungan: catat setiap kejadian, kirim kumulatif.

---

## Daftar isi
- [Apa gunanya](#apa-gunanya)
- [Bagaimana cara kerjanya](#bagaimana-cara-kerjanya)
- [Yang perlu disiapkan](#yang-perlu-disiapkan)
- [Langkah 1 — Buat bot Telegram](#langkah-1--buat-bot-telegram)
- [Langkah 2 — Pasang script + scheduler](#langkah-2--pasang-script--scheduler)
- [Langkah 3 — Uji coba](#langkah-3--uji-coba)
- [Contoh pesan](#contoh-pesan)
- [Atur & kustomisasi](#atur--kustomisasi)
- [Catatan](#catatan)
- [Cara mencopot](#cara-mencopot)

---

## Apa gunanya
- **Tahu siapa yang mati sekarang** → teknisi langsung tahu tujuan.
- **Tahu siapa yang baru nyala** (pulih) → daftar mati otomatis mengecil.
- **Deteksi gangguan massal**: banyak nama muncul di "Masih mati" sekaligus.

> Beda dengan [Alat 1](../1-notif-profil-pppoe) (perubahan profil / pelanggan
> baru-dihapus). Alat 4 fokus **status online/offline**.

---

## Bagaimana cara kerjanya

```
Tiap pelanggan PUTUS  → On Down: tambah +1 hitungan flap-nya (di memori, tanpa kirim)

Scheduler tiap ~30 detik jalankan "kirim-notif":
   - baca & reset hitungan flap (siapa yang sering putus)
   - snapshot: siapa yang offline sekarang, bandingkan dgn sebelumnya (untuk "terhubung kembali")
   - ada aktivitas (ada yang berubah / ada yang flap)? -> kirim 1 pesan
   - tidak ada apa-apa? -> tidak kirim
```

- **on-down cuma `:set` counter** (tanpa fetch, tanpa lookup) → **tidak kena race**
  saat sesi putus & **aman dipasang di profil manapun** (tidak error di uplink).
- **Kirim 1 pesan per interval** → tidak spam → **aman dari rate-limit / ban**.
- Flap (putus cepat) **tetap tercatat** karena dihitung saat kejadian, bukan saat cek.

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

---

## Langkah 2 — Pasang script + scheduler

### 2a. Pasang penghitung flap (On Down)
Isi [`ppp-on-down.rsc`](ppp-on-down.rsc) ke kolom **On Down** tiap **profil pelanggan**:
1. 🪟 Winbox → **PPP → Profiles** → double-click profil (mis. `PAKET100`).
2. Kolom **On Down** → tempel isi `ppp-on-down.rsc` → **OK**. Ulangi tiap profil paket.

> Isinya cuma `:set` counter — tanpa fetch, tanpa lookup → **tidak akan error**
> (walau kepasang di profil uplink sekalipun). Tidak perlu On Up.

### 2b. Pasang pengirim (scheduler)
1. 🖥️ Buka [`kirim-notif.rsc`](kirim-notif.rsc), ganti `ISI_TOKEN_BOT` & `ISI_CHAT_ID`.
2. 🪟 **System → Scripts → Add (+)**. **Name:** `kirim-notif`, tempel ke **Source** → **OK**.
3. 🪟 **New Terminal**, pasang scheduler (1 baris):
   ```rsc
   /system scheduler add name=kirim-notif interval=30s on-event="/system script run kirim-notif" comment="Notif koneksi PPPoE"
   ```

---

## Langkah 3 — Uji coba
1. Putus 1 user (🪟 PPP → Active Connections → tombol **–**), biarkan mati.
2. Tunggu ≤ 30 detik → pesan masuk (nama itu ada di "Masih mati").
3. Biarkan user itu nyambung lagi → pesan berikutnya menampilkannya di "Terhubung kembali",
   dan hilang dari "Masih mati".
4. Putus-sambung 1 user beberapa kali cepat → muncul di "Sering putus (Nx)".
5. Tes manual (tanpa nunggu): `/system script run kirim-notif`.

---

## Contoh pesan

Di HP (judul & label "Terhubung kembali" / "Masih mati" / "Sering putus" **tebal**):

```text
Update Koneksi
2026-09-15 22:00:00
Aktif: 116/120

Terhubung kembali:
budi

Masih mati (3):
siti, rudi, joko

Sering putus (30 dtk):
andi (5x), warkop (3x)
```
- **Terhubung kembali** = tadinya mati, sekarang balik. Kalau tidak ada → `-`.
- **Masih mati (3)** = yang offline sekarang + jumlahnya.
- **Sering putus** = yang putus **≥ 2×** dalam 30 detik (flap) + berapa kali → tanda
  wifi/kabel bermasalah. Kalau tidak ada → `-`.
- Kalau tidak ada aktivitas apa pun → **tidak ada pesan**.

---

## Atur & kustomisasi
- **Interval**: ganti `interval=30s` (mis. `1m` lebih jarang, `20s` lebih cepat).
- **Ambang "sering putus"**: `:local flapMin 2` di `kirim-notif.rsc` — user dianggap
  "sering putus" kalau putus ≥ segini kali dalam 1 interval. Naikkan (mis. `3`) kalau
  mau lebih ketat.
- **Batas nama**: `:local maxList 30` di script — kalau nama sangat banyak (mati
  lampu), daftar dipotong jadi `… +X lagi` (biar tidak lewat batas 4096 karakter
  Telegram). Jangan dinaikkan: 3 daftar × 40 nama × 30 karakter sudah lewat 4096.
- **Teks/format**: ubah baris `:local teks (...)`. Pakai HTML (`<b>..</b>` = tebal).
  ⚠️ Username jangan mengandung `< > &` (bisa bikin seluruh pesan ditolak). Kalau ada,
  hapus tag `<b>`/`</b>` dan `\"parse_mode\":\"HTML\",` → jadi teks biasa.

---

## Catatan
- **Mati lampu / gangguan massal**: semua putus → 1 pesan berisi "Masih mati (395):
  [30 nama] … +365 lagi". Interval berikutnya kalau tidak ada aktivitas → tidak kirim.
  Saat pulih bertahap, tiap ada yang balik → daftar mengecil.
- **Tidak spam** → aman dari rate-limit / ban Telegram.
- **`Aktif: x/total`** akurat untuk jaringan **murni PPPoE**.
- State di RAM (`pppOfflinePrev`, `pppFlap`). Setelah reboot, run pertama hanya
  mencatat kondisi (tidak kirim), lalu normal.

---

## Cara mencopot
```rsc
/system scheduler remove [find name=kirim-notif]
/system script remove [find name=kirim-notif]
:global pppOfflinePrev; :set pppOfflinePrev
:global pppFlap; :set pppFlap
```
Lalu 🪟 PPP → Profiles → kosongkan kolom **On Down** tiap profil pelanggan.
