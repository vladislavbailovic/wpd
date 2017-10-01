#!/bin/bash

function wpd_has_container {
	echo $(docker ps -a | grep "$1")
}

function wdp_next_ip {
	local oct=$(grep '127.0.0' /etc/hosts | awk '{ print $1 }' | sort -nr | sed -n '1 p' | cut -d . -f 4)
	let "oct++"
	echo "127.0.0.$oct"
}

function wdp_uninstall_container {
	if [[ ! -z $(wpd_has_container $1) ]]; then
		echo "Removing container $1"
		docker rm "$1"
		local tempfile=$(mktemp hosts.XXXXXXXXX)
		cat /etc/hosts | sed -e "/$1/d" >> "$tempfile"
		sudo cp /etc/hosts ~/hosts.uninstall.bkp
		sudo mv "$tempfile" /etc/hosts
		echo "All done!"
	else
		echo "Unknown container"
	fi
}

function wdp_install_database {
	local dbname="$1"
	local container="$dbname"db
	local nextip=$(wdp_next_ip)
	if [[ -z $(wpd_has_container "$container") ]]; then
		echo "Creating $container with DB $dbname on $nextip :3306"
		docker run --name "$container" -e MYSQL_ROOT_PASSWORD=password -e MYSQL_DATABASE="$dbname" -d -p "$nextip":3306:3306 mysql:5.7
		sudo cp /etc/hosts ~/hosts.install.bkp
		sudo echo "$nextip $container.dev #install" >> /etc/hosts
		echo "All done"
	else
		echo "Container $container already exists, won't install anything"
	fi
}

function wdp_install_wordpress {
	local wpname="$1"
	local wproot="$WORKING""/wordpress"
	local wploc="$wproot"/"$wpname"
	local dbcontainer="$wpname"db
	local container="$wpname"wp
	local nextip=$(wdp_next_ip)
	if [[ -z $(wpd_has_container "$container") ]]; then
		echo "Creating $container WP setup $wpname in $wploc linked with $dbcontainer - it will run on $nextip"
		if [ ! -d "$wproot" ]; then
			echo "WordPress setup root directory does not exist, creating"
			mkdir "$wproot"
			chown www-data:www-data "$wproot"
		fi
		mkdir -p "$WORKING"/working/plugins
		mkdir -p "$WORKING"/working/themes
		docker run \
			-e WORDPRESS_DB_PASSWORD=password -d \
			--name "$container" \
			--link "$dbcontainer":mysql \
			-p "$nextip":80:80 \
			-v "$wploc":/var/www/html \
			-v "$WORKING"/working/plugins:/var/www/html/wp-content/plugins \
			-v "$WORKING"/working/themes:/var/www/html/wp-content/themes \
			wordpress
		sudo cp /etc/hosts ~/hosts.install.bkp
		sudo echo "$nextip $container.dev #install" >> /etc/hosts
	else
		echo "Container $container already exists, won't install anything"
	fi

}

function wdp_start {
	local state=$(docker ps | grep "$1")
	if [ "" == "$state" ]; then
		if [[ ! -z $(wpd_has_container "$1") ]]; then
			echo "Booting $1"
			docker start "$1"
		else
			echo "Unknown container $1"
		fi
	else
		echo "Container for $1 already running"
	fi
}

function wdp_stop {
	local state=$(docker ps | grep "$1")
	if [ "" == "$state" ]; then
		echo "Container for $1 already stopped"
	else
		if [[ ! -z $(wpd_has_container "$1") ]]; then
			echo "Stopping $1"
			docker stop "$1"
		else
			echo "Unknown container $1"
		fi
	fi
}

function wdp_toggle {
	local state=$(docker ps | grep "$1")
	if [ "" == "$state" ]; then
		if [[ ! -z $(wpd_has_container "$1") ]]; then
			echo "Booting $1"
			docker start "$1"
		else
			echo "Unknown container $1"
		fi
	else
		if [[ ! -z $(wpd_has_container "$1") ]]; then
			echo "Stopping $1"
			docker stop "$1"
		else
			echo "Unknown container $1"
		fi
	fi
}

WORKING=$(dirname $0)
WORKING=$(readlink -m "$WORKING")
TARGET="multi"
CMD="toggle"

# Format: $0 [TARGET] [COMMAND]
if [ "$#" == 2 ]; then
	TARGET="$1"
	CMD="$2"
fi

# Format $0 [TARGET] toggle (implicit)
if [ "$#" == 1 ]; then
	TARGET="$1"
fi

if [ "start" == "$CMD" ]; then
	echo "Booting WordPress environment $TARGET"
	wdp_start "$TARGET"db
	wdp_start "$TARGET"wp
elif [ "stop" == "$CMD" ]; then
	echo "Halting WordPress environment $TARGET"
	wdp_stop "$TARGET"db
	wdp_stop "$TARGET"wp
elif [ "restart" == "$CMD" ]; then
	echo "Re-starting WordPress environment $TARGET"
	wdp_stop "$TARGET"db
	wdp_stop "$TARGET"wp
	wdp_start "$TARGET"db
	wdp_start "$TARGET"wp
elif [ "toggle" == "$CMD" ]; then
	echo "Toggling WordPress environment state for $TARGET"
	wdp_toggle "$TARGET"db
	wdp_toggle "$TARGET"wp
elif [ "install" == "$CMD" ]; then
	echo "Installing WordPress environment $TARGET"
	wdp_install_database $TARGET
	wdp_install_wordpress $TARGET
elif [ "uninstall" == "$CMD" ]; then
	echo "Uninstalling WordPress environment $TARGET"
	wdp_stop "$TARGET"db
	wdp_stop "$TARGET"wp
	wdp_uninstall_container "$TARGET"db
	wdp_uninstall_container "$TARGET"wp
elif [ "backup" == "$CMD" ]; then
	echo "Backing up database"
	dbname="$TARGET"db
	filename="$WORKING"/backup/"$dbname"-$(date +%Y-%m-%d.%H-%m).sql
	wdp_start $dbname
	mysqldump -u root -ppassword -h "$dbname.dev" "$TARGET" > "$filename"
	wc "$filename"
else
	echo "Usage $0 [TARGET] [COMMAND]"
	echo "... where COMMAND is one of these: start, stop, restart, toggle, install, uninstall, backup"
	echo "... and default target being 'multi'"
fi
