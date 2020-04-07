#!/bin/sh
echo "Configuring SSL ..."

while (( "$#" )); do 
  echo "---> Domain $1"
  shift
done

echo

