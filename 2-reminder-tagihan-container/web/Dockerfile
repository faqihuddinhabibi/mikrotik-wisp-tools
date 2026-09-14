# Image nginx statis untuk dijalankan sebagai CONTAINER di dalam RouterOS.
# Build context = ROOT repo (biar bisa COPY docs/). Router x86 = amd64.
FROM --platform=linux/amd64 nginx:1.27-alpine

COPY docs/ /usr/share/nginx/html/
COPY 2-reminder-tagihan-container/web/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
