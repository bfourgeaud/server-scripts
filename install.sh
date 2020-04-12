#!/bin/bash

print_usage(){
  echo "Arguments : "
  echo "[-s|--web-server] 'Apache'|'Nginx'"
  echo "[-u|--update-packages]"
  echo "[-a|--add-site] (config_files)"
}

#### STATIC VALUES #####
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

CURRENT_USER=$(who | awk 'NR==1{print $1}')
available_srv=(Apache Nginx)

# Loop though arguments
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
      print_usage
      exit 0;;
    -s|--web-server)
      if [[ $2 == -* ]]; then echo "Invalid [-s|--web-server] parameter"; exit 0; fi
      if [[ ! "${available_srv[@]}" =~ "${2}" ]]; then echo -e "Only ${RED}Apache${NC} and ${RED}Nginx${NC} are possible as [-s|--web-server] parameter"; exit 0; fi
      WEB_SERVER="$2"
      shift 2;;
    --secure)
      SECURE=true
      shift;;
    -u|--update-packages)
      UPDATE_PKG=true
      shift;;
    -a|--add-site)
      shift
      arr=("$@")
      for item in "${arr[@]}";
      do
        if [[ $item == -* ]]; then break; fi
        if [[ $item == *.conf ]]; then CONFIG_FILE+=($item); fi
      done
      shift ${#CONFIG_FILE[@]};;
    *)
      shift;;
esac
done

echo "#### RESUMING OPTIONS ####"
echo "WEB_SERVER : " $WEB_SERVER
echo "UPDATE_PKG : " $UPDATE_PKG
echo "CONFIG_FILES : "
for file in "${CONFIG_FILE[@]}";
do
  echo "  > $file"
done

echo
echo "#### PROCESSING ####"
# Updating packages
if [ $UPDATE_PKG ];
then
  echo "Updating Packages ..."
  apt -qq update && apt -qq -y upgrade
fi

# Install WebServer & Firewall
if [ -n "$WEB_SERVER" ];
then
  echo "Installing $WEB_SERVER ..."
  case $WEB_SERVER in
    Apache)
      ./bin/apache.sh --install
      ./bin/setup-firewall.sh $WEB_SERVER $SECURE;;
    Nginx)
      ./bin/nginx.sh --install
      ./bin/setup-firewall.sh $WEB_SERVER $SECURE;;
  esac
fi

# Install SITES
for file in "${CONFIG_FILE[@]}";
do
  source $file
  echo
  echo -e "installing ${GREEN}$DOMAIN${NC} ..."

  echo "---> Creating folder"
	mkdir -p $ROOT_PATH

  # Clone Github
  if $GITHUB;
  then
    echo "Cloning $GITHUB_REPO to $ROOT_PATH ..."
    ./bin/clone-github.sh -r $GITHUB_REPO -p $ROOT_PATH -u $GITHUB_USERNAME
  fi

  # Install Environnement
  case $ENVIRONNEMENT in
    NodeJS)
      ./bin/server-block.sh --add $WEB_SERVER --path $ROOT_PATH --domain $DOMAIN --proxy $PORT
      ./bin/nodejs.sh --install --start --path $ROOT_PATH;;
    Wordpress)
      ./bin/server-block.sh --add $WEB_SERVER --path $ROOT_PATH --domain $DOMAIN
      ./bin/wordpress.sh --install --path $ROOT_PATH --domain $DOMAIN;;
    Static)
      ./bin/server-block.sh --add $WEB_SERVER --path $ROOT_PATH --domain $DOMAIN
      ./bin/static.sh $ROOT_PATH;;
    *)
      echo -e "${RED}$ENVIRONNEMENT${NC} environnement not available"
      echo -e "Aborting, evaluating next"
      continue;;
  esac

  # Installing Additional Libraries (Mongoose|SQL)
  # Updating packages
  if [ $MONGOOSE ];
  then
    echo "Installing Mongoose"
    ./bin/mongoose.sh --install --db-name $MONGOOSE_DB_NAME --user $MONGOOSE_USER --pass $MONGOOSE_PASSWORD
  fi

  #Setup Folder security
  echo "---> Setting folder security"
	chown -R $CURRENT_USER:$CURRENT_USER $ROOT_PATH
	chmod -R 755 $ROOT_PATH

  # Setup SSL Certificate
  if $SSL;
  then
    echo -e "Setting up SSL for ${GREEN}$DOMAIN${NC} ..."
    ./bin/setup-ssl.sh $WEB_SERVER $DOMAIN
  fi

  # Start Environnement
  case $ENVIRONNEMENT in
    NodeJS)
      ./bin/nodejs.sh --start $ROOT_PATH;;
    *)
      echo "Nothing to start";;
  esac

done

# Restarting WebServer
if [ -n "$WEB_SERVER" ];
then
  echo "Restarting $WEB_SERVER ..."
  case $WEB_SERVER in
    Apache)
      ./bin/apache.sh --restart;;
    Nginx)
      ./bin/nginx.sh --restart;;
  esac
fi

echo "Done Installing."

./bin/server-info.sh
