# 02 — Reminder Tagihan (Walled-Garden mirip wifi.id)

Saat customer **online** dan **besok jatuh tempo (H-1)**, semua trafik **HTTP**
mereka dibelokkan ke **halaman pengingat tagihan**. Di HP, notifikasi
"Sign in to network" akan muncul sendiri (captive-portal detection) → halaman
kebuka otomatis, mirip splash page wifi.id.

Semua pakai fitur **bawaan RouterOS** (web-proxy + address-list + NAT + scheduler).
**Tanpa container.** Halaman di-host **gratis** di **GitHub Pages**.

---

## Cara kerja (alur)

```
        (tiap 1 jam)
scheduler billing-scheduler.rsc
        │  baca DUE: dari comment tiap /ppp secret
        │  DUE == besok ? (H-1)
        ▼
address-list "tagihan-reminder"  ← IP user online yang besok jatuh tempo
        │
        ▼
NAT: HTTP (port 80) dari list itu  ─redirect→  web-proxy :8080
        │
        ▼
web-proxy access: action=deny redirect-to=github.io/.../  → HALAMAN REMINDER
```

Kenapa jalan walau customer pakai router sendiri? Karena mereka **dial PPPoE**,
jadi seluruh trafiknya lewat MikroTik. Redirect terjadi di sisi MikroTik.

---

## Keterbatasan (baca dulu, penting biar ekspektasi benar)

| Hal | Kenyataan |
|-----|-----------|
| **HTTPS** | Tidak bisa di-redirect (butuh MITM sertifikat). Situs `https://` tetap kebuka normal. |
| **HTTP** | Bisa di-redirect. Ini yang dipakai captive-portal detection HP. |
| **Popup otomatis** | Muncul karena HP/laptop tes koneksi via HTTP ke server deteksi. Sangat sering berhasil, tapi tidak 100% di semua device. |
| **Isolir** | Ini reminder **halus** (internet masih jalan). Untuk blokir total, lihat bagian "Opsional: Isolir". |

Kalau butuh jaminan 100% (misal wajib kelihatan), gabungkan dengan **Telegram**
(folder 01 pola-nya sama) — sudah disiapkan opsional di `billing-scheduler.rsc`.

---

## Langkah pasang

### A. Aktifkan GitHub Pages (host halaman)
1. Repo ini harus **public** (sudah).
2. GitHub → repo **mikrotik-wisp-tools** → **Settings** → **Pages**.
3. **Source**: `Deploy from a branch`. **Branch**: `main`, folder **`/docs`**. **Save**.
4. Tunggu ±1 menit. Halaman tersedia di:
   `https://faqihuddinhabibi.github.io/mikrotik-wisp-tools/`
5. Edit `docs/index.html`: ganti **nama usaha**, **nomor WA**, **info rekening/QRIS**.

> Sudah dibuatkan otomatis lewat CLI saat push pertama. Cek di Settings → Pages
> apakah sudah aktif; kalau belum, ikuti langkah di atas.

### B. Isi tanggal jatuh tempo tiap pelanggan
Tambahkan `DUE:NN` di comment tiap `/ppp secret` (NN = tanggal 1–28):
```rsc
/ppp secret set [find name=budi] comment="Budi RT03 - 20Mbps | DUE:15"
/ppp secret set [find name=siti] comment="Siti - 10Mbps | DUE:5"
```

**Kecualikan pelanggan tertentu** (mis. instansi yang bayar 3 bulan sekali).
Ada **2 cara**, pilih salah satu:

**Cara A — tag `SKIP` di comment.** Tambahkan kata `SKIP` di mana saja pada comment:
```rsc
/ppp secret set [find name=kantor-desa] comment="Kantor Desa - bayar per 3 bln SKIP"
```
Hapus kata `SKIP` kalau mau diaktifkan lagi.

**Cara B — daftar nama di script** (tanpa menyentuh comment). Buka
`billing-scheduler.rsc`, isi variabel `excludeNames` dengan nama-nama user
(persis seperti di `/ppp secret`), dipisah koma, **diapit koma**:
```rsc
:local excludeNames ",kantor-desa,sekolah-01,puskesmas,"
```
User yang tercantum **tidak akan pernah** kena halaman reminder walau ada `DUE:`.

Keduanya berlaku bersamaan — user kena kalau cocok salah satu.

### C. Setup walled-garden (sekali)
1. Buka [`setup-walled-garden.rsc`](setup-walled-garden.rsc).
2. Pastikan baris `redirectUrl` benar (default sudah sesuai repo ini).
3. Paste di terminal RouterOS, atau import filenya:
   ```rsc
   /import file-name=setup-walled-garden.rsc
   ```

### D. Pasang billing-scheduler
1. **System → Scripts → Add**, nama `billing-scheduler`, paste isi
   [`billing-scheduler.rsc`](billing-scheduler.rsc).
   (Opsional: isi `botToken` & `chatId` kalau mau notif Telegram juga.)
2. Scheduler tiap 1 jam:
   ```rsc
   /system scheduler
   add name=billing-scheduler interval=1h on-event="/system script run billing-scheduler" \
       comment="Isi address-list reminder tagihan"
   ```
3. Jalankan sekali manual untuk tes:
   ```rsc
   /system script run billing-scheduler
   /ip firewall address-list print where list="tagihan-reminder"
   ```

