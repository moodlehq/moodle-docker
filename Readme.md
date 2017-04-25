# docker-moodle-db-mssql

## Requirements
---
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


# docker-moodle-php

A php moodle installation which has support for Moodle DB drivers pgsql/mysqli/sqlsrv and oci8.

It exposes a php-fpm socket which a webserver can be pointed at, and php run on comamnd line.

``docker run -d --name moodle-php -v $PWD:/var/www/html --link moodle-db-mssql``
