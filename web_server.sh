#!/bin/bash

pause(){
   read -p "$*"
}

install_apache(){
	echo "---> Start installing Apache"
	echo "---> Not implemented yet ..."
}

install_nginx(){
	NGINX_CONFIG="/etc/nginx/nginx.conf"
	echo "---> Start installing NGINX"
	apt install nginx
	ufw allow 'Nginx Full'
	
	if systemctl status nginx | grep -q 'Active: active (running)'; then
	   echo "---> Server Running"
	fi
	
	echo "---> Editing config file"
	local search="# server_names_hash_bucket_size 64;"
    local replace="server_names_hash_bucket_size 64;"
	sed -i "s/${search}/${replace}/g" $NGINX_CONFIG
	
	if nginx -t | grep -q 'syntax is ok'; then
	   echo "---> Config file OK"
	   systemctl restart nginx
	fi
}

add_server_block(){
	local _DOMAIN=$1
	local _PORT=$2
	#CURRENT_USER=$(who | awk 'NR==1{print $1}')
	FILE_PATH=/var/www/$_DOMAIN
	SITES_AVAILABLE=/etc/nginx/sites-available/
	SITES_ENABLED=/etc/nginx/sites-enabled/
	
	echo "---> Creating folder"
	mkdir -p $FILE_PATH
	
	echo "---> Setting folder security"
	chown -R $CURRENT_USER:$CURRENT_USER $FILE_PATH
	chmod -R 755 $FILE_PATH
	
	echo "---> Adding server block"
	cat <<END > $SITES_AVAILABLE$_DOMAIN
server {
        root $FILE_PATH;
        index index.html;
        server_name $_DOMAIN www.$_DOMAIN;
        location / {
           proxy_pass http://localhost:$_PORT;
           proxy_http_version 1.1;
           proxy_set_header Upgrade \$http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host \$host;
           proxy_cache_bypass \$http_upgrade;
        }
}
END
	
	echo "---> Enabling Server Block"
	ln -sf $SITES_AVAILABLE$_DOMAIN $SITES_ENABLED
	
	echo "---> Restarting Nginx"
	systemctl restart nginx
}

install_NodeJS(){
	local _Node_Version="12.x"
	
	echo "---> Installing NodeJS"
	
	apt-get install curl software-properties-common
	curl -sL https://deb.nodesource.com/setup_$_Node_Version | sudo bash -
	apt-get install nodejs
	
	echo "---> Installed Node Version :" | node -v 
	echo "---> Installed NPM version :" | npm -v
}

launch_NodeJS(){
	local _PROJECT_PATH=$1
	
	echo "---> Navigating to $_PROJECT_PATH"
	cd $_PROJECT_PATH
	
	echo "---> Installing Dependecies"
	npm install -g nodemon
	npm install
	
	echo "---> Starting NodeJS app"
	nodemon
}

clone_github(){
	local _FILE_PATH=$1
	local _GITHUB_LINK=""
	
	echo "---> Setting-up GitHub"
	read -p "Enter GitHub clone link :" _GITHUB_LINK
	
	echo "---> Deleting folder content"
	rm -rf $_FILE_PATH/*
	
	echo "---> Cloning to $_FILE_PATH"
	cd $_FILE_PATH
	ls
	git clone $_GITHUB_LINK .
}

setup_ssl(){
	local _DOMAIN=$1
	
	echo "---> Setting up SSL"
	
	echo "---> Add up-to-date mirrors"
	echo "deb http://deb.debian.org/debian stretch-backports main contrib non-free" >> "/etc/apt/sources.list"
	echo "deb-src http://deb.debian.org/debian stretch-backports main contrib non-free" >> "/etc/apt/sources.list"
	
	echo "---> update mirrors"
	apt update
	
	echo "---> Install Certbot"
	apt install python-certbot-nginx -t stretch-backports
	
	echo "---> Authorize HTTPS traffic in Firewall"
	ufw allow 'Nginx Full'
	
	echo "---> Obtaining Certificate"
	certbot --nginx -d $_DOMAIN -d www.$_DOMAIN
	
	echo "---> Restarting Nginx"
	systemctl restart nginx
	
	echo "---> Test auto-renawal"
	certbot renew --dry-run
}


### MAIN PROGRAMM ###

INSTALL=false
ADD=false
SSL=false
GITHUB=false

FILE_PATH="/var/www/default"
CURRENT_USER=$(who | awk 'NR==1{print $1}')
PORT=8080
SITES_AVAILABLE="/etc/nginx/sites-available/"
SITES_ENABLED="/etc/nginx/sites-enabled/"

echo

# Loop through arguments and process them
while [ -n "$1" ]; do # while loop starts
	case "$1" in
        -i|--install)
			INSTALL=true
			WEB_SERVER=$2
			shift 1
			;;
        -a|--add)
			ADD=true
			WEB_SERVER=$2
			DOMAIN=$3
			PORT=$4
			SSL=${5#*=}
			GITHUB=${6#*=}
			ENV=$7
			shift 6
			;;
        *)
			echo "Option $1 not recognized" ;;
    esac
	shift
done

if $INSTALL; 
then
	echo "Installing new web server ..."
	
	echo "---> Updating repositories"
	apt update
	
	echo "---> Installing Firewall"
	apt install ufw
	ufw allow OpenSSH
	ufw enable
	
	if [[ "$WEB_SERVER" == "Apache" ]]; then install_apache; fi
	if [[ "$WEB_SERVER" == "Nginx" ]]; then install_nginx; fi
fi

if $ADD;
then
	echo "Adding new web instance ..."
	echo "---> WebServer : $WEB_SERVER"
	echo "---> Domain : $DOMAIN"
	echo "---> Port : $PORT"
	echo "---> SSL : $SSL"
	echo "---> GITHUB : $GITHUB"
	echo "---> ENVIRONNEMENT : $ENV"
	
	add_server_block $DOMAIN $PORT
	pause "Press [Enter] key to continue"
	
	if $GITHUB;
	then
		clone_github $FILE_PATH
		pause "Press [Enter] key to continue"
	fi
	
	if [[ "$ENV" == "NodeJS" ]];
	then 
		install_NodeJS;
		pause "Press [Enter] key to continue"
		
		launch_NodeJS $FILE_PATH;
		pause "Press [Enter] key to continue"
	fi
	
	if $SSL;
	then
		setup_ssl $DOMAIN
		pause "Press [Enter] key to continue"
	fi
fi

echo
