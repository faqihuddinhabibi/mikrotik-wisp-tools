# mikrotik-wisp-tools

Kumpulan tools untuk WISP kecil berbasis **PPPoE** di MikroTik, tanpa container,
100% dikontrol dari **Winbox / terminal RouterOS**.

## Perangkat & versi (target yang sudah diuji-rancang untuk ini)

| Item | Nilai |
|------|-------|
| Hardware | HP ProDesk 600 G5 SFF |
| CPU | Intel Core i7-9700 |
| Arsitektur | x86 (RouterOS x86 / CHR) |
| RouterOS | 7.24.2 |
| Topologi customer | Tiap rumah punya router sendiri yang **dial PPPoE** ke MikroTik ini |

> Karena customer dial PPPoE, **semua trafik mereka lewat interface PPPoE di MikroTik**.
> Jadi MikroTik tetap bisa melihat & me-redirect trafik HTTP mereka walaupun mereka
> pakai router sendiri di rumah.

## Isi repo

### 📁 [01-pppoe-profile-telegram](01-pppoe-profile-telegram/)
Kirim notifikasi **Telegram** setiap kali **profile** sebuah user PPPoE berubah
(misal `aktif` → `isolir`). RouterOS tidak punya event bawaan untuk "profile diedit",
jadi ini pakai scheduler yang mengecek berkala. Lihat README di dalam folder.

### 📁 [02-reminder-tagihan-walled-garden](02-reminder-tagihan-walled-garden/)
Saat customer terhubung dan **hari-H / H-1 jatuh tempo**, trafik HTTP mereka
di-redirect otomatis ke **halaman pengingat tagihan** (mirip splash page wifi.id).
Pakai **web-proxy bawaan RouterOS** + **address-list** + **scheduler**. Tanpa container.
Halaman di-host di **GitHub Pages** (folder [`docs/`](docs/)).

### 📁 [docs](docs/)
Halaman HTML yang tampil ke customer, di-host lewat GitHub Pages:
- `index.html` — halaman pengingat tagihan (H-1 & hari-H)
- `besok.html` — (opsional) versi khusus "besok jatuh tempo"
- `isolir.html` — (opsional) halaman "internet diisolir, tagihan belum dibayar"

URL setelah GitHub Pages aktif:
`https://faqihuddinhabibi.github.io/mikrotik-wisp-tools/`

## Urutan pemasangan yang disarankan

1. Baca & pasang **01** dulu (paling gampang, langsung kelihatan hasilnya di Telegram).
2. Aktifkan **GitHub Pages** (lihat langkah di README folder 02).
3. Edit halaman di `docs/` sesuai nama usaha & kontak WA-mu.
4. Pasang **02** (walled-garden reminder).

## Konvensi comment di `/ppp secret`

Tools ini menyimpan data billing di **comment** tiap secret. Format bebas, yang penting
ada token `DUE:` diikuti tanggal jatuh tempo (1–28). Contoh comment:

```
Budi RT03 - Paket 20Mbps | DUE:15
```

Artinya: pelanggan "Budi", jatuh tempo **tanggal 15** tiap bulan.

- Script **billing** (folder 02) hanya **membaca** `DUE:` dari comment — tidak pernah menimpanya.
- Script **profile-watch** (folder 01) tidak menyentuh comment sama sekali (state disimpan di RAM).

> Gunakan tanggal **1–28** agar logika H-1 aman di semua bulan (hindari 29/30/31).
