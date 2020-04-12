#!/bin/bash
source ../global.sh

while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
      -i|--install)
        INSTALL=true;;
      -db|--db-name)
        MONGO_DB=$2
        shift;;
      -u|--user)
        MONGO_USER=$2
        shift;;
      -p|--pass)
        MONGO_PASS=$2
        shift;;
      *)
        echo "Invalid argument $key";;
  esac
  shift;
done

if $INSTALL;
then
  echo "Installing Mongoose"
  echo "Not implemented yet"
fi
