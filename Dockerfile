FROM wordpress:apache
RUN apt-get update \
	&& apt-get install -y libzip-dev \
	&& apt-get install -y zlib1g-dev \
	&& apt-get install -y libzip2 \
	&& apt-get install -y zip \
	&& apt-get install -y mysql-client-5.5 \
	&& docker-php-ext-install zip \
	&& docker-php-ext-install exif
