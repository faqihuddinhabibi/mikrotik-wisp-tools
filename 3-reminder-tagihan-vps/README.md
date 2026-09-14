# 3 · Reminder Tagihan + Isolir — Hosting di VPS

Menampilkan **halaman pengingat tagihan otomatis** ke HP pelanggan (mirip splash
page wifi.id) saat **besok jatuh tempo (H-1)**, plus **halaman isolir** saat
pelanggan diblokir karena belum bayar.

Pada versi ini, halaman di-host di **VPS sendiri** (server dengan IP tetap).
Kalau ingin halaman di-host **di dalam MikroTik** tanpa VPS, pakai
[folder 2 (container)](../2-reminder-tagihan-container).

---

## Daftar isi
- [Apa yang Anda dapat](#apa-yang-anda-dapat)
- [Cara kerja (wajib paham)](#cara-kerja-wajib-paham)
- [Yang perlu disiapkan](#yang-perlu-disiapkan)
- [Bagian A — Siapkan halaman di VPS](#bagian-a--siapkan-halaman-di-vps)
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
- **Isolir.** Untuk pelanggan yang sudah telat, teknisi mengubah profilnya jadi
  profil isolir → internet **diblokir total** dan semua halaman diarahkan ke
  halaman "layanan dinonaktifkan, segera bayar".
- **Pengecualian.** Pelanggan tertentu (mis. instansi yang bayar 3 bulan sekali)
  bisa dikecualikan agar tidak pernah melihat halaman reminder.

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
  MikroTik belokkan HTTP mereka  →  web-proxy  →  redirect ke halaman di VPS
        │
        ▼
  HP pelanggan memunculkan popup halaman reminder
```

**Kenapa popup muncul sendiri?** HP (Android/iOS) tiap menyambung wifi otomatis
menembak alamat cek-koneksi lewat **HTTP**. MikroTik menangkap itu dan mengarahkan
ke halaman kita → muncul notifikasi "Sign in", persis seperti wifi.id.

**Kenapa halaman di VPS bagus?** IP VPS **tetap**, jadi saat isolir (yang perlu
"mengizinkan" alamat halaman) alamatnya tidak pernah berubah. Andal.

> Pelanggan memakai router sendiri (dial PPPoE)? **Tetap jalan** — semua trafik
> mereka lewat MikroTik, jadi pengalihan terjadi di sisi MikroTik.

---

## Yang perlu disiapkan

- **VPS** (contoh: Ubuntu 24.04 LTS) dengan **IP publik**, akses SSH, dan Docker.
- Akses **MikroTik** (Winbox), RouterOS 7.x.
- Profil **isolir** + **pool IP terpisah** untuk isolir (kalau mau pakai fitur isolir).
  Cek pool Anda dengan `/ip pool print`.
- Nomor **WhatsApp admin** untuk tombol di halaman.

---

## Bagian A — Siapkan halaman di VPS

### A1. Install Docker (kalau belum)
```bash
sudo apt update
sudo apt install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker
```

### A2. Ambil kode & edit halaman
```bash
git clone https://github.com/faqihuddinhabibi/mikrotik-wisp-tools.git
cd mikrotik-wisp-tools
```
Edit **nomor WhatsApp** (dan teks bila perlu) di dua file — cari tanda
`<!-- GANTI: nomor WA -->`:
- `docs/index.html`  (halaman reminder H-1)
- `docs/isolir.html` (halaman isolir)

Ganti `6281234567890` dengan nomor admin (format `62...`).

### A3. Jalankan
```bash
cd 3-reminder-tagihan-vps/web
sudo docker compose up -d --build
```

### A4. Cek
```bash
curl -I http://localhost/            # harus 200
curl -I http://localhost/isolir.html # harus 200
```
Dari browser: `http://IP-VPS/` dan `http://IP-VPS/isolir.html`.

> Kalau port 80 VPS sudah dipakai, ubah `docker-compose.yml` baris `ports`
> jadi `"8080:80"`, dan pakai `IP-VPS:8080` di setting MikroTik nanti.

### A5. (Opsional) Update otomatis tiap ganti halaman
Lihat [`web/deploy-vps.yml.example`](web/deploy-vps.yml.example) untuk CI/CD
GitHub Actions (push → auto-deploy ke VPS). Kalau tidak, update manual:
```bash
cd ~/mikrotik-wisp-tools && git pull
cd 3-reminder-tagihan-vps/web && sudo docker compose up -d --build
```

---

## Bagian B — Setup reminder di MikroTik

### B1. Sesuaikan alamat halaman
Buka [`mikrotik/setup-walled-garden.rsc`](mikrotik/setup-walled-garden.rsc).
Ganti **IP-VPS-ANDA** (muncul 2×) dengan IP/domain VPS Anda:
```rsc
:local redirectUrl "IP-VPS-ANDA/"
...
/ip proxy access add comment="wg-allow-vps" dst-host="IP-VPS-ANDA" action=allow
```

### B2. Jalankan setup (sekali)
Upload file ke **Files** MikroTik, lalu di **New Terminal**:
```rsc
/import file-name=setup-walled-garden.rsc
```
Ini menyalakan web-proxy dan menyiapkan aturan pengalihan.

---

## Bagian C — Isi tanggal jatuh tempo

Sistem tahu kapan jatuh tempo pelanggan dari **comment** di `/ppp secret`.
Tambahkan `DUE:` diikuti **tanggal** (pakai 1–28).

Di **PPP → Secrets**, klik pelanggan, isi **Comment**, contoh:
```
Budi RT03 - 20Mbps | DUE:15
```
Artinya jatuh tempo **tanggal 15** tiap bulan. Reminder muncul tanggal **14** (H-1).

Via terminal:
```rsc
/ppp secret set [find name=budi] comment="Budi RT03 - 20Mbps | DUE:15"
```

### Pasang penjadwal (sekali)
Upload [`mikrotik/billing-scheduler.rsc`](mikrotik/billing-scheduler.rsc) →
**System → Scripts → Add**, nama `billing-scheduler`, tempel isinya. Lalu:
```rsc
/system scheduler
add name=billing-scheduler interval=1h \
    on-event="/system script run billing-scheduler" \
    comment="Isi daftar reminder tagihan"
```
Tes manual:
```rsc
/system script run billing-scheduler
/ip firewall address-list print where list="tagihan-reminder"
```

---

## Bagian D — Isolir (blokir + halaman)

### D1. Sesuaikan & jalankan setup
Buka [`mikrotik/setup-isolir.rsc`](mikrotik/setup-isolir.rsc), sesuaikan:
```rsc
:local redirectUrl "IP-VPS-ANDA/isolir.html"
:local pageIp      "IP-VPS-ANDA"
:local isolirNet   "10.1.1.0/24"   ;# subnet pool isolir-mu; cek: /ip pool print
```
> **Cara tahu subnet isolir:** jalankan `/ip pool print`, lihat pool yang dipakai
> profil isolir. Kalau range-nya `10.1.1.2-10.1.1.254`, subnetnya `10.1.1.0/24`.

Lalu import (sekali):
```rsc
/import file-name=setup-isolir.rsc
```
Ini memblokir internet subnet isolir kecuali DNS + halaman, dan mengarahkan semua
HTTP mereka ke halaman isolir.

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
Setelah reconnect, pelanggan isolir mendapat IP subnet isolir → semua halaman
menjadi halaman isolir; balikin profil → normal lagi otomatis.

**Kapan halaman isolir muncul?** Terus-menerus **selama** profil pelanggan = isolir,
setiap kali menyambung wifi.

---

## Bagian E — Kecualikan pelanggan tertentu

Agar pelanggan tertentu **tidak pernah** melihat halaman reminder (mis. instansi
yang bayar 3 bulan sekali), ada 2 cara — pilih salah satu:

**Cara A — tag `SKIP` di comment:**
```rsc
/ppp secret set [find name=kantor-desa] comment="Kantor Desa - per 3 bln SKIP"
```

**Cara B — daftar nama di script** (tanpa mengubah comment). Buka
`billing-scheduler.rsc`, isi:
```rsc
:local excludeNames ",kantor-desa,sekolah-01,puskesmas,"
```
(nama dipisah koma, **diapit koma** di awal & akhir).

---

## Tugas sehari-hari (contekan cepat)

| Mau… | Lakukan |
|------|---------|
| **Ganti tanggal tagihan** pelanggan | Edit comment: ubah angka setelah `DUE:` (mis. `DUE:20`) |
| **Isolir** pelanggan | `set [find name=X] profile=ISOLIR` lalu `/ppp active remove [find name=X]` |
| **Aktifkan lagi** | `set [find name=X] profile=PAKET...` lalu `/ppp active remove [find name=X]` |
| **Kecualikan** dari reminder | Tambah `SKIP` di comment, atau masukkan nama ke `excludeNames` |
| **Ganti nomor WA / teks halaman** | Edit `docs/index.html` & `docs/isolir.html`, deploy ulang (Bagian A5) |

---

## Batasan penting

- **HTTPS tidak bisa dialihkan.** Situs `https://` (mayoritas situs) tidak akan
  ke-redirect saat dibuka langsung — itu batasan semua captive portal (termasuk
  wifi.id). Yang memunculkan popup adalah **cek-koneksi HTTP** otomatis HP, yang
  sering terjadi tiap menyambung wifi. Jadi popup tetap muncul, hanya tidak "di
  tengah-tengah" saat orang sedang buka situs HTTPS.
- **Butuh kepastian 100%?** Kombinasikan dengan notifikasi (mis. Telegram — sudah
  ada opsinya di `billing-scheduler.rsc`).

---

## Kalau ada masalah

| Gejala | Solusi |
|--------|--------|
| Halaman reminder tak muncul | Cek IP pelanggan ada di daftar: `/ip firewall address-list print where list="tagihan-reminder"`. Pastikan web-proxy nyala: `/ip proxy print`. |
| Halaman isolir tak kebuka | Pastikan IP VPS ada di `ALLOW-ISOLIR` & `iso-allow-page` di atas `iso-redirect`. Cek VPS online. |
| Semua orang ke-redirect | NAT `wg-reminder-redirect` harus pakai `src-address-list=tagihan-reminder`, bukan semua. |
| Situs HTTPS tak ke-redirect | Memang tidak bisa; andalkan cek-koneksi HTTP + Telegram. |
| Pelanggan sudah bayar tapi masih kena reminder | Reminder hanya H-1; besoknya (hari-H) sudah tidak muncul. Untuk berhenti seketika, hapus IP-nya dari `tagihan-reminder`. |

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

# matikan proxy kalau tidak dipakai lagi
/ip proxy set enabled=no
```
Di VPS: `cd 3-reminder-tagihan-vps/web && sudo docker compose down`.
