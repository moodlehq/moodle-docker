# Moodle Docker Containers for Developers

The idea behind these docker containers is to provide a set of preconfigured images for developer convenience. They are currently designed to be ephemeral.

So far there are two sets of images:

* Database engines - containers to host the Moodle database, configured to run and go
* A PHP host - configured to run php directly and serve moodle files with php-fpm

## A note about the php host

Having all parts of the infrastructure dockerised has some elegant advantages, but due to issues like https://github.com/docker/for-mac/issues/77 there can be advantages to keeping the PHP side of the setup outside of docker for development purposes. You may wish to use the php host only in situations like testing oracle (where the php driver can be a pain).

---

# docker-moodle-db-mssql

## Requirements
- This image requires Docker Engine 1.8+ in any of [their supported platforms](https://www.docker.com/products/overview).
- At least 3.25 GB of RAM. Make sure to assign enough memory to the Docker VM if you're running on Docker for [Mac](https://docs.docker.com/docker-for-mac/#/general) or [Windows](https://docs.docker.com/docker-for-windows/#/advanced).
- Requires the following environment flags
    - ACCEPT_EULA=Y
    - SA_PASSWORD=<your_strong_password>
    - A strong system administrator (SA) password: At least 8 characters including uppercase, lowercase letters, base-10 digits and/or non-alphanumeric symbols.


## Running Exposing SQL Server to localhost.

### Docker command
``docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=m@0dl3ing' -p 1433:1433 moodle-db-mssql``

### Config.php
```
$CFG = new stdClass();

$CFG->dbtype    = 'mssql'; // or sqlsrv
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'localhost';
$CFG->dbname    = 'moodle';
$CFG->dbuser    = 'sa';
$CFG->dbpass    = 'm@0dl3ing';
$CFG->prefix    = 'mdl_';

$CFG->wwwroot   = 'http://your.wwwroot';
$CFG->dataroot  = '/path/to/your/moodledata';
```

---

# docker-moodle-php

A php moodle installation which has support for Moodle DB drivers pgsql/mysqli/sqlsrv and oci8.

It exposes a php-fpm socket which a webserver can be pointed at, and php run on comamnd line.

``docker run -d --name moodle-php -v $PWD:/var/www/html --link moodle-db-mssql``
