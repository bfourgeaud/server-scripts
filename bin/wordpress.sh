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

  # Install PHP
  install_package "php7.0"
  install_package "php7.0-mysql"
  install_package "libapache2-mod-php7.0"

  #Install WP client tool
  curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  php wp-cli.phar --info
  chmod +x wp-cli.phar
  sudo mv wp-cli.phar /usr/local/bin/wp
  if wp --info | grep -q 'WP-CLI version:'; then
     echo "---> WP client tool installed successfully"
  else
    echo "Error Installing WP client tool"
    exit 0;
  fi

  #echo "---> Installing MariaDB"
  install_package "mariadb-server"
  install_package "mariadb-client"

  DB_NAME= ${DOMAIN//./_}

  echo "---> Wordpress Database info (DBNAME: $DB_NAME) :"
	read -p "Enter a username :" DB_USER
	read -s -p "Enter a password :" DB_PASS

  # Create the database.

  echo "Creating database $DB_NAME..."
  mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS $DB_NAME; CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS'; GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"

  # Download WP Core.
  -u $CURRENT_USER -i -- wp core download --path=$FOLDER_PATH

  # Generate the wp-config.php file
  -u $CURRENT_USER -i -- wp core config --path=$FOLDER_PATH--dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_PASS --extra-php <<PHP
  define('WP_DEBUG', true);
  define('WP_DEBUG_LOG', true);
  define('WP_DEBUG_DISPLAY', true);
  define('WP_MEMORY_LIMIT', '256M');
PHP

  ADMIN_USER="jeebie"
  ADMIN_PASS="WP_Jeebie_2020"
  ADMIN_EMAIL="benjamin.fourgeaud@gmail.com"
  # Install the WordPress database.
  -u $CURRENT_USER -i -- wp core install --path=$FOLDER_PATH --url="http://$DOMAIN" --title=$DOMAIN --admin_user=$ADMIN_USER --admin_password=$ADMIN_PASS --admin_email=$ADMIN_EMAIL

fi
