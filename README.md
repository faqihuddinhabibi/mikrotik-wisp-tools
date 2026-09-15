# mikrotik-wisp-tools

Kumpulan alat praktis untuk **WISP / RT-RW Net berbasis PPPoE** di MikroTik —
**tanpa aplikasi billing berbayar, tanpa server, tanpa RADIUS, dikontrol dari Winbox**.

1. **Notif profil berubah** — pesan Telegram saat profil pelanggan diubah
   (mis. diisolir/diaktifkan), pelanggan baru, pelanggan dihapus. *(Alat 1)*
2. **Reminder tagihan + isolir** — halaman pengingat muncul di HP pelanggan sehari
   sebelum jatuh tempo (mirip splash page wifi.id), **+ isolir** (blokir + halaman
   "silakan bayar"). Halaman isolir disimpan **di dalam MikroTik**, halaman reminder
   di **GitHub Pages** (gratis). *(Alat 2)*

Berjalan di **RouterOS 7.x** (diuji di perangkat x86). Cocok untuk jaringan kecil
yang ingin otomatisasi sederhana tanpa server.

---

## Tampilan halaman

<p>
<img src="screenshots/reminder.png" width="240" alt="Halaman pengingat tagihan (H-1)">
&nbsp;&nbsp;
<img src="screenshots/isolir.png" width="240" alt="Halaman isolir">
</p>

**Lihat langsung (demo):** reminder H-1 → https://faqihuddinhabibi.github.io/mikrotik-wisp-tools/

> Nomor WhatsApp & teks bisa Anda ganti sendiri (lihat README tiap folder).

---

## Isi repo

```
mikrotik-wisp-tools/
├── docs/
│   └── index.html                 Halaman reminder H-1 (di-host di GitHub Pages)
│
├── 1-notif-profil-pppoe/          ALAT 1 — notif Telegram saat profil berubah
│   ├── README.md                  (panduan lengkap langkah demi langkah)
│   └── pppoe-profile-watch.rsc
│
├── 2-reminder-isolir/             ALAT 2 — reminder H-1 + isolir, tanpa server
│   ├── README.md
│   ├── setup-reminder-isolir.rsc  (sekali jalan: web-proxy, pengalihan, blokir isolir)
│   ├── billing-scheduler.rsc      (scheduler 1 jam: siapa yang H-1 hari ini)
│   └── error.html                 (halaman isolir → Files/webproxy/ di router)
│
├── LICENSE
└── README.md
```

---

## Mulai dari mana?

1. Pasang **[Alat 1](1-notif-profil-pppoe)** dulu — paling mudah, hasilnya langsung
   kelihatan di Telegram.
2. Lanjut **[Alat 2](2-reminder-isolir)** untuk reminder + isolir, ikuti README
   dari atas sampai bawah.

Semua panduan ditulis langkah demi langkah untuk pemula.

---

## Konvensi comment `/ppp secret`

Data tagihan disimpan di **comment** tiap pelanggan (bebas formatnya, asal ada
token berikut):

| Token | Arti | Contoh comment |
|-------|------|----------------|
| `DUE:NN` | Tanggal jatuh tempo (pakai **1–28**) | `Budi RT03 - 20Mbps \| DUE:15` |
| `SKIP` | Jangan pernah tampilkan halaman reminder ke user ini | `Kantor Desa - per 3 bln SKIP` |

- Reminder muncul **H-1** (sehari sebelum `DUE`). `DUE:1` → hari terakhir bulan sebelumnya.
- Script hanya **membaca** comment, tidak menimpanya.

---

## Batasan penting (baca sebelum pasang)

- **HTTPS tidak bisa dialihkan.** Situs `https://` tidak akan ke-redirect saat
  dibuka langsung — ini batasan **semua** captive portal (termasuk wifi.id). Yang
  memunculkan popup adalah **cek-koneksi HTTP** otomatis HP tiap menyambung wifi.
- Untuk kepastian ekstra, ada opsi notifikasi **Telegram** di script reminder.
- Pelanggan pakai router sendiri (dial PPPoE)? Tetap jalan — trafik lewat MikroTik.

---

## Lisensi

[MIT](LICENSE) — bebas dipakai, diubah, dan disebarkan. Semoga bermanfaat untuk
teman-teman WISP/RT-RW Net lain. Kontribusi & saran dipersilakan lewat Issues/PR.
