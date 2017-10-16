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

function wpd_expand_script_vars {
	local src=${1:-}
	local dest=${2:-}
	echo "Changing $src to $dest $WPD_PROJECT_BIN_PATH"
	if [[ -f "$src" ]]; then
		sed \
			-e "s/WPD_PLUGIN/$PLUGIN/g" \
			-e "s!WPD_PLUGIN_DIR!$WORKING/projects/plugins/$PLUGIN!g" \
			-e "s/WPD_DB_ROOT/$WPD_DB_ROOT/g" \
			-e "s/WPD_DB_PASS/$WPD_DB_PASS/g" \
			-e "s!WPD_PROJECT_BIN_PATH!$WPD_PROJECT_BIN_PATH!g" \
		"$src" >> "$dest"
		chmod u+x "$dest"
	fi
}

function wpd_add_git_hooks {
	local current="$PWD"
	local plugdir="$WORKING"/projects/plugins/"$PLUGIN"
	cd "$plugdir"

	if [[ -d "$plugdir"/.git ]]; then
		echo "Is git directory, check hooks"

		if [[ ! -f "$plugdir"/.git/hooks/post-commit ]]; then
			echo "No post commit hook, making our own"
			wpd_expand_script_vars "$WORKING/src-wpd/hooks/post-commit" "$plugdir"/.git/hooks/post-commit
			wpd_gitignore_add "*.tags"
		fi

		### this is still a little bit hardcore
		# if [[ ! -f "$plugdir"/.git/hooks/pre-commit ]]; then
		# 	local hascs=$(which phpcs)
		# 	if [ "" != "$hascs" ]; then
		# 		echo "No pre commit hook, making our own"
		# 		wpd_expand_script_vars "$WORKING/src-wpd/hooks/pre-commit" "$plugdir"/.git/hooks/pre-commit
		# 	fi
		# else
		# 	echo "We already have pre-commit hook, give up"
		# fi
	fi

	cd "$current"
}

function wpd_add_php_configs {
	local current="$PWD"
	local plugdir="$WORKING"/projects/plugins/"$PLUGIN"
	cd "$plugdir"

	if [[ ! -f "$plugdir"/phpcs.ruleset.xml ]]; then
		echo "Adding ruleset file"
		cp "$WORKING"/src-wpd/phpcs.ruleset.xml "$plugdir"/phpcs.ruleset.xml
	fi

	if [[ ! -d "$plugdir"/tests ]]; then
		echo "Creating tests dir with default setup"
		mkdir "$plugdir"/tests
		cp "$WORKING"/src-wpd/phpunit.xml.suffix "$plugdir"/phpunit.xml
	elif [[ ! -f "$plugdir"/phpunit.xml ]]; then
		echo "Tests dir with no phpunit, creating from template"
		local phpsfx=""
		local suffixsfx="suffix"
		if [[ -d "$plugdir"/tests/php ]]; then
			phpsfx=".phpdir"
			if [ $(ls "$plugdir"/tests/php/test-*.php | wc -l) -gt 0 ]; then
				suffixsfx="prefix"
			fi
		else
			if [ $(ls "$plugdir"/tests/test-*.php | wc -l) -gt 0 ]; then
				suffixsfx="prefix"
			fi
		fi
		local phpunit="phpunit.xml$phpsfx.$suffixsfx"
		if [[ -f "$WORKING"/src-wpd/"$phpunit" ]]; then
			echo "Copying file $phpunit"
			cp "$WORKING"/src-wpd/"$phpunit" "$plugdir"/phpunit.xml
		fi
	fi

	cd "$current"
}

function wpd_add_bin_dir {
	local current="$PWD"
	local plugdir="$WORKING"/projects/plugins/"$PLUGIN"
	cd "$plugdir"

	if [ ! -d bin ]; then
		echo "No bin dir, creating directory and log symlinks to follow"
		mkdir bin
	else
		echo "Already have bin, not re-creating bin dir"
	fi

	for script in "$WORKING"/src-wpd/scripts/*.sh; do
		local dest="$plugdir"/bin/$(basename "$script")
		echo "Checking $dest existence";
		if [[ -f "$script" ]]; then
			if [[ ! -f "$dest" ]]; then
				echo "Copying script to destination"
				wpd_expand_script_vars $script $dest
			fi
		fi
	done
	wpd_gitignore_add "bin/"
	wpd_add_php_configs

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

function wpd_plugin_equip {
	local current="$PWD"
	cd "$WORKING"/projects/plugins/"$PLUGIN"

	wpd_add_logs_dir
	wpd_add_bin_dir
	wpd_add_git_hooks

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

WPD_PROJECT_BIN_PATH="$WORKING"/projects/plugins/"$PLUGIN"

if [ "checkout" == "$CMD" ]; then
	wpd_checkout
	wpd_git_submodules
	wpd_npm_setup
	wpd_plugin_equip
elif [ "equip" == "$CMD" ]; then
	wpd_plugin_equip
fi
