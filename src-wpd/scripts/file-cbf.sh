#!/bin/bash

hascs=$(which phpcs);
if [ "" == "$hascs" ]; then
	echo "Install PHP Code Sniffer"
	exit 1
fi
if [[ ! -f ./phpcs.ruleset.xml ]]; then
	echo "No ruleset file, aborting"
	exit 1
fi

phpcbf --standard=./phpcs.ruleset.xml $1
