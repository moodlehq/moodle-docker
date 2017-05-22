#!/usr/bin/env bash

set -e

echo "Downloading oracle files"
curl https://raw.githubusercontent.com/AminMkh/docker-php7-oci8-apache/b7c740638776552f00178a5d12905cefb50c7848/oracle/instantclient-basic-linux.x64-12.1.0.2.0.zip\
    -o /tmp/instantclient-basic-linux.x64-12.1.0.2.0.zip
curl https://raw.githubusercontent.com/AminMkh/docker-php7-oci8-apache/b7c740638776552f00178a5d12905cefb50c7848/oracle/instantclient-sdk-linux.x64-12.1.0.2.0.zip\
    -o /tmp/instantclient-sdk-linux.x64-12.1.0.2.0.zip
curl https://raw.githubusercontent.com/AminMkh/docker-php7-oci8-apache/b7c740638776552f00178a5d12905cefb50c7848/oracle/instantclient-sqlplus-linux.x64-12.1.0.2.0.zip\
    -o /tmp/instantclient-sqlplus-linux.x64-12.1.0.2.0.zip

unzip /tmp/instantclient-basic-linux.x64-12.1.0.2.0.zip -d /usr/local/
rm /tmp/instantclient-basic-linux.x64-12.1.0.2.0.zip
unzip /tmp/instantclient-sdk-linux.x64-12.1.0.2.0.zip -d /usr/local/
rm /tmp/instantclient-sdk-linux.x64-12.1.0.2.0.zip
unzip /tmp/instantclient-sqlplus-linux.x64-12.1.0.2.0.zip -d /usr/local/
rm /tmp/instantclient-sqlplus-linux.x64-12.1.0.2.0.zip

ln -s /usr/local/instantclient_12_1 /usr/local/instantclient
ln -s /usr/local/instantclient/libclntsh.so.12.1 /usr/local/instantclient/libclntsh.so
ln -s /usr/local/instantclient/sqlplus /usr/bin/sqlplus

echo 'instantclient,/usr/local/instantclient' | pecl install oci8 && docker-php-ext-enable oci8
echo 'oci8.statement_cache_size = 0' >> /usr/local/etc/php/conf.d/docker-php-ext-oci8.ini
