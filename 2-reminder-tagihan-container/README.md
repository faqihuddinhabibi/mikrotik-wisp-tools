# 2 · Reminder Tagihan + Isolir — Hosting di MikroTik (Container)

Menampilkan **halaman pengingat tagihan otomatis** ke HP pelanggan (mirip splash
page wifi.id) saat **besok jatuh tempo (H-1)**, plus **halaman isolir** saat
pelanggan diblokir karena belum bayar.

Pada versi ini, halaman di-host **di dalam MikroTik sendiri** sebagai container —
**tanpa VPS, tanpa layanan luar**. Kalau lebih suka host di server terpisah, pakai
[folder 3 (VPS)](../3-reminder-tagihan-vps).

> ⚠️ Mengaktifkan container butuh **install paket + reboot** router. Di jaringan
> yang sedang dipakai pelanggan, lakukan saat **jam sepi (maintenance window)**.

---

## Daftar isi
- [Apa yang Anda dapat](#apa-yang-anda-dapat)
- [Cara kerja (wajib paham)](#cara-kerja-wajib-paham)
- [Kelebihan & kekurangan versi container](#kelebihan--kekurangan-versi-container)
- [Yang perlu disiapkan](#yang-perlu-disiapkan)
- [Bagian A — Siapkan halaman sebagai container](#bagian-a--siapkan-halaman-sebagai-container)
- [Bagian B — Setup reminder di MikroTik](#bagian-b--setup-reminder-di-mikrotik)
- [Bagian C — Isi tanggal jatuh tempo](#bagian-c--isi-tanggal-jatuh-tempo)
- [Bagian D — Isolir (blokir + halaman)](#bagian-d--isolir-blokir--halaman)
- [Bagian E — Kecualikan pelanggan tertentu](#bagian-e--kecualikan-pelanggan-tertentu)
- [Tugas sehari-hari (contekan cepat)](#tugas-sehari-hari-contekan-cepat)
- [Batasan penting](#batasan-penting)
- [Kalau ada masalah](#kalau-ada-masalah)
- [Cara mencopot](#cara-mencopot)

---

## Apa yang Anda dapat

- **Reminder H-1 otomatis.** Sehari sebelum jatuh tempo, saat pelanggan
  menyambung wifi, HP-nya memunculkan popup halaman "tagihan jatuh tempo besok".
  Internet mereka **tetap menyala** (hanya diingatkan).
- **Isolir.** Untuk pelanggan telat, teknisi mengubah profilnya jadi profil isolir
  → internet **diblokir total** dan semua halaman diarahkan ke halaman isolir.
- **Pengecualian.** Pelanggan tertentu bisa dikecualikan agar tidak pernah melihat
  halaman reminder.

---

## Cara kerja (wajib paham)

```
Sehari sebelum jatuh tempo (H-1):
  scheduler (tiap 1 jam) baca "DUE:tanggal" dari comment tiap pelanggan
        │  kalau besok jatuh tempo & pelanggan online
        ▼
  IP pelanggan dimasukkan ke daftar "tagihan-reminder"
        │
        ▼
  MikroTik belokkan HTTP mereka → web-proxy → redirect ke halaman DI CONTAINER
        │
        ▼
  HP pelanggan memunculkan popup halaman reminder
```

**Kenapa popup muncul sendiri?** HP (Android/iOS) tiap menyambung wifi otomatis
menembak alamat cek-koneksi lewat **HTTP**. MikroTik menangkapnya → muncul
notifikasi "Sign in", persis wifi.id.

**Halaman ada di dalam MikroTik** (mis. IP `172.17.0.2`). Karena lokal, halaman
**selalu bisa dibuka** — bahkan saat pelanggan diisolir dan internet keluar diblok.

> Pelanggan memakai router sendiri (dial PPPoE)? **Tetap jalan** — semua trafik
> mereka lewat MikroTik.

---

## Kelebihan & kekurangan versi container

| Kelebihan | Kekurangan |
|-----------|------------|
| Tidak butuh VPS / internet — halaman lokal selalu tersedia | Perlu paket container + **reboot** (ada risiko di jam produksi) |
| IP halaman lokal, tidak pernah berubah | Memakai sedikit CPU/RAM/disk router |
| Berdiri sendiri (tidak bergantung pihak luar) | Update halaman = build & upload image ulang |

---

## Yang perlu disiapkan

- **MikroTik x86 / perangkat yang mendukung container**, RouterOS 7.x, ada disk/SSD.
- **Komputer dengan Docker** (untuk membangun image; bukan di router).
- Profil **isolir** + **pool IP terpisah** untuk isolir (kalau pakai fitur isolir).
  Cek dengan `/ip pool print`.
- Nomor **WhatsApp admin** untuk tombol di halaman.

---

## Bagian A — Siapkan halaman sebagai container

### A1. Edit halaman (nomor WA)
Di komputer:
```bash
git clone https://github.com/faqihuddinhabibi/mikrotik-wisp-tools.git
cd mikrotik-wisp-tools
```
Edit `docs/index.html` & `docs/isolir.html` — cari `<!-- GANTI: nomor WA -->`,
ganti `6281234567890` dengan nomor admin.

### A2. Build image → file .tar
Perlu Docker di komputer:
```bash
bash 2-reminder-tagihan-container/web/build-and-export.sh
```
Hasil: `2-reminder-tagihan-container/web/reminder-web.tar`.
**Upload** file itu ke menu **Files** RouterOS (drag-drop di Winbox).

### A3. Aktifkan fitur container di RouterOS (sekali; ada reboot)
1. **Install paket `container`**: unduh `container-<versi>.npk` (arsitektur **x86**)
   dari mikrotik.com → Downloads, cocokkan versi RouterOS. Upload ke **Files** →
   **reboot**. Cek: `/system package print` (harus ada `container`).
2. **Aktifkan device-mode**:
   ```rsc
   /system/device-mode/update container=yes
   ```
   RouterOS minta konfirmasi lewat **reboot** + (pada sebagian perangkat) tekan
   tombol reset fisik dalam beberapa detik. Ikuti instruksi di layar.
   Cek: `/system/device-mode/print` → `container: yes`.

### A4. Jaringan container
```rsc
/interface/veth/add name=veth-web address=172.17.0.2/24 gateway=172.17.0.1
/interface/bridge/add name=br-docker
/ip/address/add address=172.17.0.1/24 interface=br-docker
/interface/bridge/port/add bridge=br-docker interface=veth-web
```

### A5. Buat & jalankan container
```rsc
# cek nama disk dulu:
/disk print
# arahkan penyimpanan container ke disk (ganti disk1 sesuai namamu)
/container/config/set tmpdir=disk1/tmp

/container/add file=reminder-web.tar interface=veth-web root-dir=disk1/web \
    logging=yes start-on-boot=yes
/container/print
/container/start [find]
```
Cek: `/container/print` → status `running`. Halaman ada di **http://172.17.0.2/**
dan **http://172.17.0.2/isolir.html**.

### A6. Update halaman nanti
Edit `docs/*.html` → jalankan lagi `build-and-export.sh` → upload tar baru →
```rsc
/container/stop [find]
/container/remove [find]
/container/add file=reminder-web.tar interface=veth-web root-dir=disk1/web start-on-boot=yes
/container/start [find]
```

---

## Bagian B — Setup reminder di MikroTik

File [`mikrotik/setup-walled-garden.rsc`](mikrotik/setup-walled-garden.rsc) sudah
diset ke IP container `172.17.0.2`. Upload ke **Files**, lalu:
```rsc
/import file-name=setup-walled-garden.rsc
```
Ini menyalakan web-proxy dan menyiapkan pengalihan HTTP untuk daftar
`tagihan-reminder`.

---

## Bagian C — Isi tanggal jatuh tempo

Sistem tahu jatuh tempo dari **comment** `/ppp secret`. Tambahkan `DUE:` diikuti
**tanggal** (pakai 1–28). Di **PPP → Secrets**, isi **Comment**, contoh:
```
Budi RT03 - 20Mbps | DUE:15
```
= jatuh tempo tanggal 15; reminder muncul tanggal 14 (H-1).

Via terminal:
```rsc
/ppp secret set [find name=budi] comment="Budi RT03 - 20Mbps | DUE:15"
```

### Pasang penjadwal (sekali)
Upload [`mikrotik/billing-scheduler.rsc`](mikrotik/billing-scheduler.rsc) →
**System → Scripts → Add** (nama `billing-scheduler`, tempel isinya). Lalu:
```rsc
/system scheduler
add name=billing-scheduler interval=1h \
    on-event="/system script run billing-scheduler" \
    comment="Isi daftar reminder tagihan"
```
Tes:
```rsc
/system script run billing-scheduler
/ip firewall address-list print where list="tagihan-reminder"
```

---

## Bagian D — Isolir (blokir + halaman)

### D1. Sesuaikan & jalankan setup
Buka [`mikrotik/setup-isolir.rsc`](mikrotik/setup-isolir.rsc), sesuaikan subnet
isolir:
```rsc
:local isolirNet "10.1.1.0/24"   ;# subnet pool isolir-mu; cek: /ip pool print
```
> **Cara tahu subnet isolir:** `/ip pool print` → lihat pool yang dipakai profil
> isolir. Range `10.1.1.2-10.1.1.254` → subnet `10.1.1.0/24`.

`redirectUrl` & `pageIp` sudah diset ke container `172.17.0.2`. Lalu import:
```rsc
/import file-name=setup-isolir.rsc
```

### D2. Cara meng-isolir & mengaktifkan lagi (teknisi)
Ganti `PAKET100` dengan nama profil paket pelanggan yang sebenarnya.
```rsc
# ISOLIR (belum bayar):
/ppp secret set [find name=budi] profile=ISOLIR
/ppp active remove [find name=budi]     ;# putus paksa agar reconnect pakai profil baru

# AKTIFKAN LAGI (sudah bayar):
/ppp secret set [find name=budi] profile=PAKET100
/ppp active remove [find name=budi]
```
**Kapan halaman isolir muncul?** Terus-menerus **selama** profil pelanggan = isolir,
setiap kali menyambung wifi. Karena halaman ada di container lokal, **selalu bisa
dibuka** walau internet diblok.

---

## Bagian E — Kecualikan pelanggan tertentu

Agar pelanggan tertentu **tidak pernah** melihat halaman reminder, pilih salah satu:

**Cara A — tag `SKIP` di comment:**
```rsc
/ppp secret set [find name=kantor-desa] comment="Kantor Desa - per 3 bln SKIP"
```
**Cara B — daftar nama di `billing-scheduler.rsc`:**
```rsc
:local excludeNames ",kantor-desa,sekolah-01,puskesmas,"
```
(nama dipisah koma, **diapit koma** di awal & akhir).

---

## Tugas sehari-hari (contekan cepat)

| Mau… | Lakukan |
|------|---------|
| **Ganti tanggal tagihan** | Edit comment: ubah angka setelah `DUE:` |
| **Isolir** pelanggan | `set [find name=X] profile=ISOLIR` lalu `/ppp active remove [find name=X]` |
| **Aktifkan lagi** | `set [find name=X] profile=PAKET...` lalu `/ppp active remove [find name=X]` |
| **Kecualikan** dari reminder | Tambah `SKIP` di comment, atau masukkan nama ke `excludeNames` |
| **Ganti nomor WA / teks** | Edit `docs/*.html`, build & upload image ulang (A6) |

---

## Batasan penting

- **HTTPS tidak bisa dialihkan** (batasan semua captive portal). Popup muncul dari
  **cek-koneksi HTTP** otomatis HP saat menyambung wifi. Untuk kepastian ekstra,
  aktifkan notifikasi Telegram di `billing-scheduler.rsc`.
- **Font halaman saat isolir**: internet diblok, jadi font Google tidak termuat →
  halaman memakai font sistem (tetap rapi).

---

## Kalau ada masalah

| Gejala | Solusi |
|--------|--------|
| Container tidak `running` | Cek `/container/print`, `/log print`. Pastikan device-mode container `yes` & paket container terpasang. |
| Halaman tak kebuka dari HP | Cek `http://172.17.0.2/` dari router/PC di jaringan. Pastikan veth+bridge benar. |
| Reminder tak muncul | Cek daftar `tagihan-reminder`, web-proxy nyala, scheduler jalan. |
| Semua orang ke-redirect | NAT `wg-reminder-redirect` harus `src-address-list=tagihan-reminder`. |
| Halaman isolir tak kebuka | Pastikan `172.17.0.2` ada di `ALLOW-ISOLIR`. |

---

## Cara mencopot
```rsc
# reminder
/system scheduler remove [find name=billing-scheduler]
/system script remove [find name=billing-scheduler]
/ip firewall nat remove [find comment~"^wg-"]
/ip proxy access remove [find comment~"^wg-"]
/ip firewall address-list remove [find list="tagihan-reminder"]

# isolir
/ip firewall nat remove [find comment~"^iso-"]
/ip firewall filter remove [find comment~"^iso-"]
/ip proxy access remove [find comment~"^iso-"]
/ip firewall address-list remove [find list="ALLOW-ISOLIR"]

/ip proxy set enabled=no

# container (kalau mau dihapus total)
/container/stop [find]
/container/remove [find]
/interface/bridge/port/remove [find interface=veth-web]
/interface/veth/remove [find name=veth-web]
/interface/bridge/remove [find name=br-docker]
```
