#!/bin/sh


function pause(){
   read -p "$*"
}

## Check if script can launch
##First check current Linux Version
#lsb_release --description

#if ! [ $(id -u) = 0 ]; then
#   echo "The script need to be run as root." >&2
#   exit 1
#fi


##CONFIGURE SERVER BASIC SETTINGS
#Update and Upgrade packages
apt update

#Choose WebServer
PS3='What WebServer do you want to install ? : '
options=("Apache" "Nginx" "None")
select webSrv in "${options[@]}"
do
	case $webSrv in
		"Apache")
			./web_server.sh --install "Apache";
			break;;
		"Nginx")
			./web_server.sh --install "Nginx";
			break;;
		"None")
			break;;
		*)
			echo "invalid option";;
	esac
done

echo

#How much site instances do you want to create ?
valid=false
until $valid; do
	echo "How much site instances (1-10)"
	read nbSites
	if [[ "$nbSites" =~ ^[0-9]+$ ]]; then valid=true; else valid=false; fi
done


## Loops though instances and configure them
for (( i=1; i<=$nbSites; i++ ))
do
	confirm=false;
	until $confirm; do
		echo -en "\ec"
		echo "Configuring site n°$i"
		echo
		# Get the domain name
		echo "Domain-name :"
		read domain

		echo
		# Get Running Environnement
		PS3='Pre-installed Environnement :'
		options=("NodeJS" "Wordpress" "None")
		select siteEnv in "${options[@]}"
		do
			case $siteEnv in
				"NodeJS")
					break;;
				"Wordpress")
					break;;
				"None")
					break;;
				*)
					echo "invalid option";;
			esac
		done
		
		echo
		# Install SSL
		while true; do
			read -p "Configure SSL (y or N) ?" yn
			case $yn in
				[Yy]* ) configureSSL=true; break;;
				[Nn]* ) configureSSL=false; break;;
				* ) echo "Please answer (y)es or (n)o";;
			esac
		done
		
		echo
		# Authorize HTTP connection (Unsecure) ?
		while true; do
			read -p "Authorize HTTP connection (y or n) ?" yn
			case $yn in
				[Yy]* ) authorizeHTTP=true; break;;
				[Nn]* ) authorizeHTTP=false; break;;
				* ) echo "Please answer (y)es or (n)o";;
			esac
		done
		
		echo
		# GitHub link ?
		while true; do
			read -p "Connect to GitHub Repository (y or n) ?" yn
			case $yn in
				[Yy]* ) connectGitHub=true; break;;
				[Nn]* ) connectGitHub=false; break;;
				* ) echo "Please answer (y)es or (n)o";;
			esac
		done

		echo
		#Port Number
		valid=false
		until $valid; do
			echo "Port Number (4000-9999) - Default 8080"
			read portNr
			if ((portNr >= 4000 && portNr <= 9999)); then valid=true; else valid=false; fi
		done

		# Resume choices
		echo
		echo "SITE $i : You choose the following configuration";
		echo "Domain-name : $domain"
		echo "Running Environnement : $siteEnv"
		echo "Connect GitHub : $connectGitHub"
		echo "Port Number : $portNr"
		echo "Configure SSL : $configureSSL"
		echo "Authorize HTTP : $authorizeHTTP"
		
		echo
		# Validate choices ?
		while true; do
			read -p "Do you confirm that information (y or n) ?" yn
			case $yn in
				[Yy]* ) confirm=true; break;;
				[Nn]* ) confirm=false; break;;
				* ) echo "Please answer (y)es or (n)o";;
			esac
		done
	done
	
	# Make installation
	echo
	echo "Installing site $domain ...."
	echo
	
	./web_server.sh --add "$webSrv" "$domain" "$portNr"
	
	#Configuring SSL
	if $configureSSL;
	then 
		./ssl.sh "$domain" "www.$domain"
	fi
	
	#Installing NodeJS
	if [[ "$siteEnv" == "NodeJS" ]]; 
	then 
		./nodeJS.sh
		#Add proxy to apache/nginx to listen to port
	fi
	
	#Installing Wordpress
	if [[ "$siteEnv" == "Wordpress" ]]; 
	then 
		./wordpress.sh
	fi
	
	#Wait for user confirmation
	echo
	pause "Press [Enter] key to continue"
done
