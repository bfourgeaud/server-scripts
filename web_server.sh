#!/bin/bash

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

clone_github(){
	local _FILE_PATH=$1
	local _GITHUB_LINK=""
	
	read -p "Enter GitHub clone link :" _GITHUB_LINK
	git clone $_GITHUB_LINK _FILE_PATH/.
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
			shift 5
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
	
	add_server_block $DOMAIN $PORT
	
	if $GITHUB;
	then
		clone_github $FILE_PATH
	fi
	
	if $SSL;
	then
		setup_ssl $DOMAIN
	fi
fi

echo
