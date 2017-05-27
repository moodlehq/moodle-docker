# docker-moodle: Docker Containers for Moodle Developers
[![Build Status](https://travis-ci.org/danpoltawski/docker-moodle.svg?branch=master)](https://travis-ci.org/danpoltawski/docker-moodle/branches)

This repository contains Docker configuration aimed at Moodle developers and testers to easily deploy a testing environment for Moodle.

## Features:
* All supported database servers (PostgreSQL, MySQL, Micosoft SQL Server, Oracle XE)
* Behat/Selenium configuration for Firefox and Chrome
* All PHP Extensions enabled configured for external services (e.g. solr, ldap)
* All supported PHP versions
* Zero-configuration approach
* Backed by [automated tests](https://travis-ci.org/danpoltawski/docker-moodle/branches)

## Prerequistes
* [Docker](https://docs.docker.com) and [Docker Compose](https://docs.docker.com/compose/) installed
* 3.25GB of RAM (to [run Microsoft SQL Server](https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup#prerequisites))

## Example usage

```bash
# Set up path to code and choose a db server (pgsql/mssql/oracle/mysql)
export MOODLE_DOCKER_WWWROOT=/path/to/moodle/code
export MOODLE_DOCKER_DB=mssql

# Ensure config.php is in place
cp config.docker-template.php $MOODLE_DOCKER_WWWROOT/config.php

# Start up containers
bin/moodle-docker-compose up -d

# Run behat tests..
bin/moodle-docker-compose exec webserver php admin/tool/behat/cli/init.php
# [..]

bin/moodle-docker-compose exec webserver php admin/tool/behat/cli/run.php --tags=@auth_manual
Running single behat site:
Moodle 3.3rc1 (Build: 20170505), 381db2fe8df5c381f633fa2a92e61c6f0d7308cb
Php: 7.1.5, sqlsrv: 14.00.0500, OS: Linux 4.9.13-moby x86_64
Server OS "Linux", Browser: "firefox"
Started at 25-05-2017, 19:04
...............

2 scenarios (2 passed)
15 steps (15 passed)
1m35.32s (41.60Mb)

# Shut down containers
bin/moodle-docker-compose down
```

## Branching Model

This repo uses branches to accomodate different php versions as well as some of the higher/lower versions of PostgreSQL/MySQL:


| Branch Name  | PHP Version | Build Status | Notes |
|--------------|-------------|--------------|-------|
| master | 7.1.x | [![Build Status](https://travis-ci.org/danpoltawski/docker-moodle.svg?branch=master)](https://travis-ci.org/danpoltawski/docker-moodle) | Same as branch php71 |
| php71 | 7.1.x | [![Build Status](https://travis-ci.org/danpoltawski/docker-moodle.svg?branch=php71)](https://travis-ci.org/danpoltawski/docker-moodle) | |
| php70 | 7.0.x | [![Build Status](https://travis-ci.org/danpoltawski/docker-moodle.svg?branch=php70)](https://travis-ci.org/danpoltawski/docker-moodle) | |
| php56 | 5.6.x | [![Build Status](https://travis-ci.org/danpoltawski/docker-moodle.svg?branch=php56)](https://travis-ci.org/danpoltawski/docker-moodle) | |
| latest | 7.1.x | [![Build Status](https://travis-ci.org/danpoltawski/docker-moodle.svg?branch=latest)](https://travis-ci.org/danpoltawski/docker-moodle) | Latest versions of PHP, MySQL and PostgresSQL  |
| lowest | 5.6.x | [![Build Status](https://travis-ci.org/danpoltawski/docker-moodle.svg?branch=latest)](https://travis-ci.org/danpoltawski/docker-moodle) | Lowest supported versions of PHP (5.6) , MySQL (5.5) and PostgresSQL (9.3) |

## Advanced usage

As can be seen in [bin/moodle-docker-compose](https://github.com/danpoltawski/docker-moodle/blob/travis/bin/moodle-docker-compose),
this repo is just a series of docker-compose configurations and light wrapper which make use of companion docker images. Each part
is designed to be reusable and you are encouraged to use the docker[-compose] commands as needed.

### Companion docker images

The following Moodle customised docker images are close companions of this project:

* [moodle-apache-php](https://github.com/danpoltawski/moodle-php-apache): Apache/PHP Environment preconfigured for all Moodle environments
* [moodle-db-mssql](https://github.com/danpoltawski/moodle-db-mssql): Microsoft SQL Server for Linux configured for Moodle
* [moodle-db-oracle](https://github.com/danpoltawski/moodle-db-oracle): Oracle XE configured for Moodle

## Note for Mac users

Mounting host directories into the docker container currently has some performance issues (see https://github.com/docker/for-mac/issues/77) and you may find your code perform slower than expected. [docker-sync](https://github.com/EugenMayer/docker-sync) may be a solution to this, but it has yet been considered in thsi repo.

## Contributions

Are extremely welcome!
