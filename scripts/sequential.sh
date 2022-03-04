#!/bin/bash

timestamp() {
        date +"%s"
}

echo "$1: $(timestamp)" >> "$4"

if [ $(($1)) -lt $(($2)) ]
then
        $3 -Q --output=/dev/null --error=/dev/null /scripts/sequential.sh $(($1+1)) $2 $3 $4
fi

echo "Ending sequential job"

