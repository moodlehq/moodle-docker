# moodle-docker: Docker Containers for Moodle Developers
[![Build Status](https://travis-ci.org/moodlehq/moodle-docker.svg?branch=master)](https://travis-ci.org/moodlehq/moodle-docker/branches)

This repository contains Docker configuration aimed at Moodle developers and testers to easily deploy a testing environment for Moodle.

## Features:
* All supported database servers (PostgreSQL, MySQL, Micosoft SQL Server, Oracle XE)
* Behat/Selenium configuration for Firefox and Chrome
* Catch-all smtp server and web interface to messages using [MailHog](https://github.com/mailhog/MailHog/)
* All PHP Extensions enabled configured for external services (e.g. solr, ldap)
* All supported PHP versions
* Zero-configuration approach
* Backed by [automated tests](https://travis-ci.org/moodlehq/moodle-docker/branches)

## Prerequisites
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

# Install for manual testing (optional)
bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="Docker moodle" --shortname="docker_moodle" --adminpass="test" --adminemail="admin@example.com"
# Access http://localhost:8000/ on your browser

# Access phpMyAdmin (for MySQL and MariaDB databases)

If you are running MySQL or MariaDB, you can navigate to http://localhost:8001 to access phpMyAdmin for database management.

# Shut down containers
bin/moodle-docker-compose down
```

Note that the behat faildump directory is exposed at http://localhost:8000/_/faildumps/.

## Manual testing

Moodle is configured to listen on `http://localhost:8000/` and mailhog is listening on `http://localhost:8000/_/mail` to view emails which Moodle has sent out.


## Branching Model

This repo uses branches to accomodate different php versions as well as some of the higher/lower versions of PostgreSQL/MySQL:


| Branch Name  | PHP Version | Build Status | Notes |
|--------------|-------------|--------------|-------|
| master | 7.1.x | [![Build Status](https://travis-ci.org/moodlehq/moodle-docker.svg?branch=master)](https://travis-ci.org/moodlehq/moodle-docker) | Same as branch php71 |
| php71 | 7.1.x | [![Build Status](https://travis-ci.org/moodlehq/moodle-docker.svg?branch=php71)](https://travis-ci.org/moodlehq/moodle-docker) | |
| php70 | 7.0.x | [![Build Status](https://travis-ci.org/moodlehq/moodle-docker.svg?branch=php70)](https://travis-ci.org/moodlehq/moodle-docker) | |
| php56 | 5.6.x | [![Build Status](https://travis-ci.org/moodlehq/moodle-docker.svg?branch=php56)](https://travis-ci.org/moodlehq/moodle-docker) | |

## Advanced usage

As can be seen in [bin/moodle-docker-compose](https://github.com/moodlehq/moodle-docker/blob/travis/bin/moodle-docker-compose),
this repo is just a series of docker-compose configurations and light wrapper which make use of companion docker images. Each part
is designed to be reusable and you are encouraged to use the docker[-compose] commands as needed.

### Companion docker images

The following Moodle customised docker images are close companions of this project:

* [moodle-apache-php](https://github.com/moodlehq/moodle-php-apache): Apache/PHP Environment preconfigured for all Moodle environments
* [moodle-db-mssql](https://github.com/moodlehq/moodle-db-mssql): Microsoft SQL Server for Linux configured for Moodle
* [moodle-db-oracle](https://github.com/moodlehq/moodle-db-oracle): Oracle XE configured for Moodle

## Environment variables

You can change the configuration of the docker images by setting various environment variables before calling `bin/moodle-docker-compose up`.

| Environment Variable                      | Options                               | Notes                                                                        |
|-------------------------------------------|---------------------------------------|------------------------------------------------------------------------------|
| `MOODLE_DOCKER_DB`                        | pgsql, mariadb, mysql, mssql, oracle  | Database server to run agianst                                               |
| `MOODLE_DOCKER_WWWROOT`                   | Path on your file system              | The path to the Moodle codebase you intend to test.                          |
| `MOODLE_DOCKER_BROWSER`                   | firefox, chrome                       | The browser to run Behat against                                             |
| `MOODLE_DOCKER_PHPUNIT_EXTERNAL_SERVICES` | Empty, or set                         | If set, dependencies for memcached, redis, solr, and openldap are added      |
| `MOODLE_DOCKER_WEB_PORT`                  | Empty, or set to an integer           | Used as the port number for web. If set to 0, no port is used (default 8000) |


## Contributions

Are extremely welcome!
