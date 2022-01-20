# moodle-docker: Docker Containers for Moodle Developers
[![Build Status](https://github.com/moodlehq/moodle-docker/workflows/moodle-docker%20CI/badge.svg?branch=master)](https://github.com/moodlehq/moodle-docker/actions/workflows/ci.yml?query=branch%3Amaster)

This repository contains Docker configuration aimed at Moodle developers and testers to easily deploy a testing environment for Moodle.

## Features:
* All supported database servers (PostgreSQL, MySQL, Micosoft SQL Server, Oracle XE)
* Behat/Selenium configuration for Firefox and Chrome
* Catch-all smtp server and web interface to messages using [MailHog](https://github.com/mailhog/MailHog/)
* All PHP Extensions enabled configured for external services (e.g. solr, ldap)
* All supported PHP versions
* Zero-configuration approach
* Backed by [automated tests](https://travis-ci.com/moodlehq/moodle-docker/branches)

## Prerequisites
* [Docker](https://docs.docker.com) and [Docker Compose](https://docs.docker.com/compose/) installed
* 3.25GB of RAM (if you choose [Microsoft SQL Server](https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup#prerequisites) as db server)

## Quick start

```bash
# Set up path to Moodle code
export MOODLE_DOCKER_WWWROOT=/path/to/moodle/code
# Choose a db server (Currently supported: pgsql, mariadb, mysql, mssql, oracle)
export MOODLE_DOCKER_DB=pgsql

# Ensure customized config.php for the Docker containers is in place
cp config.docker-template.php $MOODLE_DOCKER_WWWROOT/config.php

# Start up containers
bin/moodle-docker-compose up -d

# Wait for DB to come up (important for oracle/mssql)
bin/moodle-docker-wait-for-db

# Work with the containers (see below)
# [..]

# Shut down and destroy containers
bin/moodle-docker-compose down
```
## Run several Moodle instances

By default, the script will load a single instance. If you want to run two
or more different versions of Moodle at the same time, you have to add this
environment variable prior running any of the steps at `Quick start`:

```bash
# Define a project name; it will appear as a prefix on container names.
export COMPOSE_PROJECT_NAME=moodle34

# Use a different public web port from those already taken
export MOODLE_DOCKER_WEB_PORT=1234

# [..] run all "Quick steps" now
```

Having set up several Moodle instances, you need to have set up
the environment variable `COMPOSE_PROJECT_NAME` to just refer
to the instance you expect to. See
[envvars](https://docs.docker.com/compose/reference/envvars/)
to see more about `docker-compose` environment variables.

## Use containers for running behat tests

```bash
# Initialize behat environment
bin/moodle-docker-compose exec webserver php admin/tool/behat/cli/init.php
# [..]

# Run behat tests
bin/moodle-docker-compose exec -u www-data webserver php admin/tool/behat/cli/run.php --tags=@auth_manual
Running single behat site:
Moodle 3.4dev (Build: 20171006), 33a3ec7c9378e64c6f15c688a3c68a39114aa29d
Php: 7.1.9, pgsql: 9.6.5, OS: Linux 4.9.49-moby x86_64
Server OS "Linux", Browser: "firefox"
Started at 25-05-2017, 19:04
...............

2 scenarios (2 passed)
15 steps (15 passed)
1m35.32s (41.60Mb)
```

Notes:

* The behat faildump directory is exposed at http://localhost:8000/_/faildumps/.
* Use `MOODLE_DOCKER_BROWSER` to switch the browser you want to run the test against.
  You need to recreate your containers using `bin/moodle-docker-compose` as described below, if you change it.
* Check the [Custom commands](#custom-commands) section for more options.

## Use containers for running phpunit tests

```bash
# Initialize phpunit environment
bin/moodle-docker-compose exec webserver php admin/tool/phpunit/cli/init.php
# [..]

# Run phpunit tests
bin/moodle-docker-compose exec webserver vendor/bin/phpunit auth_manual_testcase auth/manual/tests/manual_test.php
Moodle 3.4dev (Build: 20171006), 33a3ec7c9378e64c6f15c688a3c68a39114aa29d
Php: 7.1.9, pgsql: 9.6.5, OS: Linux 4.9.49-moby x86_64
PHPUnit 5.5.7 by Sebastian Bergmann and contributors.

..                                                                  2 / 2 (100%)

Time: 4.45 seconds, Memory: 38.00MB

OK (2 tests, 7 assertions)
```

Notes:
* If you want to run test with coverage report, use command: `bin/moodle-docker-compose exec webserver phpdbg -qrr vendor/bin/phpunit --coverage-text auth_manual_testcase auth/manual/tests/manual_test.php`
* Check the [Custom commands](#custom-commands) section for more options.

## Use containers for manual testing

```bash
# Initialize Moodle database for manual testing
bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="Docker moodle" --shortname="docker_moodle" --summary="Docker moodle site" --adminpass="test" --adminemail="admin@example.com"
```

Notes:
* Moodle is configured to listen on `http://localhost:8000/`.
* Mailhog is listening on `http://localhost:8000/_/mail` to view emails which Moodle has sent out.
* The admin `username` you need to use for logging in is `admin` by default. You can customize it by passing `--adminuser='myusername'`
* Check the [Custom commands](#custom-commands) section for more options.

## Use containers for running behat tests for the Moodle App

In order to run Behat tests for the Moodle App, you need to install the [local_moodlemobileapp](https://github.com/moodlehq/moodle-local_moodlemobileapp) plugin in your Moodle site. Everything else should be the same as running standard Behat tests for Moodle. Make sure to filter tests using the `@app` tag.

The Behat tests will be run against a container serving the mobile application, you have two options here:

1. Use a Docker image that includes the application code. You need to specify the `MOODLE_DOCKER_APP_VERSION` env variable and the [moodlehq/moodleapp](https://hub.docker.com/r/moodlehq/moodleapp) image will be downloaded from Docker Hub. You can read about the available images in [Moodle App Docker Images](https://docs.moodle.org/dev/Moodle_App_Docker_Images) (for Behat, you'll want to run the ones with the `-test` suffix).

2. Use a local copy of the application code and serve it through Docker, similar to how the Moodle site is being served. Set the `MOODLE_DOCKER_APP_PATH` env variable to the codebase in you file system. This will assume that you've already initialized the app calling `npm install` and `npm run setup` locally.

For both options, you also need to set `MOODLE_DOCKER_BROWSER` to "chrome".

```bash
# Install local_moodlemobileapp plugin
git clone git://github.com/moodlehq/moodle-local_moodlemobileapp "$MOODLE_DOCKER_WWWROOT/local/moodlemobileapp"

# Initialize behat environment
bin/moodle-docker-compose exec webserver php admin/tool/behat/cli/init.php
# (you should see "Configured app tests for version X.X.X" here)

# Run behat tests
bin/moodle-docker-compose exec -u www-data webserver php admin/tool/behat/cli/run.php --tags="@app&&@mod_login"
Running single behat site:
Moodle 4.0dev (Build: 20200615), a2b286ce176fbe361f0889abc8f30f043cd664ae
Php: 7.2.30, pgsql: 11.8 (Debian 11.8-1.pgdg90+1), OS: Linux 5.3.0-61-generic x86_64
Server OS "Linux", Browser: "chrome"
Browser specific fixes have been applied. See http://docs.moodle.org/dev/Acceptance_testing#Browser_specific_fixes
Started at 13-07-2020, 18:34
.....................................................................

4 scenarios (4 passed)
69 steps (69 passed)
3m3.17s (55.02Mb)
```

Notes:
* Check the [Custom commands](#custom-commands) section for more options.

If you are going with the second option, this *can* be used for local development of the Moodle App, given that the `moodleapp` container serves the app on the local 8100 port. However, this is intended to run Behat tests that require interacting with a local Moodle environment. Normal development should be easier calling `npm start` in the host system.

By all means, if you don't want to have npm installed locally you can go full Docker executing the following commands before starting the containers:

```
docker run --volume $MOODLE_DOCKER_APP_PATH:/app --workdir /app node:14 npm install
docker run --volume $MOODLE_DOCKER_APP_PATH:/app --workdir /app node:14 npm run setup
```

You can learn more about writing tests for the app in [Acceptance testing for the Moodle App](https://docs.moodle.org/dev/Acceptance_testing_for_the_Moodle_App).

## Using VNC to view behat tests

If `MOODLE_DOCKER_SELENIUM_VNC_PORT` is defined, selenium will expose a VNC session on the port specified so behat tests can be viewed in progress.

For example, if you set `MOODLE_DOCKER_SELENIUM_VNC_PORT` to 5900..
1. Download a VNC client: https://www.realvnc.com/en/connect/download/viewer/
2. With the containers running, enter 0.0.0.0:5900 as the port in VNC Viewer. You will be prompted for a password. The password is 'secret'.
3. You should be able to see an empty Desktop. When you run any Behat tests a browser will popup and you will see the tests execute.

## Stop and restart containers

`bin/moodle-docker-compose down` which was used above after using the containers stops and destroys the containers. If you want to use your containers continuously for manual testing or development without starting them up from scratch everytime you use them, you can also just stop without destroying them. With this approach, you can restart your containers sometime later, they will keep their data and won't be destroyed completely until you run `bin/moodle-docker-compose down`.

```bash
# Stop containers
bin/moodle-docker-compose stop

# Restart containers
bin/moodle-docker-compose start
```

## Custom commands

### moodle-docker-bash
This script was created to easily run any command inside any container. First parameter will be the container name and second one will be the command. Example:
```bash
~$ bin/moodle-docker-bash webserver php -v
PHP 7.4.23 (cli) (built: Sep  3 2021 18:14:02) ( NTS )
```
```bash
~$ bin/moodle-docker-bash db psql --version
psql (PostgreSQL) 11.13 (Debian 11.13-1.pgdg90+1)
```

### mbash
As most of the commands using the `moodle-docker-bash` script will be run on the `webserver` container, this is a shortcut of that script that runs the commands only in the `webserver` container. Example:
```bash
~$ bin/mbash php -v
PHP 7.4.23 (cli) (built: Sep  3 2021 18:14:02) ( NTS )
```

### minstall
This script was created to be automatically installed in the webserver container and to easily run any install command. First parameter will be the database to install (moodle, phpunit or behat) and the rest will be all the parameters that want to be used to override the default one. Note that this script needs to be run either withing the container shell or using `moodle-docker-bash`. Examples:
```bash
~$ bin/mbash minstall moodle --fullname="Moodle first instance" --adminpass="admin"
-------------------------------------------------------------------------------
== Setting up database ==
-->System
```
```bash
~$ bin/mbash minstall phpunit
Initialising Moodle PHPUnit test environment...
```
```bash
~$ bin/mbash minstall behat
You are already using the latest available Composer version 2.1.8 (stable channel).
Installing dependencies from lock file (including require-dev)
```

### mtest
This script was created to be automatically installed in the webserver container and to easily run any test command. First parameter will be the tests to be run (phpunit or behat) and the rest will be all the parameters that want to be used to override the default ones. Note that this script needs to be run either withing the container shell or using `moodle-docker-bash`. Examples:
```bash
~$ bin/mbash mtest phpunit --filter auth_manual_testcase
Moodle 3.11.3 (Build: 20210913), 8c02bd32af238dfc83727fb4260b9caf1b622fdb
Php: 7.4.23, pgsql: 11.13 (Debian 11.13-1.pgdg90+1), OS: Linux 5.10.47-linuxkit x86_64
```
```bash
~$ bin/mbash mtest behat --tags=@auth_manual
Running single behat site:
```

### mutil
This script was created to be automatically installed in the webserver container and to easily access the `util.php` files of phpunit and behat. First parameter will be the test environment (phpunit or behat) and the rest will be all the parameters that want to be used to override the default ones. Note that this script needs to be run either withing the container shell or using `moodle-docker-bash`. Examples:
```bash
~$ bin/mbash mutil phpunit --drop
Purging dataroot:
Dropping tables:
```
```bash
~$ bin/mbash mutil behat --drop
Dropping tables:
```

### mfixversion
After increasing the version number in a branch, going back to the master branch might cause version problems. This script was created to easily solve that issue. Note that this script needs to be run either withing the container shell or using `moodle-docker-bash`. Example:
```bash
~$ bin/mbash mfixversion
-------------------------------------------------------------------------------
== Resetting all version numbers ==
```

## Environment variables

You can change the configuration of the docker images by setting various environment variables **before** calling `bin/moodle-docker-compose up`.
When you change them, use `bin/moodle-docker-compose down && bin/moodle-docker-compose up -d` to recreate your environment.

| Environment Variable                      | Mandatory | Allowed values                        | Default value | Notes                                                                        |
|-------------------------------------------|-----------|---------------------------------------|---------------|------------------------------------------------------------------------------|
| `MOODLE_DOCKER_DB`                        | yes       | pgsql, mariadb, mysql, mssql, oracle  | none          | The database server to run against                                           |
| `MOODLE_DOCKER_WWWROOT`                   | yes       | path on your file system              | none          | The path to the Moodle codebase you intend to test                           |
| `MOODLE_DOCKER_PHP_VERSION`               | no        | 7.4, 7.3, 7.2, 7.1, 7.0, 5.6          | 7.3           | The php version to use                                                       |
| `MOODLE_DOCKER_BROWSER`                   | no        | firefox, chrome,  firefox:&lt;tag&gt;, chrome:&lt;tag&gt; | firefox:3       | The browser to run Behat against. Supports a colon notation to specify a specific Selenium docker image version to use. e.g. firefox:2.53.1 can be used to run with older versions of Moodle (<3.5)              |
| `MOODLE_DOCKER_PHPUNIT_EXTERNAL_SERVICES` | no        | any value                             | not set       | If set, dependencies for memcached, redis, solr, and openldap are added      |
| `MOODLE_DOCKER_WEB_HOST`                  | no        | any valid hostname                    | localhost     | The hostname for web                                |
| `MOODLE_DOCKER_WEB_PORT`                  | no        | any integer value (or bind_ip:integer)| 127.0.0.1:8000| The port number for web. If set to 0, no port is used.<br/>If you want to bind to any host IP different from the default 127.0.0.1, you can specify it with the bind_ip:port format (0.0.0.0 means bind to all) |
| `MOODLE_DOCKER_SELENIUM_VNC_PORT`         | no        | any integer value (or bind_ip:integer)| not set       | If set, the selenium node will expose a vnc session on the port specified. Similar to MOODLE_DOCKER_WEB_PORT, you can optionally define the host IP to bind to. If you just set the port, VNC binds to 127.0.0.1 |
| `MOODLE_DOCKER_APP_PATH`                  | no        | path on your file system              | not set       | If set and the chrome browser is selected, it will start an instance of the Moodle app from your local codebase |
| `MOODLE_DOCKER_APP_VERSION`               | no        | a valid [app docker image version](https://docs.moodle.org/dev/Moodle_App_Docker_images) | not set       | If set will start an instance of the Moodle app if the chrome browser is selected |
| `MOODLE_DOCKER_APP_RUNTIME`               | no        | 'ionic3' or 'ionic5'                  | not set       | Set this to indicate the runtime being used in the Moodle app. In most cases, this can be ignored because the runtime is guessed automatically (except on Windows using the `.cmd` binary). In case you need to set it manually and you're not sure which one it is, versions 3.9.5 and later should be using Ionic 5. |

## Using XDebug for live debugging

The XDebug PHP Extension is not included in this setup and there are reasons not to include it by default.

However, if you want to work with XDebug, especially for live debugging, you can add XDebug to a running webserver container easily:

```
# Install XDebug extension with PECL
moodle-docker-compose exec webserver pecl install xdebug

# Set some wise setting for live debugging - change this as needed
read -r -d '' conf <<'EOF'
; Settings for Xdebug Docker configuration
xdebug.mode = debug
xdebug.client_host = host.docker.internal
EOF
moodle-docker-compose exec webserver bash -c "echo '$conf' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"

# Enable XDebug extension in Apache and restart the webserver container
moodle-docker-compose exec webserver docker-php-ext-enable xdebug
moodle-docker-compose restart webserver
```

While setting these XDebug settings depending on your local need, please take special care of the value of `xdebug.client_host` which is needed to connect from the container to the host. The given value `host.docker.internal` is a special DNS name for this purpose within Docker for Windows and Docker for Mac. If you are running on another Docker environment, you might want to try the value `localhost` instead or even set the hostname/IP of the host directly.

After these commands, XDebug ist enabled and ready to be used in the webserver container.
If you want to disable and re-enable XDebug during the lifetime of the webserver container, you can achieve this with these additional commands:

```
# Disable XDebug extension in Apache and restart the webserver container
moodle-docker-compose exec webserver sed -i 's/^zend_extension=/; zend_extension=/' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
moodle-docker-compose restart webserver

# Enable XDebug extension in Apache and restart the webserver container
moodle-docker-compose exec webserver sed -i 's/^; zend_extension=/zend_extension=/' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
moodle-docker-compose restart webserver
```

## Advanced usage

As can be seen in [bin/moodle-docker-compose](https://github.com/moodlehq/moodle-docker/blob/master/bin/moodle-docker-compose),
this repo is just a series of docker-compose configurations and light wrapper which make use of companion docker images. Each part
is designed to be reusable and you are encouraged to use the docker[-compose] commands as needed.

## Companion docker images

The following Moodle customised docker images are close companions of this project:

* [moodle-php-apache](https://github.com/moodlehq/moodle-php-apache): Apache/PHP Environment preconfigured for all Moodle environments
* [moodle-db-mssql](https://github.com/moodlehq/moodle-db-mssql): Microsoft SQL Server for Linux configured for Moodle
* [moodle-db-oracle](https://github.com/moodlehq/moodle-db-oracle): Oracle XE configured for Moodle

## Contributions

Are extremely welcome!
