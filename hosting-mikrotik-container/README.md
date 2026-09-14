# Opsi B — Hosting di MikroTik (Container)

Halaman reminder + isolir di-host **langsung di dalam MikroTik** sebagai container
(nginx). MikroTik redirect ke **IP container lokal** (mis. `172.17.0.2`).

## Kenapa opsi ini

| Kelebihan | Kekurangan |
|-----------|------------|
| **Tidak butuh VPS / internet** — halaman lokal, selalu bisa dibuka | Fitur container perlu diaktifkan (paket + reboot) |
| User isolir pasti bisa akses (IP lokal router) | Pakai CPU/RAM/disk router |
| IP lokal tetap, tidak pernah basi | Setup lebih teknis; **reboot = risiko di jaringan produksi** |
| Tanpa ketergantungan GitHub | Update halaman = build & upload ulang image |

> Bandingkan **Opsi A** ([../hosting-vps](../hosting-vps)): host di VPS, lebih gampang
> update & bisa dinamis, tapi butuh VPS online.

> ⚠️ **PENTING**: mengaktifkan container butuh **install paket + reboot** router.
> Di jaringan produksi (bos), lakukan saat **maintenance window** (jam sepi).
> HP ProDesk x86 + SSD 128GB **lebih dari cukup** untuk ini.

---

## Tahap 1 — Build image (di komputer, bukan router)

Butuh Docker di komputermu (Mac/Linux/Win):
```bash
git clone https://github.com/faqihuddinhabibi/mikrotik-wisp-tools.git
cd mikrotik-wisp-tools
bash hosting-mikrotik-container/build-and-export.sh
```
Hasil: `hosting-mikrotik-container/reminder-web.tar`. **Upload** file ini ke menu
**Files** RouterOS (drag-drop di Winbox).

---

## Tahap 2 — Aktifkan fitur container di RouterOS (SEKALI, ada reboot)

1. **Install paket `container`**:
   - Download `container-7.24.2.npk` (arch **x86**) dari mikrotik.com → Software.
   - Upload ke Files → **reboot**. Cek: `/system package print` (harus ada `container`).
2. **Aktifkan device-mode container**:
   ```rsc
   /system/device-mode/update container=yes
   ```
   RouterOS minta konfirmasi: **reboot**, lalu (pada beberapa perangkat) tekan
   tombol reset fisik dalam hitungan detik. Ikuti instruksi di layar.
   Cek: `/system/device-mode/print` → `container: yes`.

---

## Tahap 3 — Jaringan container

```rsc
# veth (kaki container)
/interface/veth/add name=veth-web address=172.17.0.2/24 gateway=172.17.0.1

# bridge khusus container
/interface/bridge/add name=br-docker
/ip/address/add address=172.17.0.1/24 interface=br-docker
/interface/bridge/port/add bridge=br-docker interface=veth-web
```

## Tahap 4 — Buat & jalankan container

```rsc
# arahkan penyimpanan container ke disk (ganti disk1 sesuai nama disk-mu; cek /disk print)
/container/config/set tmpdir=disk1/tmp

# tambahkan container dari file tar yang tadi diupload
/container/add file=reminder-web.tar interface=veth-web root-dir=disk1/web \
    logging=yes start-on-boot=yes

# lihat status & id, lalu start
/container/print
/container/start [find]
```
Cek jalan: `/container/print` → status `running`. Halaman ada di
**http://172.17.0.2/** dan **http://172.17.0.2/isolir.html**.

> `disk1` = nama disk. Cek dengan `/disk print`. Kalau beda (mis. `nvme1`),
> sesuaikan `tmpdir` dan `root-dir`.

---

## Tahap 5 — Arahkan MikroTik ke container

**Reminder** — `02-.../setup-walled-garden.rsc`:
```rsc
:local redirectUrl "172.17.0.2/"
```
**Isolir** — `02-.../setup-isolir.rsc`:
```rsc
:local redirectUrl "172.17.0.2/isolir.html"
```
Dan whitelist IP container (ganti isi ALLOW-ISOLIR):
```rsc
/ip firewall address-list remove [find list="ALLOW-ISOLIR"]
/ip firewall address-list add list="ALLOW-ISOLIR" address=172.17.0.2 comment="container-web"
```
Jalankan ulang script setup-nya. User isolir → diarahkan ke container lokal,
selalu bisa dibuka, **tanpa internet sama sekali**.

> Catatan: karena lokal, halaman tidak butuh DNS/GitHub. Font Google tidak termuat
> (halaman pakai font sistem) — tampilan tetap rapi.

---

## Update halaman nanti
Edit `docs/*.html` → build ulang (`build-and-export.sh`) → upload tar baru →
```rsc
/container/stop [find]
/container/remove [find]
/container/add file=reminder-web.tar interface=veth-web root-dir=disk1/web start-on-boot=yes
/container/start [find]
```

## Uninstall container
```rsc
/container/stop [find]
/container/remove [find]
/interface/bridge/port/remove [find interface=veth-web]
/interface/veth/remove [find name=veth-web]
/interface/bridge/remove [find name=br-docker]
```
