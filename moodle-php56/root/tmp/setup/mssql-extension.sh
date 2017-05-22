#!/usr/bin/env bash

set -e

echo "Downloading freedts files"
curl ftp://ftp.freetds.org/pub/freetds/stable/freetds-1.00.33.tar.gz -o /tmp/freetds-1.00.33.tar.gz
apt-get install -y unixodbc-dev

echo "Building mssql extension"
cd /tmp && tar -xvf freetds-1.00.33.tar.gz && cd freetds-1.00.33 \
    && ./configure --with-unixodbc=/usr --sysconfdir=/etc/freetds --enable-sybase-compat \
    && make -j$(nproc) \
    && make install

docker-php-ext-install -j$(nproc) mssql
