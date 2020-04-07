#!/bin/bash

pause(){
   read -p "$*"
}

setup_firewall(){
	local _HTTP_AUTH=$1

	echo "---> Installing Firewall"
	apt install ufw
	ufw reset
		
	echo "---> Configuring Firewall"
	ufw allow OpenSSH
	
	if $_HTTP_AUTH; 
	then 
		ufw allow 'Nginx Full';
	else
		ufw allow 'Nginx HTTPS';
	fi
	
	ufw enable
}

install_apache(){
	echo "---> Start installing Apache"
	echo "---> Not implemented yet ..."
}

install_nginx(){
	NGINX_CONFIG="/etc/nginx/nginx.conf"
	echo "---> Start installing NGINX"
	apt install nginx
	
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
	#npm install -g nodemon
	npm install -g forever
	npm install
	
	echo "---> Starting NodeJS app"
	forever start app.js
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
	local _DOMAIN=$1
	
	echo "---> Setting up SSL"
	
	echo "---> Add up-to-date mirrors"
	echo "deb http://deb.debian.org/debian stretch-backports main contrib non-free" >> "/etc/apt/sources.list"
	echo "deb-src http://deb.debian.org/debian stretch-backports main contrib non-free" >> "/etc/apt/sources.list"
	
	echo "---> update mirrors"
	apt update
	
	echo "---> Install Certbot"
	apt install python-certbot-nginx -t stretch-backports
	
	echo "---> Obtaining Certificate"
	certbot --nginx -d $_DOMAIN -d www.$_DOMAIN
	
	echo "---> Restarting Nginx"
	systemctl restart nginx
	
	echo "---> Test auto-renawal"
	certbot renew --dry-run
}


### MAIN PROGRAMM ###

# Default values
INSTALL=false
ADD=false
SSL=false
GITHUB=false
HTTP_AUTH=true
WEB_SERVER="Nginx"
ENV="NodeJS"

FILE_PATH="/var/www/default"
CURRENT_USER=$(who | awk 'NR==1{print $1}')
PORT=8080
SITES_AVAILABLE="/etc/nginx/sites-available/"
SITES_ENABLED="/etc/nginx/sites-enabled/"

echo

#Update and Upgrade packages
apt update && apt upgrade

# Loop through arguments and process them
while [ -n "$1" ]; do # while loop starts
	case "$1" in
        -i|--install)
			INSTALL=true
			WEB_SERVER=$2
			HTTP_AUTH=$8
			#shift 2
			break;;
        -a|--add)
			ADD=true
			#WEB_SERVER=$2
			#DOMAIN=$3
			#PORT=$4
			##SSL=${5#*=}
			##GITHUB=${6#*=}
			#ENV=$7
			#shift 6
			;;
		-s|--server)
			WEB_SERVER=$2
			shift;;
		-d|--domain)
			DOMAIN=$2
			shift;;
		-p|--port)
			PORT=$2
			shift;;
		-ssl|--secure)
			SSL=$2
			shift;;
		-g|--github)
			GITHUB=$2
			shift;;
		-e|--env)
			ENV=$2
			shift;;
        *)
			echo "Option $1 not recognized" ;;
    esac
	shift
done

if $INSTALL; 
then
	echo "Installing new web server ..."
	
	echo "---> Installing Firewall"
	setup_firewall $HTTP_AUTH
	
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
	
	if $GITHUB;
	then
		clone_github $FILE_PATH
	fi
	
	if [[ "$ENV" == "NodeJS" ]];
	then 
		install_NodeJS;	
		launch_NodeJS $FILE_PATH;
	fi
	
	if $SSL;
	then
		setup_ssl $DOMAIN
	fi
fi

echo
