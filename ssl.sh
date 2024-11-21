#!/bin/bash


ls ~/.acme.sh/acme.sh > /dev/null 2>&1

if [[ $? != 0 ]];then
    read -p "输入邮箱：" email
    curl https://get.acme.sh | sh -s email=$email
else
    echo "acme.sh installed."
fi

read -p "输入要申请SSL的主域名：" domain

cat <<EOF > /etc/nginx/conf.d/$domain.conf
server {
    listen 80;
    server_name $domain;
}
EOF

~/.acme.sh/acme.sh --issue -d $domain --nginx

mkdir /etc/nginx/ssl

~/.acme.sh/acme.sh --install-cert -d $domain \
--key-file /etc/nginx/ssl/$domain-key.pem \
--fullchain-file /etc/nginx/ssl/$domain-cert.pem \
--reloadcmd "service nginx force-reload"

cat <<EOF > /etc/nginx/conf.d/$domain.conf
server {
    listen 80;
    server_name $domain;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;

    ssl_certificate /etc/nginx/ssl/$domain-cert.pem;
    ssl_certificate_key /etc/nginx/ssl/$domain-key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    location / {
        default_type text/plain;
        return 200 "SSL OK";
    }
}
EOF

nginx -t
nginx -s reload
