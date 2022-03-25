#!/bin/bash

timestamp() {
	date +"%s%N"
}

echo "$(timestamp)" > "$1"

