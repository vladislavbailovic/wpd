FROM wordpress:apache
RUN apt-get update \
	&& apt-get install -y libzip-dev \
	&& apt-get install -y zlib1g-dev \
	&& apt-get install -y libzip2 \
	&& apt-get install -y zip \
	&& apt-get install -y mysql-client-5.5 \
	&& docker-php-ext-install zip \
	&& docker-php-ext-install exif

# Add sudo in order to run wp-cli as the www-data user
RUN apt-get update && apt-get install -y sudo less

# Add WP-CLI
RUN curl -o /bin/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
COPY src-wpd/wp-su.sh /bin/wp
RUN chmod +x /bin/wp-cli.phar /bin/wp

# Cleanup
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
