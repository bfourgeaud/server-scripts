#!/bin/bash
source global.sh

echo "Setting up Firewall ..."

if [ $# -eq 0 ];
then
  echo "No arguments provided"
  echo "Usage : ./setup-firewall [webserver (Apache|Nginx)] [secure (true|false)]"
  exit 0;
fi

WEBSERVER=$1
SECURE=$2

case $WEBSERVER in
  Apache)
    HTTPS="WWW Secure"
    FULL="WWW Full"
    ;;
  Nginx)
    HTTPS="Nginx HTTPS"
    FULL="Nginx Full"
    ;;
  *)
  echo "WebServer provided not valid. Should be Apache or Nginx"
  exit 0;;
esac

# Check if firewall Installed
install_package "ufw"

# Check if OpenSSH authorized
if !(ufw status | grep -q 'OpenSSH'); then
  ufw allow "OpenSSH"
fi

if [ "$SECURE" = "true" ] ;
then
  echo "Allowing only HTTPS traffic ($HTTPS)"
  ufw allow "$HTTPS";
  ufw delete allow "$FULL"
else
  echo "Allowing HTTP & HTTPS traffic ($FULL)"
  ufw allow "$FULL";
  ufw delete allow "$HTTPS"
fi

# Check if firewall active
if !(ufw status | grep -q 'Status: active'); then
  echo "---> Activating Firewall"
  ufw enable
fi

ufw status
