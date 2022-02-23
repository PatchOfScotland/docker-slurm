#!/bin/bash

timestamp() {
        date +"%s"
}

echo "$1:$(timestamp)" >> "/scripts/results/sequential.txt"

if [ $1 -lt 100 ]
then
        sbatch /scripts/sequential.sh $(($1+1))
fi
