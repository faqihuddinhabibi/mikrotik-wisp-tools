# Opsi A — Hosting di VPS (Docker)

Halaman reminder + isolir di-host di **VPS sendiri** (Ubuntu 24.04 LTS) pakai
**Docker + nginx**. MikroTik cukup redirect ke **IP VPS** (tetap, tidak berubah).

## Kenapa opsi ini

| Kelebihan | Kekurangan |
|-----------|------------|
| **IP tetap** → whitelist isolir cukup 1 IP, tidak pernah basi | VPS harus selalu online |
| Bisa diakses saat user isolir (IP di-whitelist) | Tambah 1 komponen (VPS) untuk dijaga |
| Nanti bisa halaman **dinamis** (nama/nominal per user) | — |
| HTTP langsung (pas untuk captive portal) | — |

> Bandingkan dengan **Opsi B** ([../hosting-mikrotik-container](../hosting-mikrotik-container)):
> halaman di-host di dalam MikroTik (container), tanpa perlu VPS.

---

## Langkah pasang (Ubuntu 24.04 LTS)

### 1. Install Docker (kalau belum)
```bash
sudo apt update
sudo apt install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker
```

### 2. Ambil repo & jalankan
```bash
git clone https://github.com/faqihuddinhabibi/mikrotik-wisp-tools.git
cd mikrotik-wisp-tools/hosting-vps
sudo docker compose up -d --build
```

### 3. Cek
```bash
curl -I http://localhost/            # harus 200
curl -I http://localhost/isolir.html # harus 200
```
Dari browser: `http://IP-VPS/` (reminder) dan `http://IP-VPS/isolir.html`.

> Kalau port 80 VPS sudah dipakai (mis. ada web lain), ubah di `docker-compose.yml`
> baris `ports` jadi `"8080:80"`, lalu sesuaikan URL di MikroTik ke `IP-VPS:8080`.

### 4. Update halaman (nomor WA dll)
Edit `docs/index.html` / `docs/isolir.html`, lalu:
```bash
git pull        # kalau diedit dari GitHub
sudo docker compose up -d --build
```

---

## Ubah setting MikroTik (arahkan ke VPS)

Ganti `redirectUrl` di script jadi IP VPS (TANPA `https://`):

**Reminder** — `02-.../setup-walled-garden.rsc`:
```rsc
:local redirectUrl "IP-VPS/"
```
**Isolir** — `02-.../setup-isolir.rsc`:
```rsc
:local redirectUrl "IP-VPS/isolir.html"
```
Lalu di `setup-isolir.rsc`, ganti whitelist GitHub jadi **IP VPS**:
```rsc
/ip firewall address-list remove [find list="ALLOW-ISOLIR"]
/ip firewall address-list add list="ALLOW-ISOLIR" address=IP-VPS comment="vps-halaman"
```
Jalankan ulang script setup-nya. Selesai — user isolir tetap bisa buka halaman
karena IP VPS di-whitelist, dan IP itu **tidak berubah**.

---

## (Opsional) CI/CD — auto-deploy tiap `git push`

Ada template di [`deploy-vps.yml.example`](deploy-vps.yml.example).
Cara aktifkan:
1. **Pindahkan** file itu ke `.github/workflows/deploy-vps.yml` di repo
   (lewat web GitHub: Add file → Create new file, paste isinya). Push file workflow
   butuh akun dengan izin Actions.
2. Di GitHub repo → **Settings → Secrets and variables → Actions**, tambah:
   - `VPS_HOST` = IP/domain VPS
   - `VPS_USER` = user SSH (mis. `root` atau user docker)
   - `VPS_SSH_KEY` = private key SSH (yang public-nya ada di `~/.ssh/authorized_keys` VPS)
   - `VPS_PATH` = path repo di VPS (mis. `/root/mikrotik-wisp-tools`)
3. Push ke `main` → GitHub Actions SSH ke VPS → `git pull` + `docker compose up -d --build`.

Kalau belum mau CI/CD, cukup manual (`git pull` + `docker compose up -d --build`).

---

## Keamanan VPS (singkat)
- Buka **hanya** port yang perlu (80/8080 untuk halaman, 22 untuk SSH).
- Halaman ini statis & publik — tidak simpan data sensitif. Aman diakses siapa saja.
- Jangan taruh token/kredensial di halaman.
