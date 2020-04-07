#!/bin/sh
#init
function pause(){
   read -p "$*"
}

function install(){
	PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $0|grep "install ok installed")
	echo Checking for library: $PKG_OK
	if [ "" == "$PKG_OK" ]; then
	  echo "Not installed. Setting up library."
	  sudo apt-get --force-yes --yes $0
	fi
}

NODE_VERSION="10.x"

#Check Sudo user
if ! [ $(id -u) = 0 ]; then
   echo "The script need to be run as root." >&2
   exit 1
fi

apt update
install "curl"

curl -sL https://deb.nodesource.com/setup_$NODE_VERSION -o nodesource_setup.sh

#Install repository
bash nodesource_setup.sh

#Install NodeJS
install "nodejs"

#Check version successfully installed
nodejs -v
npm -v
