#!/bin/bash

function wpd_usage {
	echo -e "Usage:\n\t$0 COMMAND PLUGIN";
}

function wpd_checkout {
	local current="$PWD"
	cd "$WORKING"/projects/plugins
	if [ ! -d "$PLUGIN" ]; then
		git clone "$WPD_CLONE_URL""$PLUGIN"
	else
		echo "Plugin already exists, not re-cloning"
	fi
	cd "$current"
}

function wpd_git_submodules {
	local current="$PWD"
	cd "$WORKING"/projects/plugins/"$PLUGIN"

	git submodule init
	git submodule update --recursive

	cd "$current"
}

function wpd_add_logs_dir {
	local current="$PWD"
	cd "$WORKING"/projects/plugins/"$PLUGIN"

	if [ ! -d logs ]; then
		echo "No logs dir, creating directory and log symlinks to follow"
		mkdir logs
		for directory in "$WORKING"/wordpress/*/; do
			local dir=$(basename "$directory")
			if [[ -f "$directory"wp-content/debug.log ]]; then
				echo "Linking default WP log for $dir"
				sudo ln -s "$directory"wp-content/debug.log logs/"$dir"-debug.log
			fi
		done
	else
		echo "Already have logs, not re-creating logs dir"
	fi
	wpd_gitignore_add "logs/"

	cd "$current"
}

function wpd_gitignore_add {
	local current="$PWD"
	local what=${1:-}
	cd "$WORKING"/projects/plugins/"$PLUGIN"

	if [ ! -f .gitignore ]; then
		echo "No gitignore, creating one"
		echo "$what" >> .gitignore
	else
		echo "Checking gitignore for $what"
		has_logs=$(grep "$what" .gitignore)
		if [ "" == "$has_logs" ]; then
			echo "Adding $what to gitignore"
			echo "$what" >> .gitignore
		else
			echo "$what already in gitignore: $has_logs"
		fi
	fi

	cd "$current"
}

function wpd_npm_setup {
	local current="$PWD"
	cd "$WORKING"/projects/plugins/"$PLUGIN"

	if [ -f package.json ]; then
		echo "We have NPM package file, setting up"
		npm install
	else
		echo "No package.json, skipping setup"
	fi

	cd "$current"
}

WORKING=$(dirname $0)
WORKING=$(readlink -m "$WORKING")
CMD=${1:-}
PLUGIN=${2:-}

if [ "" == "$PLUGIN" ]; then
	wpd_usage
	exit 1
fi

if [[ -f "$WORKING"/src-wpd/config.cfg ]]; then
	source "$WORKING"/src-wpd/config.cfg
else
	echo "Missing config file, aborting"
	exit 1
fi

if [ "checkout" == "$CMD" ]; then
	if [ "" == "$PLUGIN" ]; then
		wpd_usage
		exit 1
	fi
	wpd_checkout
	wpd_git_submodules
	wpd_add_logs_dir
	wpd_npm_setup
fi
