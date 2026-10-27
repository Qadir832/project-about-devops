
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY style.css /usr/share/nginx/html/style.css
COPY file.js /usr/share/nginx/html/file.js

EXPOSE 80
