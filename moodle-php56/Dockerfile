FROM php:5.6-apache

ADD root/ /
RUN /tmp/setup/php-extensions.sh
RUN /tmp/setup/mssql-extension.sh
RUN /tmp/setup/oci8-extension.sh

RUN mkdir /var/www/moodledata && chown www-data /var/www/moodledata