### E. Tes end-to-end
- Set salah satu user `DUE:` = tanggal **BESOK** (karena remindernya H-1).
  Contoh kalau hari ini tgl 14: `DUE:15`.
- Pastikan user itu **online** (`/ppp active print`).
- Jalankan `billing-scheduler` → IP-nya masuk `tagihan-reminder`.
- Dari perangkat di belakang router customer itu, buka situs **http://** (mis. `http://neverssl.com`).
- Harus ke-redirect ke halaman reminder.

---

## Opsional: reminder muncul SEKETIKA saat connect

Scheduler jalan tiap jam. Kalau mau begitu user PPPoE naik langsung dicek,
tambahkan di **`/ppp profile`** (profile normal mereka), field **On Up**:

```rsc
:local nama $user
:local ip $"remote-address"
:local today [:tonum [:pick [/system clock get date] 8 10]]
:local sid [/ppp secret find name=$nama]
:if ([:len $sid] > 0) do={
    :local cmt [/ppp secret get $sid comment]
    :local p [:find $cmt "DUE:"]
    :if ([:typeof $p] = "num") do={
        :local rest [:pick $cmt ($p + 4) [:len $cmt]]
        :local dstr ""; :local i 0; :local st false; :local rl [:len $rest]
        :while (($i < $rl) && (!$st)) do={
            :local c [:pick $rest $i ($i+1)]
            :if (($c >= "0") && ($c <= "9")) do={ :set dstr ($dstr . $c); :set i ($i+1) } else={ :set st true }
        }
        :if ([:len $dstr] > 0) do={
            :local due [:tonum $dstr]
            :if ($due = ($today + 1)) do={
                /ip firewall address-list add list="tagihan-reminder" address=$ip comment=$nama timeout=2h
            }
        }
    }
}
```

---

## Isolir (blokir total + halaman "belum bayar")

Untuk router **DISTRIBUSI MUSUK** sudah ada semua bahannya:
profile **`ISOLIR`** dengan pool **`10.1.1.0/24`** (10.1.1.2–10.1.1.254).
Tinggal jalankan **`setup-isolir.rsc`** (sekali), lalu isolir user cukup dengan
mengubah profile-nya jadi `ISOLIR`.

### Pasang
1. Buka [`setup-isolir.rsc`](setup-isolir.rsc), pastikan `redirectUrl` & `isolirNet`
   (`10.1.1.0/24`) benar.
2. Import / paste di terminal:
   ```rsc
   /import file-name=setup-isolir.rsc
   ```
   Script akan: nyalakan web-proxy, redirect HTTP subnet isolir → `isolir.html`,
   dan **blokir** internet subnet isolir kecuali DNS + halaman.

### Cara isolir & reaktivasi (teknisi)
```rsc
# isolir user (belum bayar):
/ppp secret set [find name=budi] profile=ISOLIR
/ppp active remove [find name=budi]     ;# putus paksa biar reconnect pakai profile baru

# aktifkan lagi (sudah bayar):
/ppp secret set [find name=budi] profile=PAKET100
/ppp active remove [find name=budi]
```
Setelah reconnect, user isolir dapat IP `10.1.1.x` → semua HTTP → halaman isolir,
internet lain diblok. Balikin profile → normal lagi otomatis.

### Kapan halaman isolir muncul?
Terus-menerus **selama** profile user = `ISOLIR`, tiap konek/tiap probe HTTP.
Beda dengan reminder H-1 (yang cuma sehari & internet tetap nyala).

### Catatan
- **Font halaman isolir**: karena internet diblok (kecuali github), Google Fonts
  tidak ikut termuat → halaman pakai font sistem (fallback). Tampilan tetap rapi.
- **IP GitHub Pages** (`185.199.108–111.153`) di-whitelist di `ALLOW-ISOLIR`.
  Kalau suatu saat GitHub ganti IP dan halaman tak terbuka, update list itu.
- **Kalau juga memakai reminder** (`setup-walled-garden.rsc`): jalankan
  `setup-isolir.rsc` **setelahnya**, lalu di `/ip proxy access` pastikan aturan
  `iso-redirect` berada **di atas** `wg-redirect` (drag di Winbox) — karena
  `iso-redirect` lebih spesifik (per-subnet).

---

## Troubleshooting

| Masalah | Solusi |
|---------|--------|
| Halaman tidak kebuka | Cek IP user ada di `tagihan-reminder` (`/ip firewall address-list print`). Cek proxy `enabled=yes` (`/ip proxy print`). |
| Loop redirect | Pastikan aturan `wg-allow-github` ada **di atas** `wg-redirect` (`/ip proxy access print`). |
| Semua orang ke-redirect | NAT `wg-reminder-redirect` harus pakai `src-address-list=tagihan-reminder`, bukan semua. |
| Situs HTTPS tidak ke-redirect | Memang tidak bisa. Andalkan captive-portal detection (HTTP) + Telegram. |
| IP user berubah tiap connect | Wajar (dynamic). Scheduler jam berikutnya menambah IP baru; `timeout=2h` membersihkan yang lama. |

---

## Uninstall
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

# matikan proxy kalau tidak dipakai lagi keduanya
/ip proxy set enabled=no
```
