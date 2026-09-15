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

Halaman reminder = file `docs/index.html`. GitHub Pages menyajikannya langsung
dari repo, jadi file ini harus ada di repo **milik Anda**.

1. Buka https://github.com/faqihuddinhabibi/mikrotik-wisp-tools → **Fork** (kanan
   atas) → **Create fork**. Sekarang Anda punya `github.com/USERNAME/mikrotik-wisp-tools`.
2. Ambil ke komputer: **Code → Download ZIP** (atau `git clone`), ekstrak.
3. Buka `docs/index.html` dengan editor teks (Notepad / VS Code). Cari
   `<!-- GANTI: nomor WA -->`, ganti `6281234567890` dengan nomor WA admin
   (format `62…`, tanpa `+`, tanpa `0` di depan). Boleh ganti teks juga. Simpan.
4. Kirim balik ke GitHub: di halaman repo Anda buka folder `docs` → **Add file →
   Upload files** → seret `index.html` → **Commit changes**. (Kalau pakai git:
   `git add`, `git commit`, `git push`.)
5. Nyalakan GitHub Pages: **Settings** (tab repo) → menu kiri **Pages** →
   **Build and deployment** → Source: **Deploy from a branch** → Branch: **main**,
   folder: **/docs** → **Save**.
6. Tunggu ±1 menit, refresh. Muncul alamat:
   `https://USERNAME.github.io/mikrotik-wisp-tools/`
   Buka di HP → halaman reminder tampil dengan nomor WA Anda. **Catat alamat ini.**

> Nomor WA di halaman ini memang **publik** — siapa pun yang membuka halaman
> melihatnya (itu fungsi tombolnya). Pakai nomor WA bisnis/admin, bukan pribadi.
> Update teks/nomor nanti: edit di komputer → upload/push lagi → 1 menit live.

---

## Bagian B — Halaman isolir ke dalam MikroTik

Halaman isolir = file [`error.html`](error.html) di folder ini. Harus masuk ke
**Files → `webproxy/error.html`** di router.

Halaman ini **tidak lewat GitHub** — dari komputer langsung ke router.

**B1. Ganti nomor WA** — di komputer, buka `2-reminder-isolir/error.html` dengan
editor teks, cari `<!-- GANTI: nomor WA -->`, ganti nomornya. Simpan.

**B2. Buat folder `webproxy` di router** (sekali):
1. 🪟 Winbox → **IP → Web Proxy** → tombol **Settings**.
2. Centang **Enabled** → **Apply**.
3. Klik tombol **Reset HTML** → **Yes**. Ini membuat folder `webproxy/` berisi
   halaman error bawaan.
4. Cek: 🪟 **Files** → ada folder `webproxy` berisi `error.html`.

**B3. Timpa `error.html` dengan halaman isolir:**
1. 🪟 **Files** → **double-click folder `webproxy`** (masuk ke dalamnya).
2. Seret (drag-drop) `error.html` dari komputer ke jendela Files itu. File lama
   tertimpa.
3. **Cek:** `webproxy/error.html` ukurannya ±5,6 KB (bawaan hanya ±1 KB). Kalau
   masih ±1 KB, file masuk ke root — hapus, ulangi dari langkah 1.

> Alternatif kalau drag ke dalam folder tidak bisa: taruh `error.html` di fork
> GitHub Anda, lalu di **New Terminal**:
> `/tool fetch url="https://raw.githubusercontent.com/USERNAME/mikrotik-wisp-tools/main/2-reminder-isolir/error.html" dst-path=webproxy/error.html`

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
2. 🪟 **New Terminal** (satu-satunya langkah terminal — script ini memasang 9
   aturan sekaligus, lebih aman daripada klik satu per satu):
   ```rsc
   /import file-name=setup-reminder-isolir.rsc
   ```
   Harus keluar `Selesai. ...` dan `Script file loaded and executed successfully`.

> Aman dijalankan ulang (kalau ganti alamat, dsb.) — aturan lama dihapus dulu.

**C3. Cek hasilnya** — 🪟 **IP → Web Proxy** → tab **Access**. Harus ada **3 baris
urut**: `iso-deny`, `wg-allow-page`, `wg-redirect`. Urutan ini penting: isolir
dicek dulu, lalu izin host halaman (mencegah loop), baru pengalihan reminder.
Lalu 🪟 **IP → Firewall** → tab **NAT** ada `iso-redirect80` & `wg-redirect80`;
tab **Filter Rules** ada `iso-allow-dns`, `iso-allow-dns-tcp`, `iso-drop`.

