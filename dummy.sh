#!/bin/bash

TARGET=${1:-once}
POSTS_COUNT=5
POST_TYPE=${2:-post}

function wpds_mkpost {
	paragraphs=$(shuf -i 3-15 -n1)
	post_title=$(~/Scripts/lorem.sh -d -s1)
	post_content=$(~/Scripts/lorem.sh -d -p ${paragraphs})

	docker exec \
		-e TITLE="$post_title" \
		-e CONTENT="$post_content" \
		-e POST_TYPE="$POST_TYPE" \
		"$TARGET"wp /bin/bash -c \
		'sudo -E -u www-data /bin/wp-cli.phar post create \
		--post_type="$POST_TYPE" \
		--post_title="$TITLE" \
		--post_content="$CONTENT"\
		--post_status=publish
		'
}

function wpds_mkposts {
	for i in $(seq 1 $POSTS_COUNT); do
		wpds_mkpost
	done
}

function wpds_mkusers {
	for user in editor author contributor subscriber; do
		docker exec "$TARGET"wp wp user create \
			"$user" "$user"@localhost.loc \
			--role="$user" \
			--user_pass="$user"
	done
}

wpds_mkusers
