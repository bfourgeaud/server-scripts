#!/bin/bash

source global.sh

if [ $# -lt 2 ];
then
  echo "No enough arguments provided"
  echo "Usage : ./setup-ssl [webserver (Apache|Nginx)] [domain]"
  exit 0;
fi

SSL_SERVER=$1
SSL_DOMAIN=$2

MIRROR1="deb http://deb.debian.org/debian stretch-backports main contrib non-free"
MIRROR2="deb-src http://deb.debian.org/debian stretch-backports main contrib non-free"
MIRROR_FILE="/etc/apt/sources.list"
echo "---> Setting up SSL"

echo "---> Add up-to-date mirrors"
if !(grep -Fxq "$MIRROR1" "$MIRROR_FILE"); then echo $MIRROR1 >> $MIRROR_FILE; fi
if !(grep -Fxq "$MIRROR2" "$MIRROR_FILE"); then echo $MIRROR2 >> $MIRROR_FILE; fi

echo "---> update mirrors"
apt -qq update

case $SSL_SERVER in
  Apache)
    echo "---> Install Certbot"
    apt -qq install python-certbot-apache -t stretch-backports

    echo "---> Obtaining Certificate"
    certbot -n -q --apache -d $SSL_DOMAIN -d www.$SSL_DOMAIN --agree-tos --redirect -m benjamin.fourgeaud@gmail.com

    echo "---> Restarting Apache"
    systemctl restart apache2;;
  Nginx)
    echo "---> Install Certbot"
    apt -qq install python-certbot-nginx -t stretch-backports

    echo "---> Obtaining Certificate"
    certbot -n -q --nginx -d $SSL_DOMAIN -d www.$SSL_DOMAIN --agree-tos --redirect -m benjamin.fourgeaud@gmail.com

    echo "---> Restarting Nginx"
    systemctl restart nginx;;
  *)
    echo "WebServer $SSL_SERVER not available for SSL setup"
    exit 0;;
esac

echo "---> Test auto-renawal"
certbot renew --dry-run
