# Image nginx statis untuk dijalankan sebagai CONTAINER di dalam RouterOS.
# Build context = ROOT repo. Router x86 = arsitektur amd64.
FROM --platform=linux/amd64 nginx:1.27-alpine

COPY docs/ /usr/share/nginx/html/
COPY hosting-mikrotik-container/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
