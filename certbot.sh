#!/bin/bash

COMMAND=$1
DOMAIN=$2
LETSENCRYPT_FOLDER="$HOME/letsencrypt"

if [[ "$COMMAND" == "setup" ]]; then
  if [ -z "$DOMAIN" ]; then
    echo "Syntax:"
    echo ""
    echo "./certbot.sh setup {domain}"
    echo ""
    exit 1
  fi

  sudo mkdir $LETSENCRYPT_FOLDER 2> /dev/null
  sudo service nginx stop

  docker run --rm --name certbot --net host \
  -v "$LETSENCRYPT_FOLDER/etc/letsencrypt:/etc/letsencrypt" \
  -v "$LETSENCRYPT_FOLDER/var/lib/letsencrypt:/var/lib/letsencrypt" \
  certbot/certbot certonly --non-interactive --register-unsafely-without-email --agree-tos --standalone -d $DOMAIN

  cat << EOF | sudo tee /etc/nginx/sites-available/web-app > /dev/null
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    return 301 https://$DOMAIN;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl ipv6only=on;
    server_name $DOMAIN;

    ssl_certificate $LETSENCRYPT_FOLDER/etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key $LETSENCRYPT_FOLDER/etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

  sudo ln -s /etc/nginx/sites-available/web-app /etc/nginx/sites-enabled/web-app
  sudo rm /etc/nginx/sites-enabled/default
elif [[ "$COMMAND" == "renew" ]]; then
  sudo service nginx stop

  docker run --rm --name certbot --net host \
  -v "$LETSENCRYPT_FOLDER/etc/letsencrypt:/etc/letsencrypt" \
  -v "$LETSENCRYPT_FOLDER/var/lib/letsencrypt:/var/lib/letsencrypt" \
  certbot/certbot renew --agree-tos --standalone
else
  echo "Syntax:"
  echo ""
  echo "./certbot.sh setup|renew"
  echo ""
  exit 1
fi

sudo service nginx start
