#!/bin/bash

function wpd_usage {
	echo -e "Usage:\n\t$0 TARGET COMMAND"
	echo -e "... where COMMAND is one of these:"
	echo -e "\tstart - starts WP/DB container combo"
	echo -e "\tstop - stops WP/DB container combo"
	echo -e "\trestart - stops, then starts WP/DB container combo"
	echo -e "\ttoggle - toggle WP/DB container combo state"
	echo -e "\tinstall - install new WP/DB container, pulling/creating images as needed. Also adds stuff to hosts file"
	echo -e "\tuninstall - removes container combo and hosts entry, leaves images and files though"
	echo -e "\tbackup-db - backs up DB into a timestamped SQL file"
	echo -e "\trestore-db [SEARCH_STRING] - restores DB from a SQL file. Defaults to latest, or tries to match the optional SEARCH_STRING"
	exit 1
}

function wpd_has_container {
	echo $(docker ps -a | grep "$1")
}

function wpd_has_image {
	echo $(docker images | grep "$1")
}

function wpd_build_image {
	docker build "$WORKING" -t $WPDIMAGE
}

function wdp_next_ip {
	local oct=$(grep '127.0.0' /etc/hosts | awk '{ print $1 }' | sort -k4nr -t. | sed -n '1 p' | cut -d . -f 4)
	let "oct++"
	echo "127.0.0.$oct"
}

function wdp_backup_hosts {
	local infix=$(date +%Y-%m-%d.%H-%M)-${1:-'backup'}
	sudo cp /etc/hosts ~/hosts.$infix.bkp
}

function wdp_uninstall_container {
	if [[ ! -z $(wpd_has_container $1) ]]; then
		echo "Removing container $1"
		docker rm "$1"
		local tempfile=$(mktemp hosts.XXXXXXXXX)
		cat /etc/hosts | sed -e "/$1/d" >> "$tempfile"
		wdp_backup_hosts "$1-uninstall"
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
		wdp_backup_hosts "$1-install"
		sudo echo "$nextip $container.test #install" >> /etc/hosts
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
	if [[ -z $(wpd_has_image "$WPDIMAGE") ]]; then
		wpd_build_image
	fi
	if [[ -z $(wpd_has_container "$container") ]]; then
		echo "Creating $container WP setup $wpname in $wploc linked with $dbcontainer - it will run on $nextip"
		if [ ! -d "$wproot" ]; then
			echo "WordPress setup root directory does not exist, creating"
			mkdir "$wproot"
			chown www-data:www-data "$wproot"
		fi
		mkdir -p "$WORKING"/projects/plugins
		mkdir -p "$WORKING"/projects/themes
		docker run \
			-e WORDPRESS_DB_PASSWORD=password -d \
			--name "$container" \
			--link "$dbcontainer":mysql \
			-p "$nextip":80:80 \
			-v "$wploc":/var/www/html \
			-v "$WORKING"/projects/plugins:/var/www/html/wp-content/plugins \
			-v "$WORKING"/projects/themes:/var/www/html/wp-content/themes \
			"$WPDIMAGE"
		wdp_backup_hosts "$1-install"
		sudo echo "$nextip $container.test #install" >> /etc/hosts
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

function wdp_hubify {
	hname="$TARGET"wp
	docker exec "$hname" /bin/bash -c 'echo "192.168.50.4 local.wpmudev.org" >> /etc/hosts'
	docker exec "$hname" /bin/bash -c 'echo "127.0.0.1 '$hname'.test" >> /etc/hosts'
	echo "Hubified."
}

function wdp_info {
	ip=$(docker inspect "$TARGET"wp | grep '"IPAddress' | tail -n1 | awk -F'"' '{print $4}')
	echo "WordPress runs on $ip"
}

WORKING=$(dirname $0)
WORKING=$(readlink -m "$WORKING")
TARGET=""
CMD=""
WPDIMAGE="wpddev"

if [ $# -lt 2 ]; then
	wpd_usage
fi

# Format: $0 [TARGET] [COMMAND]
if [ $# -ge 2 ]; then
	TARGET="$1"
	CMD="$2"
fi

if [ "" == "$TARGET" ]; then
	wpd_usage
fi

if [ "start" == "$CMD" ]; then
	echo "Booting WordPress environment $TARGET"
	wdp_start "$TARGET"db
	wdp_start "$TARGET"wp
	wdp_hubify
	wdp_info
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
	wdp_hubify
	wdp_info
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
elif [ "backup-db" == "$CMD" ]; then
	echo "Backing up database"
	dbname="$TARGET"db
	filename="$WORKING"/backup/"$dbname"-$(date +%Y-%m-%d.%H-%m).sql
	wdp_start $dbname
	mysqldump -u root -ppassword -h "$dbname.test" "$TARGET" > "$filename"
	wc "$filename"
elif [ "restore-db" == "$CMD" ]; then
	echo "Restoring database"
	dbname="$TARGET"db
	portion=${3:-}
	filename=$(ls -r "$WORKING"/backup/"$dbname"*"$portion"*.sql | sed -n '1p')
	if [[ ! -f "$filename" ]]; then exit; fi
	echo "Restoring $TARGET DB from $filename"
	mysql -u root -ppassword -h "$dbname.test" "$TARGET" < "$filename"
	echo "All done restoring from $filename"
elif [ "hubify" == "$CMD" ]; then
	wdp_hubify
elif [ "info" == "$CMD" ]; then
	wdp_info
else
	wpd_usage
fi
