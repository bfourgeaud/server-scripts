#!/bin/bash
source global.sh
CURRENT_USER=$(who | awk 'NR==1{print $1}')

while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
      -i|--install)
        INSTALL=true;;
      -p|--path)
        FOLDER_PATH=$2
        shift;;
      -d|--domain)
        DOMAIN=$2
        shift;;
      *)
        echo "Invalid argument $key";;
  esac
  shift;
done

if $INSTALL;
then
  if [ -z "$FOLDER_PATH" ]; then echo "Missing folder path argument"; exit 0; fi

  _TEMP_PATH="/tmp"

  # Install PHP
  install_package "php7.0"
  install_package "php7.0-mysql"
  install_package "libapache2-mod-php7.0"

  #echo "---> Installing MariaDB"
  install_package "mariadb-server"
  install_package "mariadb-client"

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

  install_package "phpmyadmin"

	echo "---> Downloading latest Wordpress Version"
	wget -P $_TEMP_PATH/ https://wordpress.org/latest.tar.gz

	echo "---> Uncompressing wordpress archive"
	tar xzf $_TEMP_PATH/latest.tar.gz -C $_TEMP_PATH/
	rm $_TEMP_PATH/latest.tar.gz

	echo "---> Deleting target folder content"
	rm -rf $FOLDER_PATH/{,.[!.],..?}*

	echo "---> Copying wordpress sources to target folder"
	cp -r $_TEMP_PATH/wordpress/. $FOLDER_PATH/
	rm -Rf $_TEMP_PATH/wordpress/

	echo "---> Setting up wp-config.php"
	mv $FOLDER_PATH/wp-config-sample.php $FOLDER_PATH/wp-config.php

	#GET SALTS
	WPSalts=$(wget https://api.wordpress.org/secret-key/1.1/salt/ -q -O -)
	TablePrefx=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 9 | head -n 1)_

	cat <<EOF > $FOLDER_PATH/wp-config.php
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
fi
