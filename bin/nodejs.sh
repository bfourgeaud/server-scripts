#!/bin/bash
source global.sh

Node_Version="12.x"
INSTALL=false
START=false

while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
      -i|--install)
        INSTALL=true;;
      -s|--start)
        START=true;;
      -p|--path)
        FOLDER_PATH=$2
        shift;;
      *)
        echo "Invalid argument $key";;
  esac
  shift;
done

if $INSTALL;
then
  echo "---> Installing NodeJS"

  if !(node -v | grep -q 'v12'); then
    install_package "curl"
    install_package "software-properties-common"
  	curl -sL https://deb.nodesource.com/setup_$Node_Version | sudo bash -
    install_package "nodejs"

  	echo "---> Installed Node Version :" | node -v
  	echo "---> Installed NPM version :" | npm -v
  else
    echo "NodeJS already installed"
  fi
fi

if $START;
then
  echo "NodeJS.sh -> Statting NodeJS on PATH : $FOLDER_PATH"
  if [ -n $FOLDER_PATH ]; then echo "ERROR : No path given, can't start NodeJS app."; exit 0; fi

  echo "---> Navigating to $FOLDER_PATH"
  cd $FOLDER_PATH

  echo "---> Installing Dependecies"
  npm install -g pm2
  npm install

  echo "---> Starting NodeJS app"
  pm2 start app.js
  pm2 startup
fi
