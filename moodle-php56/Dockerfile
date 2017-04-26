FROM php:5.6-apache

RUN apt-get update && apt-get install -y \
    gettext \
    libpq-dev \
    libmysqlclient-dev \
    libldap2-dev \
    libxslt-dev \
    libxml2-dev \
    libicu-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
    libaio1 \
    unzip \
    unixodbc-dev

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
    && docker-php-ext-install -j$(nproc) ldap


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

RUN echo 'instantclient,/usr/local/instantclient' | pecl install oci8-1.4.10 && docker-php-ext-enable oci8


# For some reason we do need en_US here..
RUN apt-get install -y locales && echo "en_US.UTF-8 UTF-8\nen_AU.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen

# Install the latest version of freetds manually, because we need it for emoji support (core_dml_testcase::test_four_byte_character_insertion)
RUN curl ftp://ftp.freetds.org/pub/freetds/stable/freetds-1.00.33.tar.gz -o /tmp/freetds-1.00.33.tar.gz
RUN cd /tmp && tar -xvf freetds-1.00.33.tar.gz && cd freetds-1.00.33 \
        && ./configure --with-unixodbc=/usr --sysconfdir=/etc/freetds --enable-sybase-compat \
        && make -j$(nproc) \
        && make install
COPY freetds.conf /etc/freetds/freetds.conf

#RUN apt-get update && apt-get install -y unixodbc-dev
RUN docker-php-ext-install -j$(nproc) mssql

RUN mkdir /var/www/moodledata && chown www-data /var/www/moodledata
