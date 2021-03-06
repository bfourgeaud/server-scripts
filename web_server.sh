#!/bin/bash

pause(){
   read -p "$*"
}

install_package(){
  local _PACKAGE_NAME=$1
  # Check if firewall Installed
  if !(dpkg -s $_PACKAGE_NAME | grep -q 'Status: install ok installed'); then
    echo "---> Installing $_PACKAGE_NAME"
    apt -qq install $_PACKAGE_NAME
  fi
}

configure_firewall(){
  local _WEB_SERVER=$1
  local _HTTP_AUTH=$2

  echo "---> Configuring Firewall entries for $_WEB_SERVER with HTTP_AUTH=$_HTTP_AUTH"

  # Check if firewall Installed
  install_package "ufw"

  #ufw reset

  echo "---> Adding Firewall rules"
  # Check if OpenSSH authorized
  if !(ufw status | grep -q 'OpenSSH'); then
    ufw allow "OpenSSH"
  fi

  if [[ "$_WEB_SERVER" == "Apache" ]]; then
    if $_HTTP_AUTH;
    then
      ufw allow "WWW Full";
      ufw delete allow "WWW Secure";
    else
      ufw allow "WWW Secure";
      ufw delete allow "WWW Full";
    fi
  fi

  if [[ "$_WEB_SERVER" == "Nginx" ]]; then
    if $_HTTP_AUTH;
    then
      ufw allow "Nginx Full";
      ufw delete allow "Nginx HTTPS";
    else
      ufw allow "Nginx HTTPS";
      ufw delete allow "Nginx Full";
    fi
  fi

  # Check if firewall active
  if !(ufw status | grep -q 'Status: active'); then
    echo "---> Activating Firewall"
    ufw enable
  fi

  ufw status
}

install_apache(){
	local _APACHE_CONFIG="/etc/apache2/apache2.conf"

	echo "---> Start installing Apache"
  install_package "apache2"
	#apt -qq install apache2

	if systemctl status apache2 | grep -q 'Active: active (running)'; then
	   echo "---> Server Running"
	fi
}

install_nginx(){
	local _NGINX_CONFIG="/etc/nginx/nginx.conf"

	echo "---> Start installing NGINX"
  install_package "nginx"
	#apt -qq install nginx

	if systemctl status nginx | grep -q 'Active: active (running)'; then
	   echo "---> Server Running"
	fi

	echo "---> Editing config file"
	local search="# server_names_hash_bucket_size 64;"
  local replace="server_names_hash_bucket_size 64;"
	sed -i "s/${search}/${replace}/g" $_NGINX_CONFIG

	if nginx -t | grep -q 'syntax is ok'; then
	   echo "---> Config file OK"
	   systemctl restart nginx
	fi
}

add_nginx_server_block(){
	local _DOMAIN=$1
	local _PORT=$2
  local _ENV=$3

	local SITES_AVAILABLE=/etc/nginx/sites-available/
	local SITES_ENABLED=/etc/nginx/sites-enabled/
  local SERVER_BLOCK=$SITES_AVAILABLE$_DOMAIN

  local domain_string="<<DOMAIN>>"
  local port_string="<<PORT>>"
  local path_string="<<ROOT>>"

	FILE_PATH=/var/www/$_DOMAIN

	echo "---> Creating folder"
	mkdir -p $FILE_PATH

	echo "---> Setting folder security"
	chown -R $CURRENT_USER:$CURRENT_USER $FILE_PATH
	chmod -R 755 $FILE_PATH

	echo "---> Adding server block"
  if [[ "$ENV" == "NodeJS" ]];
	then
    cp "./config/Server_Blocks/Nginx_Proxy" $SERVER_BLOCK
    sed -i "s/${domain_string}/${_DOMAIN}/g" $SERVER_BLOCK
    sed -i "s/${port_string}/${_PORT}/g" $SERVER_BLOCK
    sed -i "s/${path_string}/${FILE_PATH}/g" $SERVER_BLOCK
  else
    cp "./config/Server_Blocks/Nginx" $SERVER_BLOCK
    sed -i "s/${domain_string}/${_DOMAIN}/g" $SERVER_BLOCK
    sed -i "s/${path_string}/${FILE_PATH}/g" $SERVER_BLOCK
  fi


	echo "---> Enabling Server Block"
	ln -sf $SERVER_BLOCK $SITES_ENABLED

	if nginx -t | grep -q 'syntax is ok'; then
	   echo "---> Config file OK"
	   echo "---> Restarting Nginx"
	   systemctl restart nginx
	fi
}

