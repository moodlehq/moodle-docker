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
* 3.25GB of RAM (if you choose [Microsoft SQL Server](https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup#prerequisites) as db server)

## Quick start

1. Download or clone this repository
2. Rename `.env.example` to `.env`
3. Specify Moodle directory and db driver in `.env`
4. Run `bin/moodle-run` inside `moodle-docker` folder

You can now access Moodle under `localhost:8000`.

If you want to destroy the container, run `bin/moodle-docker-compose down`.


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

## Use containers for manual testing

```bash
# Initialize Moodle database for manual testing
bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="Docker moodle" --shortname="docker_moodle" --adminpass="test" --adminemail="admin@example.com"
```

Notes:
* Moodle is configured to listen on `http://localhost:8000/`.
* Mailhog is listening on `http://localhost:8000/_/mail` to view emails which Moodle has sent out.
* The admin `username` you need to use for logging in is `admin` by default. You can customize it by passing `--adminuser='myusername'`

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

## Environment variables

You can change the configuration of the docker images by setting various environment variables before calling `bin/moodle-docker-compose up`.

| Environment Variable                      | Mandatory | Allowed values                        | Default value | Notes                                                                        |
|-------------------------------------------|-----------|---------------------------------------|---------------|------------------------------------------------------------------------------|
| `MOODLE_DOCKER_DB`                        | yes       | pgsql, mariadb, mysql, mssql, oracle  | none          | The database server to run against                                           |
| `MOODLE_DOCKER_WWWROOT`                   | yes       | path on your file system              | none          | The path to the Moodle codebase you intend to test                           |
| `MOODLE_DOCKER_PHP_VERSION`               | no        | 7.4, 7.3, 7.2, 7.1, 7.0, 5.6          | 7.2           | The php version to use                                                       |
| `MOODLE_DOCKER_BROWSER`                   | no        | firefox, chrome                       | firefox       | The browser to run Behat against                                             |
| `MOODLE_DOCKER_PHPUNIT_EXTERNAL_SERVICES` | no        | any value                             | not set       | If set, dependencies for memcached, redis, solr, and openldap are added      |
| `MOODLE_DOCKER_WEB_HOST`                  | no        | any valid hostname                    | localhost     | The hostname for web                                |
| `MOODLE_DOCKER_WEB_PORT`                  | no        | any integer value (or bind_ip:integer)| 127.0.0.1:8000| The port number for web. If set to 0, no port is used.<br/>If you want to bind to any host IP different from the default 127.0.0.1, you can specify it with the bind_ip:port format (0.0.0.0 means bind to all) |
| `MOODLE_DOCKER_SELENIUM_VNC_PORT`         | no        | any integer value (or bind_ip:integer)| not set       | If set, the selenium node will expose a vnc session on the port specified. Similar to MOODLE_DOCKER_WEB_PORT, you can optionally define the host IP to bind to. If you just set the port, VNC binds to 127.0.0.1 |
| `MOODLE_APP_VERSION`                      | no        | next, latest, or an app version number| not set       | If set will start an instance of the Mmodle app if the chrome browser is selected |

## Using XDebug for live debugging

The XDebug PHP Extension is not included in this setup and there are reasons not to include it by default.

However, if you want to work with XDebug, especially for live debugging, you can add XDebug to a running webserver container easily:

```
# Install XDebug extension with PECL
moodle-docker-compose exec webserver pecl install xdebug

# Set some wise setting for live debugging - change this as needed
read -r -d '' conf <<'EOF'
; Settings for Xdebug Docker configuration
xdebug.coverage_enable = 0
xdebug.default_enable = 0
xdebug.cli_color = 2
xdebug.file_link_format = phpstorm://open?%f:%l
xdebug.idekey = PHPSTORM
xdebug.remote_enable = 1
xdebug.remote_autostart = 1
xdebug.remote_host = host.docker.internal
EOF
moodle-docker-compose exec webserver bash -c "echo '$conf' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"

# Enable XDebug extension in Apache
moodle-docker-compose exec webserver docker-php-ext-enable xdebug
```

While setting these XDebug settings depending on your local need, please take special care of the value of `xdebug.remote_host` which is needed to connect from the container to the host. The given value `host.docker.internal` is a special DNS name for this purpose within Docker for Windows and Docker for Mac. If you are running on another Docker environment, you might want to try the value `localhost` instead or even set the hostname/IP of the host directly.

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
