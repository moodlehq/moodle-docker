FROM php:7.1-apache

ADD root/ /
RUN /tmp/setup/php-extensions.sh
RUN /tmp/setup/oci8-extension.sh

# For some reason we do need en_US here..
RUN mkdir /var/www/moodledata && chown www-data /var/www/moodledata
