# Image nginx statis untuk halaman reminder + isolir.
# Build context = ROOT repo (biar bisa COPY docs/).
FROM nginx:1.27-alpine

# halaman: docs/index.html (reminder) & docs/isolir.html
COPY docs/ /usr/share/nginx/html/

# konfigurasi nginx (serve HTTP port 80 untuk captive portal)
COPY hosting-vps/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
