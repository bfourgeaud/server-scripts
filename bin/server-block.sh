#!/bin/bash

# With Proxy :
# ./bin/server-block.sh --add $WEB_SERVER --path $ROOT_PATH --domain $DOMAIN --proxy $PORT
# Without Proxy :
# ./bin/server-block.sh --add $WEB_SERVER --path $ROOT_PATH --domain $DOMAIN
domain_string="<<DOMAIN>>"
port_string="<<PORT>>"
path_string="<<ROOT>>"

while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
      -a|--add)
        WEB_SERVER=$2
        shift;;
      -p|--path)
        ROOT_PATH=$2
        shift;;
      -d|--domain)
        DOMAIN=$2
        shift;;
      -proxy|--proxy)
        PROXY=true
        PORT=$2
        shift;;
      *)
        echo "Invalid argument $key";;
  esac
  shift;
done

case $WEB_SERVER in
  Nginx)
    SITES_AVAILABLE=/etc/nginx/sites-available/
    SITES_ENABLED=/etc/nginx/sites-enabled/
    SERVER_BLOCK=$SITES_AVAILABLE$DOMAIN

    if $PROXY;
    then
      CFG_FILE="./config/Server_Blocks/Nginx_Proxy";
    else
      CFG_FILE="./config/Server_Blocks/Nginx";
    fi

    echo "---> Creating ServerBlock"
    cp $CFG_FILE $SERVER_BLOCK

    sed -i "s/${domain_string}/${DOMAIN}/g" $SERVER_BLOCK
    sed -i "s/${path_string}/${ROOT_PATH}/g" $SERVER_BLOCK
    sed -i "s/${port_string}/${PORT}/g" $SERVER_BLOCK

    echo "---> Enabling Server Block"
  	ln -sf $SERVER_BLOCK $SITES_ENABLED

  	if nginx -t | grep -q 'syntax is ok'; then
  	   echo "---> Config file OK"
  	   echo "---> Restarting Nginx"
  	   systemctl restart nginx
    else
      echo -e "ERROR : Nginx Config file syntax invalid."
      exit 0;
  	fi
    ;;
  Apache)
    SITES_AVAILABLE=/etc/apache2/sites-available/
    SITES_ENABLED=/etc/apache2/sites-enabled/
    SERVER_BLOCK=$SITES_AVAILABLE$DOMAIN

    if $PROXY;
    then
      CFG_FILE="./config/Server_Blocks/Apache_Proxy";
      a2enmod proxy
      a2enmod proxy_html
      a2enmod proxy_http
    else
      CFG_FILE="./config/Server_Blocks/Apache";
    fi

    echo "---> Creating ServerBlock"
    cp $CFG_FILE $SERVER_BLOCK

    sed -i "s/${domain_string}/${DOMAIN}/g" $SERVER_BLOCK
    sed -i "s/${path_string}/${ROOT_PATH}/g" $SERVER_BLOCK
    sed -i "s/${port_string}/${PORT}/g" $SERVER_BLOCK

    echo "---> Enabling Server Block"
  	a2ensite $_DOMAIN.conf
  	a2dissite 000-default.conf

    if apache2ctl configtest | grep -q 'Syntax OK'; then
  	   echo "---> Config file OK"
  	   systemctl restart apache2
    else
      echo -e "ERROR : Apache Config file syntax invalid."
      exit 0
  	fi
    ;;
  *)
    echo "Webserver $WEB_SERVER not supported"
    exit 0;;
esac
