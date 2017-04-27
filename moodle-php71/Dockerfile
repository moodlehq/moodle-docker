FROM php:7.1-apache

COPY setup-php-extensions.sh /tmp/
RUN chmod +x /tmp/setup-php-extensions.sh
RUN /tmp/setup-php-extensions.sh

COPY install-oracle-client.sh /tmp/
RUN chmod +x /tmp/install-oracle-client.sh
RUN /tmp/install-oracle-client.sh

# For some reason we do need en_US here..
RUN mkdir /var/www/moodledata && chown www-data /var/www/moodledata
