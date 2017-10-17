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

WPCLI_ARGS="$@"
CMD=${2:-}

if [ "$CMD" == "" ]; then
	echo "tbd"
else
	# Generic fallthrough - pass everything to WP CLI
	docker exec "$TARGET"wp wp "$WPCLI_ARGS"
fi
