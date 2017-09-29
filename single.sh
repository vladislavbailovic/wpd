#!/bin/bash


DBSTATE=$(docker ps | grep singledb)
if [ "" == "$DBSTATE" ]; then
	echo "Starting Single Site DB"
	#docker run --name singledb -e MYSQL_ROOT_PASSWORD=password -e MYSQL_DATABASE=single -d -p 127.0.0.5:3306:3306 mysql:5.7
	docker start singledb
else
	echo "Stoping Single Site DB"
	docker stop singledb
	#docker rm singledb
fi

WPSTATE=$(docker ps | grep singlewp)
if [ "" == "$DBSTATE" ]; then
	echo "Starting Single Site WP setup"
	docker run -e WORDPRESS_DB_PASSWORD=password -d --name singlewp --link singledb:mysql -p 127.0.0.6:80:80 -v "$PWD/single/":/var/www/html -v "$PWD/wp-content":/var/www/html/wp-content wordpress
else
	echo "Stopping Single Site WP"
	docker stop singlewp
	docker rm singlewp
fi

echo "Single Site environment toggled"
