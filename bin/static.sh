#!/bin/bash

DIR=$1

if [ "$(ls -A $DIR)" ]; then
     echo "$DIR is not Empty, nothing to change"
else
    echo "$DIR is Empty"
    cp ../config/index.html $DIR
fi

echo "Done."
