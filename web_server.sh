#!/bin/bash

pause(){
   read -p "$*"
}

setup_firewall(){
	local service=$1

	echo "---> Installing Firewall"
	apt install ufw
	ufw reset
		
	echo "---> Configuring Firewall"
	ufw allow OpenSSH
	ufw allow $service;

	ufw enable
}

install_apache(){
	local _HTTP_AUTH=$1
	local _APACHE_CONFIG="/etc/nginx/nginx.conf"
	
	echo "---> Start installing Apache"
	apt install apache2
	
	echo "---> Setting up Firewall"
	if $_HTTP_AUTH; then setup_firewall "WWW Full"; else setup_firewall "WWW Secure"; fi
	
	if systemctl status apache2 | grep -q 'Active: active (running)'; then
	   echo "---> Server Running"
	fi
}

install_nginx(){
	local _HTTP_AUTH=$1
	local _NGINX_CONFIG="/etc/nginx/nginx.conf"
	
	echo "---> Start installing NGINX"
	apt install nginx
	
	echo "---> Setting up Firewall"
	if _HTTP_AUTH; then setup_firewall "Nginx Full"; else setup_firewall "Nginx HTTPS"; fi
	
	if systemctl status nginx | grep -q 'Active: active (running)'; then
	   echo "---> Server Running"
	fi
	
	echo "---> Editing config file"
	local search="# server_names_hash_bucket_size 64;"
    local replace="server_names_hash_bucket_size 64;"
	sed -i "s/${search}/${replace}/g" $_NGINX_CONFIG
	
	if nginx -t | grep -q 'syntax is ok'; then
	   echo "---> Config file OK"
	   systemctl restart nginx
	fi
}

add_nginx_server_block(){
	local _DOMAIN=$1
	local _PORT=$2
	local SITES_AVAILABLE=/etc/nginx/sites-available/
	local SITES_ENABLED=/etc/nginx/sites-enabled/
	FILE_PATH=/var/www/$_DOMAIN
	
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
	
	if nginx -t | grep -q 'syntax is ok'; then
	   echo "---> Config file OK"
	   echo "---> Restarting Nginx"
	   systemctl restart nginx
	fi
}

add_apache_server_block(){
	local _DOMAIN=$1
	local _PORT=$2
	local SITES_AVAILABLE=/etc/apache2/sites-available/
	local SITES_ENABLED=/etc/apache2/sites-enabled/
	FILE_PATH=/var/www/$_DOMAIN
	
	echo "---> Creating folder"
	mkdir -p $FILE_PATH
	
	echo "---> Setting folder security"
	chown -R $CURRENT_USER:$CURRENT_USER $FILE_PATH
	chmod -R 755 $FILE_PATH
	
	echo "---> Adding server block"
	cat <<END > $SITES_AVAILABLE$_DOMAIN.conf
<VirtualHost *:80>
    ServerName $_DOMAIN
    ServerAlias www.$_DOMAIN
    DocumentRoot $FILE_PATH
    ErrorLog \${APACHE_LOG_DIR}/$_DOMAIN.error.log
    CustomLog \${APACHE_LOG_DIR}/$_DOMAIN.access.log combined
</VirtualHost>
END

	echo "---> Enabling Serber Block"
	a2ensite $_DOMAIN.conf
	a2dissite 000-default.conf
	
	if apache2ctl configtest | grep -q 'Syntax OK'; then
	   echo "---> Config file OK"
	   systemctl restart apache2
	fi
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

install_Wordpress(){
	local _FILE_PATH=$1
	local _TEMP_PATH="/tmp"

	echo "---> Installing MariaDB"
	apt install mariadb-client mariadb-server
	
	local _DB_NAME="default"
	local _USERNAME="wordpress"
	local _PASSWORD="password"
	
	echo "---> Setting up configuration :"
	read -p "Enter a database name :" _DB_NAME
	read -p "Enter a username :" _USERNAME
	read -s -p "Enter a password :" _PASSWORD
	
	echo "---> Configuring Database"
	mysql -u root -p -e "CREATE USER '$_USERNAME'@'localhost' IDENTIFIED BY '$_PASSWORD'; CREATE DATABASE $_DB_NAME; GRANT ALL PRIVILEGES ON $_DB_NAME.* TO '$_USERNAME'@'localhost'; FLUSH PRIVILEGES;"
	
	echo "---> Installing PHP"
	apt install php7.0 php7.0-mysql
	apt install libapache2-mod-php7.0
	
	echo "---> Installing PHP MY ADMIN"
	apt install phpmyadmin
	
	echo "---> Downloading latest Wordpress Version"
	wget -P $_TEMP_PATH/ https://wordpress.org/latest.tar.gz
	
	echo "---> Uncompressing wordpress archive"
	tar xzf $_TEMP_PATH/latest.tar.gz -C $_TEMP_PATH/
	rm $_TEMP_PATH/latest.tar.gz
	
	echo "---> Deleting target folder content"
	rm -rf $_FILE_PATH/{,.[!.],..?}*
	
	echo "---> Copying wordpress sources to target folder"
	cp -r $_TEMP_PATH/wordpress $_FILE_PATH
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
	local _WEB_SERVER=$1
	local _DOMAIN=$2
	
	echo "---> Setting up SSL"
	
	echo "---> Add up-to-date mirrors"
	echo "deb http://deb.debian.org/debian stretch-backports main contrib non-free" >> "/etc/apt/sources.list"
	echo "deb-src http://deb.debian.org/debian stretch-backports main contrib non-free" >> "/etc/apt/sources.list"
	
	echo "---> update mirrors"
	apt update
	
	if [[ "$_WEB_SERVER" == "Apache" ]]; 
	then 
		echo "---> Install Certbot"
		apt install python-certbot-apache -t stretch-backports
		
		echo "---> Obtaining Certificate"
		certbot --apache -d $_DOMAIN -d www.$_DOMAIN
		
		echo "---> Restarting Apache"
		systemctl restart apache2
	fi
	
	if [[ "$_WEB_SERVER" == "Nginx" ]]; 
	then 
		echo "---> Install Certbot"
		apt install python-certbot-nginx -t stretch-backports
		
		echo "---> Obtaining Certificate"
		certbot --nginx -d $_DOMAIN -d www.$_DOMAIN
		
		echo "---> Restarting Nginx"
		systemctl restart nginx
	fi
	
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
			break;;
        -a|--add)
			ADD=true
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
	
	if [[ "$WEB_SERVER" == "Apache" ]]; then install_apache $HTTP_AUTH; fi
	if [[ "$WEB_SERVER" == "Nginx" ]]; then install_nginx $HTTP_AUTH; fi
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
	
	if [[ "$WEB_SERVER" == "Apache" ]]; then add_apache_server_block $DOMAIN $PORT; fi
	if [[ "$WEB_SERVER" == "Nginx" ]]; then add_nginx_server_block $DOMAIN $PORT; fi
	
	if $GITHUB;
	then
		clone_github $FILE_PATH
	fi
	
	if [[ "$ENV" == "NodeJS" ]];
	then 
		install_NodeJS;	
		launch_NodeJS $FILE_PATH;
	fi
	
	if [[ "$ENV" == "Wordpress" ]];
	then 
		install_Wordpress $FILE_PATH;
	fi
	
	if $SSL;
	then
		setup_ssl $WEB_SERVER $DOMAIN
	fi
fi

echo
