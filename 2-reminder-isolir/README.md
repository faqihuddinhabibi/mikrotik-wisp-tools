# 2 · Reminder Tagihan (H-1) + Isolir — tanpa server

Menampilkan **halaman pengingat tagihan** di HP pelanggan (mirip splash page wifi.id)
**sehari sebelum jatuh tempo**, plus **halaman isolir** untuk pelanggan yang diblokir
karena belum bayar.

**Tanpa VPS, tanpa container.** Dua halaman, dua tempat:
- **Halaman isolir** → disimpan **di dalam MikroTik** (fitur halaman error web-proxy).
- **Halaman reminder** → di **GitHub Pages** (gratis, otomatis dari repo ini).

### Beginilah tampilannya

<p>
<img src="../screenshots/reminder.png" width="230" alt="Halaman pengingat tagihan">
&nbsp;&nbsp;
<img src="../screenshots/isolir.png" width="230" alt="Halaman isolir">
</p>

Lihat langsung halaman reminder: https://faqihuddinhabibi.github.io/mikrotik-wisp-tools/

---

## Daftar isi
- [Apa yang Anda dapat](#apa-yang-anda-dapat)
- [Cara kerja (wajib paham)](#cara-kerja-wajib-paham)
- [Yang perlu disiapkan](#yang-perlu-disiapkan)
- [Bagian A — Halaman reminder di GitHub Pages](#bagian-a--halaman-reminder-di-github-pages)
- [Bagian B — Halaman isolir ke dalam MikroTik](#bagian-b--halaman-isolir-ke-dalam-mikrotik)
- [Bagian C — Jalankan setup di MikroTik](#bagian-c--jalankan-setup-di-mikrotik)
- [Bagian D — Penjadwal reminder](#bagian-d--penjadwal-reminder)
- [Bagian E — Isi tanggal jatuh tempo](#bagian-e--isi-tanggal-jatuh-tempo)
- [Bagian F — Cara meng-isolir & mengaktifkan lagi](#bagian-f--cara-meng-isolir--mengaktifkan-lagi)
- [Bagian G — Kecualikan pelanggan tertentu](#bagian-g--kecualikan-pelanggan-tertentu)
- [Tugas sehari-hari (contekan cepat)](#tugas-sehari-hari-contekan-cepat)
- [Keamanan](#keamanan)
- [Batasan penting](#batasan-penting)
- [Kalau ada masalah](#kalau-ada-masalah)
- [Cara mencopot](#cara-mencopot)

---

## Apa yang Anda dapat

- **Reminder H-1 otomatis.** Sehari sebelum jatuh tempo, saat pelanggan menyambung
  wifi, HP-nya memunculkan popup "tagihan jatuh tempo besok". Internet mereka
  **tetap menyala** — hanya diingatkan.
- **Isolir.** Pelanggan yang telat → teknisi ganti profilnya jadi profil isolir →
  internet **diblokir total**, semua halaman diarahkan ke "layanan dinonaktifkan,
  segera bayar".
- **Pengecualian.** Pelanggan tertentu (mis. instansi yang bayar 3 bulan sekali)
  tidak pernah melihat reminder.
- **Opsional:** ringkasan Telegram "siapa saja yang H-1 hari ini".

---

## Cara kerja (wajib paham)

```
REMINDER (H-1)
  scheduler tiap 1 jam  →  baca "DUE:tanggal" dari comment tiap pelanggan
        │  kalau BESOK jatuh tempo & pelanggan sedang online
        ▼
  IP pelanggan masuk daftar "tagihan-reminder" (2 jam)
        │
        ▼
  HTTP mereka dibelokkan ke web-proxy  →  proxy jawab "pindah ke halaman GitHub Pages"
        │
        ▼
  HP memunculkan popup halaman reminder

ISOLIR
  profil pelanggan = ISOLIR  →  dapat IP dari pool isolir (mis. 10.1.1.x)
        │
        ▼
  semua internet diblokir, KECUALI DNS + HTTP yang dibelokkan ke web-proxy
        │
        ▼
  proxy MENOLAK (deny)  →  menampilkan file error.html = halaman isolir
```

**Kenapa popup muncul sendiri?** HP (Android/iOS) tiap menyambung wifi otomatis
menembak alamat cek-koneksi lewat **HTTP**. MikroTik menangkap itu → muncul
notifikasi "Sign in to network", persis seperti wifi.id.

**Kenapa isolir tidak butuh server?** RouterOS punya fitur "halaman error" untuk
web-proxy: file `webproxy/error.html` di **Files**. Kita isi file itu dengan halaman
isolir. Satu file, selesai.

**Kenapa reminder butuh GitHub Pages?** Halaman error proxy cuma **satu**, sudah
dipakai isolir. Halaman reminder butuh tempat kedua → GitHub Pages (gratis, tanpa
server, otomatis update dari repo).

> Pelanggan memakai router sendiri (dial PPPoE)? **Tetap jalan** — semua trafik
> mereka lewat MikroTik.

---

## Yang perlu disiapkan

- Akses **MikroTik** (Winbox), RouterOS 7.x. Router bisa akses internet.
- Akun **GitHub** (gratis) — untuk halaman reminder.
- Profil **isolir** + **pool IP terpisah** untuk isolir (cek: `/ip pool print`).
- Nomor **WhatsApp admin** untuk tombol di halaman.

---

## Bagian A — Halaman reminder di GitHub Pages

Halaman reminder = file `docs/index.html` di repo ini. Anda perlu **salinan repo
sendiri** supaya nomor WA-nya punya Anda.

1. Buka https://github.com/faqihuddinhabibi/mikrotik-wisp-tools → klik **Fork**
   (kanan atas) → **Create fork**. Sekarang Anda punya
   `github.com/USERNAME/mikrotik-wisp-tools`.
2. Di fork Anda, buka file `docs/index.html` → klik ikon **pensil** (Edit).
3. Cari baris `<!-- GANTI: nomor WA -->`, ganti `6281234567890` dengan nomor WA
   admin (format `62…`, tanpa `+`, tanpa `0` di depan). Boleh ganti teks juga.
4. **Commit changes** (tombol hijau).
5. Nyalakan GitHub Pages: **Settings** (tab repo) → menu kiri **Pages** →
   **Build and deployment** → Source: **Deploy from a branch** → Branch: **main**,
   folder: **/docs** → **Save**.
6. Tunggu ±1 menit, refresh. Muncul alamat:
   `https://USERNAME.github.io/mikrotik-wisp-tools/`
   Buka di HP → halaman reminder tampil dengan nomor WA Anda. **Catat alamat ini.**

> Update teks/nomor nanti: edit file di GitHub → Commit → 1 menit kemudian live.

---

## Bagian B — Halaman isolir ke dalam MikroTik

Halaman isolir = file [`error.html`](error.html) di folder ini. Harus masuk ke
**Files → `webproxy/error.html`** di router.

**B1. Ganti nomor WA** — di fork Anda, edit `2-reminder-isolir/error.html`, cari
`<!-- GANTI: nomor WA -->`, ganti nomornya → Commit.

**B2. Buat folder `webproxy` di router** (sekali):
1. 🪟 Winbox → **IP → Web Proxy** → tombol **Settings**.
2. Centang **Enabled** → **Apply**.
3. Klik tombol **Reset HTML** → **Yes**. Ini membuat folder `webproxy/` berisi
   halaman error bawaan.
4. Cek: 🪟 **Files** → ada folder `webproxy` berisi `error.html`.

**B3. Timpa `error.html` dengan halaman isolir** — pilih salah satu:

**Cara 1 — tarik dari GitHub (paling mudah).** 🪟 **New Terminal**, ganti `USERNAME`:
```rsc
/tool fetch url="https://raw.githubusercontent.com/USERNAME/mikrotik-wisp-tools/main/2-reminder-isolir/error.html" dst-path=webproxy/error.html
```
Harus keluar `status: finished`. Ulangi perintah ini setiap kali Anda mengubah
halaman isolir di GitHub.

**Cara 2 — upload manual.** Download `error.html` ke komputer → 🪟 **Files** →
**double-click folder `webproxy`** → drag-drop file ke jendela itu (menimpa yang lama).

**Cek:** 🪟 Files → `webproxy/error.html` ukurannya ±5,6 KB (bawaan hanya ±1 KB).

---

## Bagian C — Jalankan setup di MikroTik

Satu script menyiapkan semuanya: web-proxy, aturan pengalihan, blokir isolir.

**C1. Sesuaikan 3 baris** di [`setup-reminder-isolir.rsc`](setup-reminder-isolir.rsc):
```rsc
:local pageHost  "USERNAME.github.io"                       ;# TANPA "/" di akhir
:local pageUrl   "USERNAME.github.io/mikrotik-wisp-tools/"  ;# ADA "/" di akhir, TANPA "http://"
:local isolirNet "10.1.1.0/24"                              ;# subnet pool isolir Anda
```
- `USERNAME` = username GitHub Anda (dari alamat di Bagian A).
- `isolirNet`: jalankan `/ip pool print`, lihat pool yang dipakai profil isolir.
  Range `10.1.1.2-10.1.1.254` → subnet `10.1.1.0/24`.

**C2. Upload & jalankan (sekali):**
1. 🪟 **Files** → drag-drop `setup-reminder-isolir.rsc` (ke root, bukan ke folder).
2. 🪟 **New Terminal**:
   ```rsc
   /import file-name=setup-reminder-isolir.rsc
   ```
   Harus keluar `Selesai. ...` dan `Script file loaded and executed successfully`.

> Aman dijalankan ulang (kalau ganti alamat, dsb.) — aturan lama dihapus dulu.

**C3. Cek hasilnya:**
```rsc
/ip proxy access print
```
Harus ada **3 baris urut**: `iso-deny`, `wg-allow-page`, `wg-redirect`.
Urutan ini penting: isolir dicek dulu, lalu izin host halaman (mencegah loop),
baru pengalihan reminder.

---

## Bagian D — Penjadwal reminder

1. Buka [`billing-scheduler.rsc`](billing-scheduler.rsc). Opsional: isi `botToken`
   & `chatId` kalau ingin ringkasan Telegram (kosong = tidak kirim).
2. 🪟 **System → Scripts → Add (+)**. **Name:** `billing-scheduler`, tempel isinya
   ke **Source** → **OK**.
3. 🪟 **New Terminal**, pasang scheduler (1 baris):
   ```rsc
   /system scheduler add name=billing-scheduler interval=1h on-event="/system script run billing-scheduler" comment="Isi daftar reminder tagihan H-1"
   ```
4. Tes manual:
   ```rsc
   /system script run billing-scheduler
   /ip firewall address-list print where list="tagihan-reminder"
   ```
   Kalau hari ini ada pelanggan H-1 yang online → IP-nya muncul di daftar.

---

## Bagian E — Isi tanggal jatuh tempo

Sistem tahu jatuh tempo dari **comment** di `/ppp secret`: tulis `DUE:` diikuti
tanggal (**1–28**).

🪟 **PPP → Secrets** → double-click pelanggan → kolom **Comment**, contoh:
`Budi RT03 - 20Mbps | DUE:15` → **OK**.

Artinya jatuh tempo **tanggal 15**. Reminder muncul **tanggal 14** (H-1).
`DUE:1` → reminder muncul di **hari terakhir bulan sebelumnya** (30/31, otomatis).

**Uji coba cepat:** set `DUE:` seorang pelanggan = **besok**, jalankan
`/system script run billing-scheduler`, lalu di HP pelanggan itu matikan-nyalakan
wifi → popup reminder muncul. Setelah tes, kembalikan `DUE:`-nya dan hapus dari
daftar: `/ip firewall address-list remove [find list="tagihan-reminder"]`.

---

## Bagian F — Cara meng-isolir & mengaktifkan lagi

Lewat Winbox, tanpa perintah.

**Meng-ISOLIR (belum bayar):**
1. 🪟 **PPP → Secrets** → double-click pelanggan.
2. Kolom **Profile** → pilih profil isolir (mis. `ISOLIR`) → **OK**.
3. Tab **Active Connections** → klik pelanggan itu → tombol **–** (putus sesi).
   Ia menyambung ulang otomatis dengan IP isolir.

**Meng-AKTIFKAN lagi (sudah bayar):**
1. **PPP → Secrets** → double-click → **Profile** = paket semula (mis. `PAKET100`) → **OK**.
2. **Active Connections** → pilih → tombol **–**.

> Kenapa harus putus sesi? Supaya langsung dapat IP sesuai profil baru. Kalau tidak,
> berlaku saat ia reconnect sendiri.

**Kapan halaman isolir muncul?** Terus-menerus selama profil = isolir, setiap
menyambung wifi / membuka situs HTTP.

> Pasang juga [Alat 1](../1-notif-profil-pppoe) supaya tiap isolir/aktif tercatat
> ke Telegram.

---

## Bagian G — Kecualikan pelanggan tertentu

Supaya pelanggan tertentu **tidak pernah** kena reminder — pilih salah satu:

**Cara A — tag `SKIP` di comment (Winbox):** tambahkan kata `SKIP` di Comment.
Contoh: `Kantor Desa - per 3 bln SKIP`.

**Cara B — daftar nama di script:** di `billing-scheduler.rsc`:
```rsc
:local excludeNames ",kantor-desa,sekolah-01,puskesmas,"
```
(dipisah koma, **diapit koma** di awal & akhir.)

---

## Tugas sehari-hari (contekan cepat)

| Mau… | Lakukan |
|------|---------|
| **Ganti tanggal tagihan** | PPP → Secrets → double-click → ubah angka `DUE:` di Comment |
| **Isolir** | PPP → Secrets → Profile = `ISOLIR`; lalu Active Connections → **–** |
| **Aktifkan lagi** | PPP → Secrets → Profile = paket semula; lalu Active Connections → **–** |
| **Kecualikan** dari reminder | tambah `SKIP` di Comment |
| **Ganti teks / nomor WA reminder** | edit `docs/index.html` di GitHub → Commit (live ±1 menit) |
| **Ganti teks / nomor WA isolir** | edit `2-reminder-isolir/error.html` di GitHub → Commit → jalankan lagi `/tool fetch ...` dari Bagian B3 |

---

## Keamanan

Web-proxy mendengar di port **8080**. Aturan `wg-redirect` (deny) membuatnya tidak
bisa dipakai sebagai proxy terbuka, tapi lebih aman tutup dari internet. Ganti
`ether1` dengan interface WAN Anda:
```rsc
/ip firewall filter add chain=input protocol=tcp dst-port=8080 in-interface=ether1 action=drop comment="tutup proxy dari WAN" place-before=0
```

---

## Batasan penting

- **HTTPS tidak bisa dialihkan.** Situs `https://` (mayoritas) tidak ke-redirect
  saat dibuka langsung — batasan semua captive portal (termasuk wifi.id). Yang
  memunculkan popup adalah **cek-koneksi HTTP** otomatis HP tiap menyambung wifi.
  Untuk kepastian, nyalakan opsi Telegram di `billing-scheduler.rsc`.
- Halaman isolir tidak bisa memuat gambar/font dari luar (RouterOS hanya
  mengirim 1 file teks). `error.html` sudah dibuat mandiri — kalau mengedit,
  jangan tambah `<img src="http…">` atau `<link>` ke luar.
- Reminder hanya untuk pelanggan yang **online** saat scheduler jalan (tiap jam).
  Yang offline seharian tidak dapat popup (tapi tetap masuk ringkasan Telegram
  kalau online di jam lain).

---

## Kalau ada masalah

| Gejala | Solusi |
|--------|--------|
| Popup reminder tidak muncul | `/ip firewall address-list print where list="tagihan-reminder"` — IP pelanggan harus ada. Kosong? Cek `DUE:` = besok & pelanggan online. `/ip proxy print` → `enabled: yes`. |
| Popup muncul tapi halaman putih / loop | `pageHost` di `wg-allow-page` harus **sama persis** dengan host di `pageUrl` (mis. `USERNAME.github.io`). Cek `/ip proxy access print`. Buka `http://USERNAME.github.io/mikrotik-wisp-tools/` dari HP biasa — harus tampil. |
| Halaman isolir masih bawaan MikroTik ("ERROR: Forbidden") | `error.html` belum tertimpa. Cek ukuran di Files → `webproxy/error.html` (±5,6 KB). Ulangi Bagian B3. |
| Pelanggan isolir tidak dapat halaman apa pun | DNS harus jalan: `iso-allow-dns` harus **di atas** `iso-drop` (`/ip firewall filter print`). Kalau ada aturan `forward` lain yang drop lebih dulu, pindahkan `iso-*` ke atas. |
| Semua orang ke-redirect | NAT `wg-redirect80` harus `src-address-list=tagihan-reminder`. Jangan dihapus `src-address-list`-nya. |
| Pelanggan sudah bayar tapi masih kena reminder | Reminder hanya H-1, maksimal 2 jam setelah bayar. Hentikan seketika: `/ip firewall address-list remove [find list="tagihan-reminder" comment=NAMA]`. |
| `/import` error "syntax error" | File rusak karena tanda kutip keriting (copy dari editor teks). Download ulang file asli / pakai tombol **Raw** di GitHub. |

---

## Cara mencopot
```rsc
/system scheduler remove [find name=billing-scheduler]
/system script remove [find name=billing-scheduler]
/ip firewall nat remove [find comment~"^wg-"]
/ip firewall nat remove [find comment~"^iso-"]
/ip firewall filter remove [find comment~"^iso-"]
/ip proxy access remove [find comment~"^wg-"]
/ip proxy access remove [find comment~"^iso-"]
/ip firewall address-list remove [find list="tagihan-reminder"]
/ip proxy set enabled=no
```
Halaman GitHub Pages boleh dibiarkan (tidak berpengaruh) atau matikan di
**Settings → Pages → Source: None**.
