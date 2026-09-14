#!/usr/bin/env bash
# Build image nginx statis lalu export jadi .tar untuk diupload ke RouterOS.
# Jalankan di komputer yang ada Docker (bukan di router).
set -e
# pindah ke ROOT repo (2 tingkat di atas file ini)
cd "$(dirname "$0")/../.."

docker build --platform linux/amd64 \
  -f 2-reminder-tagihan-container/web/Dockerfile \
  -t reminder-web:latest .

docker save reminder-web:latest -o 2-reminder-tagihan-container/web/reminder-web.tar

echo ""
echo "Selesai. File: 2-reminder-tagihan-container/web/reminder-web.tar"
echo "Upload file itu ke menu Files di RouterOS (drag-drop di Winbox)."
