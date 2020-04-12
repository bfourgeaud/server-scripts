#!/bin/bash
while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
      -r|--repo)
        GITHUB_REPO=$2
        shift;;
      -p|--path)
        FILE_PATH=$2
        shift;;
      -u|--username)
        GITHUB_USER=$2
        shift;;
      *)
        echo "Invalid argument $key"
        exit 0;;
  esac
  shift;
done

if ! [ -n "$FILE_PATH" ];
then
  echo "Folder Path not given as argument. Aborting git clone"
  exit 0;
fi

if ! [ -n "$GITHUB_REPO" ];
then
  read -p "Enter GitHub clone link :" GITHUB_REPO
fi

if ! [ -n "$GITHUB_USER" ];
then
  read -p "Enter GitHub username :" GITHUB_USER
fi

read -s -p "Enter GitHub password :" GITHUB_PASS

echo "---> Deleting folder content"
rm -rf $FILE_PATH/{,.[!.],..?}*

echo "---> Cloning to $FILE_PATH"
cd $FILE_PATH

# TODO : parse github-link string to perform : https://<user>:<pass>@github.com/<user>/<repo>
CLONE_LINK="${GITHUB_REPO/'<<PASS>>'/$GITHUB_PASS}"

git clone -q $CLONE_LINK .
