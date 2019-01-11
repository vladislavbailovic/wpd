#!/bin/bash

function wpd_cli_usage {
	echo -e "Usage\n\t$0 TARGET WP_CLI-COMMANDS"
	exit 1
}

if [ $# -lt 2 ]; then
	wpd_cli_usage
fi

TARGET=${1:-}
if [ "" == "$TARGET" ]; then
	wpd_cli_usage
fi
shift

DOCKER_ARGS="-it"
WPCLI_ARGS="$@"

#echo "$WPCLI_ARGS"; exit;

docker exec "$DOCKER_ARGS" "$TARGET"wp wp "$WPCLI_ARGS"

# wp config create --dbhost="$TARGET"db.test --dbname="$TARGET" --dbuser=root --dbpass=pass
#wp core install --url="$TARGET"wp.test --title="$TARGET" --admin_user=bog --admin_password=bog --admin_email=bog@localhost.loc