add_apache_server_block(){
	local _DOMAIN=$1
	local _PORT=$2
  local _ENV=$3

	local SITES_AVAILABLE=/etc/apache2/sites-available/
	local SITES_ENABLED=/etc/apache2/sites-enabled/

  local domain_string="<<DOMAIN>>"
  local port_string="<<PORT>>"
  local path_string="<<ROOT>>"

	FILE_PATH=/var/www/$_DOMAIN

	echo "---> Creating folder"
	mkdir -p $FILE_PATH

	echo "---> Setting folder security"
	chown -R $CURRENT_USER:$CURRENT_USER $FILE_PATH
	chmod -R 755 $FILE_PATH

	echo "---> Adding server block"

  if [[ "$ENV" == "NodeJS" ]];
	then
    a2enmod proxy
    a2enmod proxy_html
    a2enmod proxy_http

    cp "./config/Server_Blocks/Apache_Proxy" $SERVER_BLOCK
    sed -i "s/${domain_string}/${_DOMAIN}/g" $SERVER_BLOCK
    sed -i "s/${port_string}/${_PORT}/g" $SERVER_BLOCK
    sed -i "s/${path_string}/${FILE_PATH}/g" $SERVER_BLOCK
  else
    cp "./config/Server_Blocks/Apache" $SERVER_BLOCK
    sed -i "s/${domain_string}/${_DOMAIN}/g" $SERVER_BLOCK
    sed -i "s/${path_string}/${FILE_PATH}/g" $SERVER_BLOCK
	fi

	echo "---> Enabling Serer Block"
	a2ensite $_DOMAIN.conf
	a2dissite 000-default.conf

	if apache2ctl configtest | grep -q 'Syntax OK'; then
	   echo "---> Config file OK"
	   systemctl restart apache2
	fi
}

install_NodeJS(){
	local _Node_Version="12.x"

	echo "---> Installing NodeJS"

	#apt -qq install curl software-properties-common
  install_package "curl"
  install_package "software-properties-common"
	curl -sL https://deb.nodesource.com/setup_$_Node_Version | sudo bash -
	#apt -qq install nodejs
  install_package "nodejs"

	echo "---> Installed Node Version :" | node -v
	echo "---> Installed NPM version :" | npm -v
}

launch_NodeJS(){
	local _PROJECT_PATH=$1

	echo "---> Navigating to $_PROJECT_PATH"
	cd $_PROJECT_PATH

	echo "---> Installing Dependecies"
	#npm install -g nodemon
	npm install -g forever
	npm install

	echo "---> Starting NodeJS app"
	forever start app.js
}

