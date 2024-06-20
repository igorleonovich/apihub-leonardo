#!/bin/bash

# Check for variables
export WORKER_CONNECTIONS=${WORKER_CONNECTIONS:-1024}
export HTTP_PORT=${HTTP_PORT:-80}
export REDIRECT=${REDIRECT:-https\:\/\/\$host}
export REDIRECT_TYPE=${REDIRECT_TYPE:-permanent}
export NGINX_CONF=/etc/nginx/mushed.conf
export HSTS=${HSTS:-0}
export HSTS_MAX_AGE=${HSTS_MAX_AGE:-31536000}
export HSTS_INCLUDE_SUBDOMAINS=${HSTS_INCLUDE_SUBDOMAINS:-0}

# Build config
cat <<EOF > $NGINX_CONF
user root;
daemon off;

events {
    worker_connections $WORKER_CONNECTIONS;
}

http {
    server {

        # Old part

        listen $HTTP_PORT;
        server_tokens off;
        $([ "${HSTS}" != "0" ] && echo "
        add_header Strict-Transport-Security \"max-age=${HSTS_MAX_AGE};$([ "${HSTS_INCLUDE_SUBDOMAINS}" != "0" ] && echo "includeSubDomains")\";
        ")
#        rewrite ^(.*) $REDIRECT\$1 $REDIRECT_TYPE;

        # New part

        rewrite ^/(.*)$ /$1 break;
        proxy_pass https://leonardo.ai;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_pass_request_headers on;
        client_max_body_size 100M;

        proxy_http_version 1.1;
        proxy_set_header Connection "keep-alive";
        proxy_buffering off;
        proxy_request_buffering off;

    }
}

EOF

cat $NGINX_CONF;

chown -R root:root /var/lib/nginx;
mkdir -p /run/nginx;

exec nginx -c $NGINX_CONF
