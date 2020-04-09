#! /bin/bash

# Includes your config file
source ./config/WP-config.sh

if [ $# -ne 1 ]; then
    echo $0: usage: Destination Name
    exit 1
fi

DEST=$1

# Create the database.
DB_NAME=$(echo $DEST | sed -e 's/-/_/g')
echo "Creating database $DB_NAME..."

mysql -u$DB_USER -p$DB_PASS -e"CREATE DATABASE $DB_NAME"

# Download WP Core.
wp core download --path=$SITE_PATH/$DEST

# Generate the wp-config.php file
wp core config --path=$SITE_PATH/$DEST --dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_PASS --extra-php <<PHP
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', true);
define('WP_MEMORY_LIMIT', '256M');
PHP

# Install the WordPress database.
wp core install --path=$SITE_PATH/$DEST --url=$BASE_URL/$DEST --title=$DEST --admin_user=test --admin_password=test --admin_email=YOU@YOURDOMAIN.com
