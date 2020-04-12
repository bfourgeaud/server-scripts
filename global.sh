#!/bin/bash

#### STATIC VALUES #####
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

pause(){
   read -p "$*"
}

install_package(){
  local _PACKAGE_NAME=$1
  # Check if firewall Installed
  if !(dpkg -s $_PACKAGE_NAME | grep -q 'Status: install ok installed'); then
    echo "---> Installing $_PACKAGE_NAME"
    apt -qq -y install $_PACKAGE_NAME
  fi
}
