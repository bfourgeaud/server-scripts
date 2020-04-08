#!/bin/bash

pause(){
   read -p "$*"
}

# Clear screeen
clear(){
  echo -en "\ec"
}

question_header(){
  local QUESTION=$1
  echo
  echo "#######################################################################"
  echo "##### $QUESTION"
  echo "#######################################################################"
  echo
}

check_webserver(){

  # Check for Apache
  if [[ `ps -acx|grep apache|wc -l` > 0 ]]; then
    echo "VM Configured with Apache"
    WEB_SERVER="Apache"
    return;
  fi

  # Check for Nginx
  if [[ `ps -acx|grep nginx|wc -l` > 0 ]]; then
      echo "VM Configured with Nginx"
      WEB_SERVER="Nginx"
      return;
  fi

  WEB_SERVER="None"
}

node_config(){
  # Q1 : Link to GitHub Repo
  while true; do
    read -p "Connect to GitHub Repository (y or n) ? " yn
    case $yn in
      [Yy]* ) GITHUB=true; break;;
      [Nn]* ) GITHUB=false; break;;
      * ) echo "Please answer (y)es or (n)o";;
    esac
  done

  # Q2 : Install Mongoose DataBase
  while true; do
    read -p "Add Mongoose DataBase (y or n) ? " yn
    case $yn in
      [Yy]* ) MONGOOSE=true; break;;
      [Nn]* ) MONGOOSE=false; break;;
      * ) echo "Please answer (y)es or (n)o";;
    esac
  done

  # Q3 : Choose Port for instance
  while true; do
    read -e -p "Port Number (4000-9999) - [8080] : " -i 8080 PORT
    if [[ $PORT -gt 4000 && $PORT -lt 9999 ]]; then break; fi
  done
}

wp_config(){
  echo "Config Wordpress"
}

static_config(){
  echo "Config Static"
}

resume_choices(){
  local _SITE_NR=$1

  # Resume choices
  question_header "Resume choices for WebSite n°$_SITE_NR"

  echo -e "Domain-name : ${RED}$DOMAIN${NC}"
  echo -e "Configure SSL : ${RED}$SSL${NC}"
  echo -e "Running Environnement : ${RED}$ENV${NC}"

  if [[ "$ENV" == "NodeJS" ]]; then
    echo -e "Connect to GitHub : ${RED}$GITHUB${NC}"
    echo -e "Port Number : ${RED}$PORT${NC}"
    echo -e "Install Mongoose : ${RED}$MONGOOSE${NC}"
  fi

  if [[ "$ENV" == "Wordpress" ]]; then
    echo -e "Modules to install : ${RED}$MODULES${NC}"
    echo -e "Teplates to use : ${RED}$TEMPLATES${NC}"
  fi

  if [[ "$ENV" == "Static" ]]; then
    echo ""
  fi
  echo
}

#### STATIC VALUES #####
RED='\033[0;31m'
NC='\033[0m' # No Color

#### DEFAULT VALUES ####
INSTALL_WS=true
WEB_SERVER="None"
UNSECURE_HTTP=false
NB_SITES=0

clear

## Check if script can launch
## Check if lauched with sudo privileges, else quit
if ! [ $(id -u) = 0 ]; then
   echo "The script need to be run as root." >&2
   exit 1
fi

## Check linux version, only Debian 9.x for now
if !(lsb_release --description | grep -q 'Debian GNU/Linux 9.'); then
  echo "The script works only on Debian 9.x." >&2
  exit 1
fi

## Check if Apache or Nginx Installed
check_webserver
echo "---> Actual WebServer detected : $WEB_SERVER"

echo
## Select WebServer to install
if [[ $WEB_SERVER == "None" ]];
then
  INSTALL_WS=true
  #Choose WebServer
  PS3='What WebServer do you want to install ? : '
  options=("Apache" "Nginx")
  select webSrv in "${options[@]}"
  do
  	case $webSrv in
  		"Apache")
        #./web_server.sh --install "Apache" $authorizeHTTP;
        WEB_SERVER="Apache"
  			break;;
  		"Nginx")
  			#./web_server.sh --install "Nginx" $authorizeHTTP;
        WEB_SERVER="Nginx"
  			break;;
  		*)
  			;;
  	esac
  done

  ################# INSTALL WEB SERVER #########################
  question_header "INSTALLING WEBSERVER"
  ./web_server.sh --install $WEB_SERVER
  ##############################################################
fi

# Authorize HTTP connection (Unsecure) ?
while true; do
	read -p "Authorize unsecure HTTP access (y or n) ? " yn
	case $yn in
		[Yy]* ) UNSECURE_HTTP=true; break;;
		[Nn]* ) UNSECURE_HTTP=false; break;;
		* ) ;;
esac
done

################# UPDATE MIRRORS #################
question_header "UPDATING MIRRORS"
./web_server.sh --update-mirrors
##################################################

################# UPDATE WEB SERVER FIREWALL #################
question_header "UPDATING FIREWALL"
./web_server.sh --update-firewall $UNSECURE_HTTP $WEB_SERVER
##############################################################

question_header "CONFIGURE SITES INSTANCES"
#How much site instances do you want to create ?
while true; do
	read -p "How much site instances (1-10) " NB_SITES
	if [[ "$NB_SITES" =~ ^[0-9]+$ ]]; then break; fi
done

## Loops though instances and configure them
for (( i=1; i<=$NB_SITES; i++ ))
do
	while true; do

    #### DEFAULT VALUES ####
    DOMAIN=
    SSL=false
    ENV=
    GITHUB=false
    PORT=8080
    MONGOOSE=false
    MODULES=[]
    TEMPLATES=[]

		#clear
		question_header "Configuring site n°$i"

		# Q1 : Get the domain name
		read -p "Domain-name : " DOMAIN

    # Q2 : Install SSL
    while true; do
      read -p "Configure SSL (y or N) ? " yn
      case $yn in
        [Yy]* ) SSL=true; break;;
        [Nn]* ) SSL=false; break;;
        * ) ;;
      esac
    done

    echo
		# Q3 : Get Running Environnement
		PS3='Pre-installed Environnement : '
		options=("NodeJS" "Wordpress")
		select ENV in "${options[@]}"
		do
			case $ENV in
				"NodeJS")
          node_config
					break;;
				"Wordpress")
          wp_config
					break;;
        "Static")
          static_config
          break;;
				*)
					;;
			esac
		done

		resume_choices $i

		# Validate choices ?
    read -p "Do you confirm that information (y or n) ?" yn
    case $yn in
      [Yy]* ) break;;
      [Nn]* ) clear; echo "Starting over";;
      * ) echo "Please answer (y)es or (n)o";;
    esac
	done

  pause "All Information has been recorded. Press [Enter] key to launch Install"

	# Make installation
	question_header "Installing site $domain ... "

  case $ENV in
    "NodeJS")
      ./web_server.sh --add-site $ENV --secure $SSL --domain $DOMAIN --github $GITHUB --port $portNr --mongoose $MONGOOSE
      break;;
    "Wordpress")
      ./web_server.sh --add-site $ENV --secure $SSL --domain $DOMAIN ## TODO --module $MODULES[i] --template $TEMPLATE []
      ;;
    "Static")
      ./web_server.sh --add-site $ENV --secure $SSL --domain $DOMAIN
      break;;
    *)
      echo "Nothing to install"
      ;;
  esac

done
