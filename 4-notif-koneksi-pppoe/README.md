# 4 · Notifikasi Koneksi PPPoE (Siapa yang Mati) → Telegram

Kirim ke Telegram **daftar pelanggan yang sedang mati** (offline) + **siapa yang baru
nyala**, hanya **saat ada perubahan**. Buat teknisi: sekali lihat langsung tahu siapa
yang harus dicek — tanpa mikir.

> **Kenapa model "snapshot", bukan kirim per-kejadian?**
> Kirim Telegram langsung dari event (`on-down`) tidak andal (sering gagal saat sesi
> putus) dan gampang kena rate-limit / **ban** kalau banyak trouble. Model ini kirim
> **maksimal 1 pesan per interval, hanya saat daftar berubah** → aman & reliable.
> Bonus: **tidak perlu utak-atik profil** (tidak ada on-up/on-down) — 1 script saja.

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
- **Deteksi gangguan massal**: banyak nama muncul di "Yang mati" sekaligus.

> Beda dengan [Alat 1](../1-notif-profil-pppoe) (perubahan profil / pelanggan
> baru-dihapus). Alat 4 fokus **status online/offline**.

---

## Bagaimana cara kerjanya

```
Scheduler tiap ~30 detik jalankan "kirim-notif":
   - cek siapa yang OFFLINE sekarang (snapshot)
   - bandingkan dengan snapshot sebelumnya
        - ada yang baru mati / baru nyala?  -> kirim 1 pesan
        - daftar sama persis?               -> tidak kirim apa-apa
```

- **Hanya kirim saat berubah** → tidak spam → aman dari rate-limit / ban.
- **Reliable**: jalan di konteks scheduler (bukan sesi yang putus).
- **Tidak perlu on-up/on-down** di profil → pemasangan simpel, dan tidak ada
  error "executing script from ppp" di interface uplink.

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

**Cuma 1 script, tanpa menyentuh profil.**

1. 🖥️ Buka [`kirim-notif.rsc`](kirim-notif.rsc), ganti `ISI_TOKEN_BOT` & `ISI_CHAT_ID`.
2. 🪟 Winbox → **System → Scripts → Add (+)**. **Name:** `kirim-notif`, tempel isinya
   ke **Source** → **OK** (policy: centang semua / minimal read + test).
3. 🪟 Winbox → **New Terminal**, pasang scheduler (1 baris):
   ```rsc
   /system scheduler add name=kirim-notif interval=30s on-event="/system script run kirim-notif" comment="Notif koneksi PPPoE"
   ```

---

## Langkah 3 — Uji coba
1. Putus 1 user (🪟 PPP → Active Connections → tombol **–**), biarkan mati.
2. Tunggu ≤ 30 detik → pesan masuk (nama itu ada di "Yang mati").
3. Biarkan user itu nyambung lagi → pesan berikutnya menampilkannya di "Baru nyala",
   dan hilang dari "Yang mati".
4. Tes manual (tanpa nunggu): `/system script run kirim-notif`.

---

## Contoh pesan

Di HP (judul, "Baru nyala", "Yang mati" muncul **tebal**):

```text
Update Koneksi
2026-09-14 22:00:00
Aktif: 116/120

🟢 Baru nyala: budi, andi
🔴 Yang mati (4): siti, rudi, joko, warkop-rt5
```
- **Baru nyala** = yang tadinya mati, sekarang balik. Kalau tidak ada → `-`.
- **Yang mati (4)** = semua yang offline sekarang + jumlahnya.
- Kalau daftar tidak berubah → **tidak ada pesan**.

---

## Atur & kustomisasi
- **Interval**: ganti `interval=30s` (mis. `1m` lebih jarang, `20s` lebih cepat).
- **Batas nama**: `:local maxList 40` di script — kalau nama sangat banyak (mati
  lampu), daftar dipotong jadi `… +X lagi` (biar tidak lewat batas 4096 karakter
  Telegram). Nama panjang? turunkan (mis. `30`).
- **Teks/format**: ubah baris `:local teks (...)`. Pakai HTML (`<b>..</b>` = tebal).
  ⚠️ Username jangan mengandung `< > &` (bisa bikin seluruh pesan ditolak). Kalau ada,
  hapus tag `<b>`/`</b>` dan `\"parse_mode\":\"HTML\",` → jadi teks biasa.

---

## Catatan
- **Mati lampu / gangguan massal**: semua putus → 1 pesan berisi "Yang mati (395):
  [40 nama] … +355 lagi". Interval berikutnya kalau tidak ada perubahan lagi → tidak
  kirim. Saat pulih bertahap, tiap ada yang balik → daftar mengecil.
- **Tidak spam** → aman dari rate-limit / ban Telegram.
- **`Aktif: x/total`** akurat untuk jaringan **murni PPPoE**.
- State disimpan di RAM (`pppOfflinePrev`). Setelah reboot, run pertama hanya
  mencatat kondisi (tidak kirim), lalu normal.

---

## Cara mencopot
```rsc
/system scheduler remove [find name=kirim-notif]
/system script remove [find name=kirim-notif]
:global pppOfflinePrev; :set pppOfflinePrev
```
