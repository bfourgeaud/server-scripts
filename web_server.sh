#!/bin/bash
echo

install_apache(){
	echo "--> Start installing Apache"
}

install_nginx(){
	NGINX_CONFIG="/etc/nginx/nginx.conf"
	echo "--> Start installing NGINX"
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
	DOMAIN=$1
	CURRENT_USER=$(who | awk 'NR==1{print $1}')
	FILE_PATH=/var/www/$DOMAIN
	SITES_AVAILABLE=/etc/nginx/sites-available/
	SITES_ENABLED=/etc/nginx/sites-enabled/
	
	echo "---> Creating folder"
	mkdir -p $FILE_PATH
	
	echo "---> Setting folder security"
	chown -R $CURRENT_USER:$CURRENT_USER $FILE_PATH
	chmod -R 755 $FILE_PATH
	
	echo "---> Adding server block"
	cat << "EOF" > $SITES_AVAILABLE$DOMAIN
	server {
			listen 80;
			listen [::]:80;

			root $FILE_PATH;

			server_name $DOMAIN www.$DOMAIN;

			location / {
					try_files $uri $uri/ =404;
			}
	}
EOF
	nano $SITES_AVAILABLE$DOMAIN
	
	echo "---> Enabling Server Block"
	ln -sf $SITES_AVAILABLE$DOMAIN $SITES_ENABLED
}

### MAIN PROGRAMM ###

INSTALL=false
ADD=false

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
			shift 3
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
	
	add_server_block $DOMAIN $PORT
fi

echo
