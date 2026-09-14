#!/usr/bin/env bash
# Build image nginx statis lalu export jadi .tar untuk diupload ke RouterOS.
# Jalankan di komputer yang ada Docker (bukan di router).
set -e
cd "$(dirname "$0")/.."   # pindah ke root repo

docker build --platform linux/amd64 \
  -f hosting-mikrotik-container/Dockerfile \
  -t reminder-web:latest .

docker save reminder-web:latest -o hosting-mikrotik-container/reminder-web.tar

echo ""
echo "Selesai. File: hosting-mikrotik-container/reminder-web.tar"
echo "Upload file itu ke menu Files di RouterOS (drag-drop di Winbox)."
