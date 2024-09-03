FROM nginx:1.25.5

MAINTAINER WinJayX@Gmail.com
LABEL description="This is Nginx Dockerfile  Project"
LABEL version="1.1"
USER root

VOLUME /tmp
ENV LANG en_US.UTF-8

RUN cat <<'EOF' > /etc/nginx/nginx.conf

user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    ############ 开启gzip压缩，加快前端访问速度  #############
    gzip              on;
    gzip_disable      "MSIE [1-6]\.";
    gzip_static       on;
    gzip_proxied      any;
    gzip_min_length   1k;
    gzip_comp_level   5;
    gzip_buffers      4 16k;
    gzip_types        text/plain text/css text/xml application/javascript application/x-javascript application/xml text/javascript application/json application/xml+rss image/jpeg image/gif image/png;
    gzip_vary         off;
    gzip_http_version 1.0;

    include /etc/nginx/conf.d/*.conf;
}

EOF

########    处理返回 404问题    #########
RUN sed -i '10i\        proxy_read_timeout 300s;\n        try_files $uri $uri/ /index.html;' /etc/nginx/conf.d/default.conf

ADD dist/ /usr/share/nginx/html

EXPOSE 80
EXPOSE 443
