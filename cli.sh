#!/bin/bash

function wpd_cli_usage {
	echo -e "Usage\n\t$0 TARGET WP_CLI-COMMANDS"
	exit 1
}

TARGET=${1:-}
if [ "" == "$TARGET" ]; then
	wpd_cli_usage
fi
