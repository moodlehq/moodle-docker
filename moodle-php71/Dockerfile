FROM php:7.1-apache

RUN apt-get update && apt-get install -y \
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
    ghostscript

RUN docker-php-ext-install -j$(nproc) \
    intl \
    mysqli \
    opcache \
    pgsql \
    soap \
    xsl \
    xmlrpc \
    zip \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install -j$(nproc) ldap \
    && pecl install solr memcached redis mongodb apcu igbinary \
    && docker-php-ext-enable solr memcached redis mongodb apcu igbinary \
    && echo 'apc.enable_cli = On' >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini


# Add Oracle..
RUN cd /tmp && curl https://raw.githubusercontent.com/AminMkh/docker-php7-oci8-apache/b7c740638776552f00178a5d12905cefb50c7848/oracle/instantclient-basic-linux.x64-12.1.0.2.0.zip -o instantclient-basic-linux.x64-12.1.0.2.0.zip \
    && curl https://raw.githubusercontent.com/AminMkh/docker-php7-oci8-apache/b7c740638776552f00178a5d12905cefb50c7848/oracle/instantclient-sdk-linux.x64-12.1.0.2.0.zip -o instantclient-sdk-linux.x64-12.1.0.2.0.zip \
    && curl https://raw.githubusercontent.com/AminMkh/docker-php7-oci8-apache/b7c740638776552f00178a5d12905cefb50c7848/oracle/instantclient-sqlplus-linux.x64-12.1.0.2.0.zip -o instantclient-sqlplus-linux.x64-12.1.0.2.0.zip

RUN unzip /tmp/instantclient-basic-linux.x64-12.1.0.2.0.zip -d /usr/local/ \
    && unzip /tmp/instantclient-sdk-linux.x64-12.1.0.2.0.zip -d /usr/local/ \
    && unzip /tmp/instantclient-sqlplus-linux.x64-12.1.0.2.0.zip -d /usr/local/

RUN ln -s /usr/local/instantclient_12_1 /usr/local/instantclient \
    && ln -s /usr/local/instantclient/libclntsh.so.12.1 /usr/local/instantclient/libclntsh.so \
    && ln -s /usr/local/instantclient/sqlplus /usr/bin/sqlplus

RUN echo 'instantclient,/usr/local/instantclient' | pecl install oci8 && docker-php-ext-enable oci8
RUN echo 'oci8.statement_cache_size = 0' >> /usr/local/etc/php/conf.d/docker-php-ext-oci8.ini


# For some reason we do need en_US here..
RUN apt-get install -y locales && echo "en_US.UTF-8 UTF-8\nen_AU.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen


RUN mkdir /var/www/moodledata && chown www-data /var/www/moodledata
