#! /bin/bash

# Include the config file
source ./config/WP-config.sh

if [ $# -ne 1 ]; then
    echo $0: usage: Installation name
    exit 1
fi

DEST=$1

read -p "Are you sure you want to delete the files and DB for '$DEST'?" -n 1 -r
echo    # Move to new line
if [[ $REPLY =~ ^[Yy]$ ]]
then

    echo 'Deleting files...'

    # Delete files
    rm -rf $SITE_PATH/$DEST/

    # Delete the database.
    DB_NAME=$(echo $DEST | sed -e 's/-/_/g')
    echo "Deleting database $DB_NAME..."

    mysql -u$DB_USER -p$DB_PASS -e"DROP DATABASE $DB_NAME"

    echo 'WordPress install deleted successfully.'
fi