install_Wordpress(){
	local _FILE_PATH=$1
	local _TEMP_PATH="/tmp"

	#echo "---> Installing MariaDB"
  install_package "mariadb-server"
  install_package "mariadb-client"
	#apt -qq install mariadb-client mariadb-server

	local _DB_NAME="default"
	local _USERNAME="wordpress"
	local _PASSWORD="password"

	echo "---> Setting up configuration :"
	read -p "Enter a database name :" _DB_NAME
	read -p "Enter a username :" _USERNAME
	read -s -p "Enter a password :" _PASSWORD

	echo
	echo "---> Configuring Database"
	mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS $_DB_NAME; CREATE USER IF NOT EXISTS '$_USERNAME'@'localhost' IDENTIFIED BY '$_PASSWORD'; GRANT ALL PRIVILEGES ON $_DB_NAME.* TO '$_USERNAME'@'localhost'; FLUSH PRIVILEGES;"

	#echo "---> Installing PHP"
  install_package "php7.0"
  install_package "php7.0-mysql"
  install_package "libapache2-mod-php7.0"
	#apt -qq install php7.0 php7.0-mysql
	#apt -qq install libapache2-mod-php7.0

	#echo "---> Installing PHP MY ADMIN"
	#apt -qq install phpmyadmin
  install_package "phpmyadmin"

	echo "---> Downloading latest Wordpress Version"
	wget -P $_TEMP_PATH/ https://wordpress.org/latest.tar.gz

	echo "---> Uncompressing wordpress archive"
	tar xzf $_TEMP_PATH/latest.tar.gz -C $_TEMP_PATH/
	rm $_TEMP_PATH/latest.tar.gz

	echo "---> Deleting target folder content"
	rm -rf $_FILE_PATH/{,.[!.],..?}*

	echo "---> Copying wordpress sources to target folder"
	cp -r $_TEMP_PATH/wordpress/. $_FILE_PATH/
	rm -Rf $_TEMP_PATH/wordpress/

	echo "---> Setting up wp-config.php"
	mv $_FILE_PATH/wp-config-sample.php $_FILE_PATH/wp-config.php

	#GET SALTS
	WPSalts=$(wget https://api.wordpress.org/secret-key/1.1/salt/ -q -O -)
	TablePrefx=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 9 | head -n 1)_

	cat <<EOF > $_FILE_PATH/wp-config.php
<?php
/***Managed by JEEBIE.ME - Benjamin Fourgeaud***/

define('DB_NAME', '$_DB_NAME');
define('DB_USER', '$_USERNAME');
define('DB_PASSWORD', '$_PASSWORD');
define('DB_HOST', 'localhost');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

/*WP Tweaks*/
#define( 'WP_SITEURL', '' );
#define( 'WP_HOME', '' );
#define( 'ALTERNATE_WP_CRON', true );
#define('DISABLE_WP_CRON', 'true');
#define('WP_CRON_LOCK_TIMEOUT', 900);
#define('AUTOSAVE_INTERVAL', 300);
#define( 'WP_MEMORY_LIMIT', '256M' );
#define( 'FS_CHMOD_DIR', ( 0755 & ~ umask() ) );
#define( 'FS_CHMOD_FILE', ( 0644 & ~ umask() ) );
#define( 'WP_ALLOW_REPAIR', true );
#define( 'FORCE_SSL_ADMIN', true );
#define( 'AUTOMATIC_UPDATER_DISABLED', true );
#define( 'WP_AUTO_UPDATE_CORE', false );

$WPSalts

\$table_prefix = '$TablePrefx';

define('WP_DEBUG', false);

if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

require_once(ABSPATH . 'wp-settings.php');
EOF

	echo "---> Setting folder security"
	chown -R $CURRENT_USER:$CURRENT_USER $_FILE_PATH
	chmod -R 755 $_FILE_PATH
}

install_Static(){
  local _FILE_PATH=$1
  cp "./config/index.html" "$_FILE_PATH/index.html"
}

clone_github(){
	local _FILE_PATH=$1
	local _GITHUB_LINK=""

	echo "---> Setting-up GitHub"
	read -p "Enter GitHub clone link :" _GITHUB_LINK

	echo "---> Deleting folder content"
	rm -rf $_FILE_PATH/{,.[!.],..?}*

	echo "---> Cloning to $_FILE_PATH"
	cd $_FILE_PATH
	git clone $_GITHUB_LINK .
}

