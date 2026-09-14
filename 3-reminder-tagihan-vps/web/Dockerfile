# Image nginx statis untuk halaman reminder + isolir (di VPS).
# Build context = ROOT repo (biar bisa COPY docs/).
FROM nginx:1.27-alpine

COPY docs/ /usr/share/nginx/html/
COPY 3-reminder-tagihan-vps/web/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
