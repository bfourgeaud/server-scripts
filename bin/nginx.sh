#!/bin/bash
source ../global.sh

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
  NGINX_CONFIG="/etc/nginx/nginx.conf"

  echo "---> Start installing NGINX"
  install_package "nginx"
  #apt -qq install nginx

  if systemctl status nginx | grep -q 'Active: active (running)'; then
     echo "---> Server Running"
  fi

  echo "---> Editing config file"
  search="# server_names_hash_bucket_size 64;"
  replace="server_names_hash_bucket_size 64;"
  sed -i "s/${search}/${replace}/g" $NGINX_CONFIG

  if nginx -t | grep -q 'syntax is ok'; then
     echo "---> Config file OK"
     systemctl restart nginx
  fi
fi

if $RESTART;
then
  if nginx -t | grep -q 'syntax is ok'; then
     echo "---> Restarting Nginx"
     systemctl restart nginx
  fi
fi

if $RELOAD;
then
  if nginx -t | grep -q 'syntax is ok'; then
     echo "---> Restarting Nginx"
     systemctl reload nginx
  fi
fi