---

## Bagian D — Penjadwal reminder

1. Buka [`billing-scheduler.rsc`](billing-scheduler.rsc) di komputer. Opsional:
   isi `botToken` & `chatId` kalau ingin ringkasan Telegram (kosong = tidak kirim).
2. 🪟 **System → Scripts → Add (+)**. **Name:** `billing-scheduler`, tempel isinya
   ke **Source** → **OK**.
3. 🪟 **System → Scheduler → Add (+)**:
   - **Name:** `billing-scheduler`
   - **Interval:** `01:00:00`
   - **On Event:** `/system script run billing-scheduler`
   - **OK**.
4. Tes manual: 🪟 **System → Scripts** → klik `billing-scheduler` → tombol
   **Run Script**. Lalu 🪟 **IP → Firewall** → tab **Address Lists** → cari list
   `tagihan-reminder`. Kalau hari ini ada pelanggan H-1 yang online → IP-nya ada.

---

## Bagian E — Isi tanggal jatuh tempo

Sistem tahu jatuh tempo dari **comment** di `/ppp secret`: tulis `DUE:` diikuti
tanggal (**1–28**).

🪟 **PPP → Secrets** → double-click pelanggan → kolom **Comment**, contoh:
`Budi RT03 - 20Mbps | DUE:15` → **OK**.

Artinya jatuh tempo **tanggal 15**. Reminder muncul **tanggal 14** (H-1).
`DUE:1` → reminder muncul di **hari terakhir bulan sebelumnya** (30/31, otomatis).

**Uji coba cepat:** set `DUE:` seorang pelanggan = **besok** → 🪟 System → Scripts →
`billing-scheduler` → **Run Script** → di HP pelanggan itu matikan-nyalakan wifi →
popup reminder muncul. Setelah tes, kembalikan `DUE:`-nya, lalu 🪟 IP → Firewall →
Address Lists → pilih baris `tagihan-reminder` miliknya → tombol **–**.

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
| **Ganti teks / nomor WA reminder** | edit `docs/index.html` di komputer → upload/push ke GitHub (live ±1 menit) |
| **Ganti teks / nomor WA isolir** | edit `error.html` di komputer → Winbox Files → masuk folder `webproxy` → drag file (Bagian B3) |

---

## Keamanan

Web-proxy mendengar di port **8080**. Aturan `wg-redirect` (deny) membuatnya tidak
bisa dipakai sebagai proxy terbuka, tapi lebih aman tutup dari internet.
🪟 **IP → Firewall → Filter Rules → Add (+)**:
- Tab **General**: Chain `input`, Protocol `tcp`, Dst. Port `8080`,
  In. Interface = interface WAN Anda (mis. `ether1`).
- Tab **Action**: Action `drop`. Comment: `tutup proxy dari WAN` → **OK**.
- Seret aturan ini ke **paling atas** daftar.

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
| Popup reminder tidak muncul | IP → Firewall → **Address Lists**: IP pelanggan harus ada di `tagihan-reminder`. Kosong? Cek `DUE:` = besok & pelanggan online. IP → Web Proxy → Settings: **Enabled** tercentang. |
| Popup muncul tapi halaman putih / loop | `pageHost` di `wg-allow-page` harus **sama persis** dengan host di `pageUrl` (mis. `USERNAME.github.io`). Cek IP → Web Proxy → tab **Access**. Buka `http://USERNAME.github.io/mikrotik-wisp-tools/` dari HP biasa — harus tampil. |
| Halaman isolir masih bawaan MikroTik ("ERROR: Forbidden") | `error.html` belum tertimpa. Cek ukuran di Files → `webproxy/error.html` (±5,6 KB). Ulangi Bagian B3. |
| Pelanggan isolir tidak dapat halaman apa pun | DNS harus jalan: di IP → Firewall → **Filter Rules**, `iso-allow-dns` harus **di atas** `iso-drop`. Kalau ada aturan `forward` lain yang drop lebih dulu, seret `iso-*` ke atasnya. |
| Semua orang ke-redirect | IP → Firewall → NAT → `wg-redirect80` harus punya **Src. Address List** = `tagihan-reminder`. Jangan dikosongkan. |
| Pelanggan sudah bayar tapi masih kena reminder | Reminder hanya H-1, maksimal 2 jam. Hentikan seketika: IP → Firewall → Address Lists → pilih barisnya → **–**. |
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
