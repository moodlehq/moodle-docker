#!/usr/bin/env bash

set -e

echo "Installing apt depdencies"


apt-get update
apt-get install -y \
    gettext \
    libcurl4-openssl-dev \
    libpq-dev \
    libmysqlclient-dev \
    libldap2-dev \
    libxslt-dev \
    libxml2-dev \
    libicu-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libmemcached-dev \
    zlib1g-dev \
    libpng12-dev \
    libaio1 \
    unzip \
    ghostscript \
    locales

#RUN apt-get install -y locales && echo "en_US.UTF-8 UTF-8\nen_AU.UTF-8 UTF-8" > /etc/locale.gen
locale-gen en_US.UTF-8 en_AU.UTF-8

echo "Installing php extensions"
docker-php-ext-install -j$(nproc) \
    intl \
    mysqli \
    opcache \
    pgsql \
    soap \
    xsl \
    xmlrpc \
    zip

docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
docker-php-ext-install -j$(nproc) gd

docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/
docker-php-ext-install -j$(nproc) ldap

pecl install solr memcache redis mongodb igbinary apcu-4.0.11 memcached-2.2.0
docker-php-ext-enable solr memcache memcached redis mongodb apcu igbinary

echo 'apc.enable_cli = On' >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini
