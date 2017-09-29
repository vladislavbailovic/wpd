#!/bin/bash

#docker run --name multidb -e MYSQL_ROOT_PASSWORD=password -e MYSQL_DATABASE=multi -d -p 127.0.0.2:3306:3306 mysql:5.7
#docker run -e WORDPRESS_DB_PASSWORD=password -d --name multiwp --link multidb:mysql -p 127.0.0.3:80:80 -v "$PWD/multi/":/var/www/html -v "$PWD/wp-content":/var/www/html/wp-content wordpress

DBSTATE=$(docker ps | grep multidb)
if [ "" == "$DBSTATE" ]; then
	echo "Starting Multisite DB"
	#docker run --name multidb -e MYSQL_ROOT_PASSWORD=password -e MYSQL_DATABASE=multi -d -p 127.0.0.2:3306:3306 mysql:5.7
	docker start multidb
else
	echo "Stoping Multisite DB"
	docker stop multidb
	#docker rm multidb
fi

WPSTATE=$(docker ps | grep multiwp)
if [ "" == "$DBSTATE" ]; then
	echo "Starting Multisite WP setup"
	docker run -e WORDPRESS_DB_PASSWORD=password -d --name multiwp --link multidb:mysql -p 127.0.0.3:80:80 -v "$PWD/multi/":/var/www/html -v "$PWD/wp-content":/var/www/html/wp-content wordpress
else
	echo "Stopping Multisite WP"
	docker stop multiwp
	docker rm multiwp
fi

echo "Multisite environment toggled"
