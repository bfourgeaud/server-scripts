#!/bin/bash
source global.sh

while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
      -i|--install)
        INSTALL=true;;
      -s|--restart)
        RESTART=true;;
      -p|--reload)
        RELOAD=true;;
      *)
        echo "Invalid argument $key";;
  esac
  shift;
done


if $INSTALL;
then
  APACHE_CONFIG="/etc/apache2/apache2.conf"

  echo "---> Start installing Apache"
  install_package "apache2"

  if systemctl status apache2 | grep -q 'Active: active (running)'; then
     echo "---> Server Running"
  fi
fi

if $RESTART;
then
  systemctl restart apache2
fi

if $RELOAD;
then
  systemctl reload apache2
fi
