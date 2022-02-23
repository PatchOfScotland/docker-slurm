#!/bin/bash

timestamp() {
	date +"%s"
}

echo "$(timestamp)" > "$1"

