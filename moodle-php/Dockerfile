FROM ubuntu:16.04
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
        apt-get -y install \
        php-pear \
        php7.0 \
        php7.0-cgi \
        php7.0-cli \
        php7.0-common \
        php7.0-curl \
        php7.0-dev \
        php7.0-gd \
        php7.0-intl \
        php7.0-mcrypt \
        php7.0-mbstring \
        php7.0-xmlrpc \
        php7.0-mysql \
        php7.0-pgsql \
        php7.0-fpm \
        php7.0-zip \
        php7.0-ldap \
        php7.0-soap \
        unzip \
        apt-transport-https \
        unixodbc-dev \
        build-essential \
        libaio1 \
        autoconf && apt-get clean

# Setup mssql dependencies
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
ADD https://packages.microsoft.com/config/ubuntu/16.04/prod.list /etc/apt/sources.list.d/mssql-tools.list
ENV ACCEPT_EULA Y
RUN apt-get update && apt-get -y install msodbcsql mssql-tools
RUN pecl install sqlsrv
COPY php-fpm.conf /etc/php/7.0/fpm/php-fpm.conf

# For some reason we do need en_US here..
RUN apt-get install -y locales && echo "en_US.UTF-8 UTF-8\nen_AU.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen

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

RUN echo 'instantclient,/usr/local/instantclient' | pecl install oci8

RUN echo "; priority=20\nextension=sqlsrv.so"  >> /etc/php/7.0/mods-available/sqlsrv.ini
RUN echo "; priority=20\nextension=oci8.so"  >> /etc/php/7.0/mods-available/oci8.ini
RUN phpenmod sqlsrv oci8

RUN mkdir -p /var/moodle/moodledata /var/moodle/phpunitdata /var/moodle/behatdata

EXPOSE 9000
WORKDIR /usr/src
CMD php-fpm7.0 -R