setup_ssl(){
	local _WEB_SERVER=$1
	local _DOMAIN=$2

  local MIRROR1="deb http://deb.debian.org/debian stretch-backports main contrib non-free"
  local MIRROR2="deb-src http://deb.debian.org/debian stretch-backports main contrib non-free"
  local MIRROR_FILE="/etc/apt/sources.list"
	echo "---> Setting up SSL"

	echo "---> Add up-to-date mirrors"
  if !(grep -Fxq "$MIRROR1" "$MIRROR_FILE"); then echo $MIRROR1 >> $MIRROR_FILE; fi
  if !(grep -Fxq "$MIRROR2" "$MIRROR_FILE"); then echo $MIRROR2 >> $MIRROR_FILE; fi

	echo "---> update mirrors"
	apt -qq update

	if [[ "$_WEB_SERVER" == "Apache" ]];
	then
		echo "---> Install Certbot"
		apt -qq install python-certbot-apache -t stretch-backports

		echo "---> Obtaining Certificate"
		certbot --apache -d $_DOMAIN -d www.$_DOMAIN

		echo "---> Restarting Apache"
		systemctl restart apache2
	fi

	if [[ "$_WEB_SERVER" == "Nginx" ]];
	then
		echo "---> Install Certbot"
		apt -qq install python-certbot-nginx -t stretch-backports

		echo "---> Obtaining Certificate"
		certbot --nginx -d $_DOMAIN -d www.$_DOMAIN

		echo "---> Restarting Nginx"
		systemctl restart nginx
	fi

	echo "---> Test auto-renawal"
	certbot renew --dry-run
}

update(){
  #Update and Upgrade packages
  echo "---> Updating and Upgrading Packages"
  apt -qq update && apt -qq upgrade
}

### MAIN PROGRAMM ###

# Default values
INSTALL=false
ADD=false
SSL=false
GITHUB=false
HTTP_AUTH=true
WEB_SERVER=""
ENV=""

FILE_PATH="/var/www/default"
CURRENT_USER=$(who | awk 'NR==1{print $1}')
PORT=8080

# Loop through arguments and process them
while [ -n "$1" ]; do # while loop starts
	case "$1" in
    -i|--install)
      INSTALL=true
			WEB_SERVER=$2

      echo "Installing new web server ..."
    	if [[ "$WEB_SERVER" == "Apache" ]]; then install_apache; fi
    	if [[ "$WEB_SERVER" == "Nginx" ]]; then install_nginx; fi

			break;;

    -up|--update-mirrors)
      update
      break;;

    -uf|--update-firewall) ## TODO : HANDLE
      WEB_SERVER=$2
      HTTP_AUTH=$3
      configure_firewall $WEB_SERVER $HTTP_AUTH
      break;;

    -as|--add-site)
      ADD=true
      ENV=$2
      shift;;

    -ssl|--secure)
      SSL=$2
      shift;;
    -d|--domain)
  		DOMAIN=$2
  		shift;;

    -g|--github)
  		GITHUB=$2
  		shift;;
    -p|--port)
  		PORT=$2
  		shift;;
    -mg|--mongoose)
      MONGOOSE=$2
      shift;;

    --module)
      MODULES+=($2)
      shift;;
    --template)
      TEMPLATES+=($2)
      shift;;

		-s|--server)
			WEB_SERVER=$2
			shift;;
		-e|--env)
			ENV=$2
			shift;;
        *)
			echo "Option $1 not recognized" ;;
    esac
	shift
done

if $ADD;
then
	echo "Adding new web instance ..."
	echo "---> WebServer : $WEB_SERVER"
	echo "---> Domain : $DOMAIN"
	echo "---> Port : $PORT"
	echo "---> SSL : $SSL"
	echo "---> GITHUB : $GITHUB"
	echo "---> ENVIRONNEMENT : $ENV"

	if [[ "$WEB_SERVER" == "Apache" ]]; then add_apache_server_block $DOMAIN $PORT $ENV; fi
	if [[ "$WEB_SERVER" == "Nginx" ]]; then add_nginx_server_block $DOMAIN $PORT $ENV; fi

	if $GITHUB;
	then
		clone_github $FILE_PATH
	fi

	if [[ "$ENV" == "NodeJS" ]];
	then
		install_NodeJS;
    if $GITHUB;
  	then
  		clone_github $FILE_PATH
      launch_NodeJS $FILE_PATH;
  	fi
	fi

	if [[ "$ENV" == "Wordpress" ]];
	then
		install_Wordpress $FILE_PATH;
	fi

  if [[ "$ENV" == "Static" ]];
	then
    if $GITHUB;
  	then
  		clone_github $FILE_PATH
    else
      install_static $FILE_PATH;
  	fi
	fi

	if $SSL;
	then
		setup_ssl $WEB_SERVER $DOMAIN
	fi
fi

echo
