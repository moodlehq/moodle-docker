FROM php:7.1-apache

COPY setup-php-extensions.sh /tmp/
COPY install-oracle-client.sh /tmp/

RUN chmod +x /tmp/setup-php-extensions.sh && /tmp/setup-php-extensions.sh
RUN chmod +x /tmp/install-oracle-client.sh /tmp/install-oracle-client.sh

# For some reason we do need en_US here..
RUN mkdir /var/www/moodledata && chown www-data /var/www/moodledata
