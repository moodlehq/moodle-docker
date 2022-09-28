# moodle-docker: Docker Containers for Moodle Developers
[![Build Status](https://github.com/moodlehq/moodle-docker/workflows/moodle-docker%20CI/badge.svg?branch=master)](https://github.com/moodlehq/moodle-docker/actions/workflows/ci.yml?query=branch%3Amaster)

This repository contains Docker configuration aimed at Moodle developers and testers to easily deploy a development or testing environment for Moodle.

## Features:
* All supported database servers (PostgreSQL, MySQL, Microsoft SQL Server, Oracle XE)
* Behat/Selenium configuration for Firefox and Chrome
* Catch-all smtp server and web interface to messages using [MailHog](https://github.com/mailhog/MailHog/)
* All PHP Extensions enabled configured for external services (e.g. solr, ldap)
* All supported PHP versions
* Zero-configuration approach
* Full support for macOS with Apple M1/M2 CPU
* Backed by [automated tests](https://travis-ci.com/moodlehq/moodle-docker/branches)

## Prerequisites
* [Docker](https://docs.docker.com) and [Docker Compose](https://docs.docker.com/compose/cli-command/#installing-compose-v2) installed if your Docker CLI version does not support `docker compose` command.
* 3.25GB of RAM (if you choose [Microsoft SQL Server](https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup#prerequisites) as db server)

## Quick start

1. Open terminal and cd to your projects directory
2. Clone __moodle-docker__ repository `git clone git@github.com:moodlehq/moodle-docker.git`
3. Clone __moodle__ repository `git clone git@github.com:moodle/moodle.git`
4. Delete your standard moodle/config.php file if present.
5. Create __moodle-docker.env__ file with the following content in your moodle directory
   (or you can copy _moodle-docker/templates/moodle-docker.env_ to moodle directory as a starting point):
```
# Specifies database type
MOODLE_DOCKER_DB=pgsql
```
6. Open terminal, cd to your moodle directory and execute `bin/docker_up` script:
```bash
cd /path/to/moodle
../moodle-docker/bin/docker_up
```
7. Now you can complete the test site installation at [http://localhost:8000/](http://localhost:8000/).
8. Alternatively you can complete the test site installation from CLI:
```bash
cd /path/to/moodle
../moodle-docker/bin/init_site --agree-license --adminpass="test"
```
9. You can view emails which Moodle has sent out at [http://localhost:8000/_/mail](http://localhost:8000/_/mail).
10. Optionally you can add emulated php script to your project to simplify execution of php scripts from CLI:
```bash
cd /path/to/moodle
cp ../moodle-docker/templates/php ./
./php --version
```
11. When you are finished with testing you can delete the instances using `bin/docker_down` script:
```bash
cd /path/to/moodle
../moodle-docker/bin/docker_down
```

## Run several Moodle instances

By default, docker compose uses current directory name as project name,
which means that you do not have to add COMPOSE_PROJECT_NAME to
__moodle-docker.env__ file when it is inside your moodle code directory.

However, you need to specify unique ports of each service that is exposed.
For example, you could add following to __moodle-docker.env__ file
prior to running `bin/docker_up` script where ports are incremented by one
for each of your moodle checkout directories.

First Moodle project:
```
# Specifies database type
MOODLE_DOCKER_DB=pgsql

# Use a uniquie local web port
MOODLE_DOCKER_WEB_PORT=8001

# Use a uniquie local VNC port
MOODLE_DOCKER_SELENIUM_VNC_PORT=5901

# Use a uniquie local database port
MOODLE_DOCKER_DB_PORT=5401
```

Second Moodle project:
```
# Specifies database type
MOODLE_DOCKER_DB=pgsql

# Use a uniquie local web port
MOODLE_DOCKER_WEB_PORT=8002

# Use a uniquie local VNC port
MOODLE_DOCKER_SELENIUM_VNC_PORT=5902

# Use a uniquie local database port
MOODLE_DOCKER_DB_PORT=5402
```

If you want to run multiple docker compose instances for one moodle project directory,
then you can create separate directories with __moodle-docker.env__ files that contain
explicit __MOODLE_DOCKER_WWWROOT__ and __COMPOSE_PROJECT_NAME__ values.
Alternatively you can export environment settings instead of the environment file.

## Use docker for running PHPUnit tests

To initialise the PHPUnit test environment execute `bin/init_behat` script:

```bash
cd /path/with/moodle-docker.env/
../moodle-docker/bin/init_phpunit
```

To run PHPUnit tests execute `bin/phpunit` script, for example:

```bash
cd /path/with/moodle-docker.env/
../moodle-docker/bin/phpunit --filter=auth_manual
```

You should see something like this:
```
Moodle 4.0.4+ (Build: 20220922), d708740c3fdb953a6dbb8dd2b3068de9d23a3d27
Php: 7.4.30, pgsql: 12.12 (Debian 12.12-1.pgdg110+1), OS: Linux 5.10.124-linuxkit aarch64
PHPUnit 9.5.13 by Sebastian Bergmann and contributors.

.....                                                               5 / 5 (100%)

Time: 00:00.627, Memory: 290.00 MB

OK (5 tests, 17 assertions)
```

Notes:
* If you want to run tests with code coverage reports:
```bash
cd /path/with/moodle-docker.env/
# Build component configuration
../moodle-docker/bin/util_phpunit --buildcomponentconfigs
# Execute tests for component
../moodle-docker/bin/moodle-docker-compose exec webserver php -d pcov.enabled=1 -d pcov.directory=. vendor/bin/phpunit --configuration reportbuilder --coverage-text
```
* See available [Command-Line Options](https://phpunit.readthedocs.io/en/9.5/textui.html#textui-clioptions) for further info

## Use docker for running Behat tests

To initialise the Behat test environment execute `bin/init_behat` script: 

```bash
cd /path/with/moodle-docker.env/
../moodle-docker/bin/init_behat
```

To run Behat tests execute `bin/behat` script, for example:

```bash
cd /path/with/moodle-docker.env/
../moodle-docker/bin/behat --tags=@auth_manual
```

You should see something like this:
```
Moodle 4.0.4+ (Build: 20220922), d708740c3fdb953a6dbb8dd2b3068de9d23a3d27
Php: 7.4.30, pgsql: 12.12 (Debian 12.12-1.pgdg110+1), OS: Linux 5.10.124-linuxkit aarch64
Run optional tests:
- Accessibility: No
Server OS "Linux", Browser: "firefox"
Started at 29-09-2022, 00:58
...............

2 scenarios (2 passed)
15 steps (15 passed)
0m42.66s (51.78Mb)
```

Notes:

* The behat faildump directory is exposed at http://localhost:8000/_/faildumps/.
* Use `MOODLE_DOCKER_BROWSER` to switch the browser you want to run the test against.
  You need to recreate your containers using `bin/docker_rebuild`,
  if you make any changes in __moodle-docker.env__ file.

### Using VNC to view Behat tests

If you want to observe the execution of scenarios in a web browser then
add the following lines into you __moodle-docker.env__ file before executing `bin/docker_up`:

```
# Instruct selenium to expose a VNC session on this port
MOODLE_DOCKER_SELENIUM_VNC_PORT=5900
```

You should be able to use any kind of VNC viewer, such as [Real VNC Viewer](https://www.realvnc.com/en/connect/download/viewer/)
or standard macOS application _Screen Sharing_.

With the containers running, enter 0.0.0.0:5900 as the port in VNC Viewer or type [vnc://127.0.0.1:5900](vnc://127.0.0.1:5900) address
in _Screen Sharing_ application. You will be prompted for a password, the password is 'secret'.

You should be able to see an empty Desktop. When you run any Behat tests with @javascript tag
a browser will pop up, and you will see the tests execute.

### Use containers for running behat tests for the Moodle App

In order to run Behat tests for the Moodle App, you need to install the [local_moodlemobileapp](https://github.com/moodlehq/moodle-local_moodlemobileapp) plugin in your Moodle site. Everything else should be the same as running standard Behat tests for Moodle. Make sure to filter tests using the `@app` tag.

The Behat tests will be run against a container serving the mobile application, you have two options here:

1. Use a Docker image that includes the application code. You need to specify the `MOODLE_DOCKER_APP_VERSION` env variable and the [moodlehq/moodleapp](https://hub.docker.com/r/moodlehq/moodleapp) image will be downloaded from Docker Hub. You can read about the available images in [Moodle App Docker Images](https://docs.moodle.org/dev/Moodle_App_Docker_Images) (for Behat, you'll want to run the ones with the `-test` suffix).

2. Use a local copy of the application code and serve it through Docker, similar to how the Moodle site is being served. Set the `MOODLE_DOCKER_APP_PATH` env variable to the codebase in you file system. This will assume that you've already initialized the app calling `npm install` and `npm run setup` locally.

For both options, you also need to set `MOODLE_DOCKER_BROWSER` to "chrome".

```bash
# Install local_moodlemobileapp plugin
cd /path/to/moodle
git clone https://github.com/moodlehq/moodle-local_moodlemobileapp local/moodlemobileapp

# Initialize behat environment
cd /path/with/moodle-docker.env/
../moodle-docker/bin/init_behat
# (you should see "Configured app tests for version X.X.X" here)

# Run behat tests
../moodle-docker/bin/behat --tags="@app&&@mod_login"
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

If you are going with the second option, this *can* be used for local development of the Moodle App, given that the `moodleapp` container serves the app on the local 8100 port. However, this is intended to run Behat tests that require interacting with a local Moodle environment. Normal development should be easier calling `npm start` in the host system.

By all means, if you don't want to have npm installed locally you can go full Docker executing the following commands before starting the containers:

```
docker run --volume $MOODLE_DOCKER_APP_PATH:/app --workdir /app bash -c "npm install npm@7 -g && npm ci"
```

You can learn more about writing tests for the app in [Acceptance testing for the Moodle App](https://docs.moodle.org/dev/Acceptance_testing_for_the_Moodle_App).

## Use docker to run grunt

First you need to install appropriate node and npm version in webserver container, for example:

```bash
cd /path/with/moodle-docker.env/
../moodle-docker/bin/init_node 16
```

To run grunt use:

```bash
cd /path/with/moodle-docker.env/
../moodle-docker/bin/grunt
```

Note: some node modules may not be still compatible with Apple M1/M2 processors. To work around it,
you may try to use `MOODLE_DOCKER_WEB_PLATFORM=linux/amd64` environment setting.

## Stop and restart containers

`bin/docker_down` which was used above after using the containers stops and destroys the containers.
If you want to use your containers continuously for manual testing or development without starting them up
from scratch everytime you use them, you can also just stop without destroying them.
With this approach, you can restart your containers sometime later,
they will keep their data and won't be destroyed completely until you run `bin/docker_down`.

```bash
cd /path/with/moodle-docker.env/

# Stop containers
../moodle-docker/bin/docker_stop

# Restart containers
../moodle-docker/bin/docker_start
```

It is also possible to use Dashboard in Docker Desktop to stop, start or delete the instances. 

## Environment variables file _./moodle-docker.env_

You can change the configuration of the docker images by setting various environment variables in __moodle-docker.env__ file.
This file is usually placed in your Moodle code directory, however it can be placed in any directory because the bin
scripts are looking for it in the current working directory when executed.

Changes in the environment file should be done **before** calling `bin/docker_up`. If your containers are running
first call `bin/docker_down`, then update the environment file and finally start the containers again.

| Environment Variable                      | Mandatory | Allowed values                        | Default value | Notes                                                                        |
|-------------------------------------------|-----------|---------------------------------------|---------------|------------------------------------------------------------------------------|
| `MOODLE_DOCKER_DB`                        | yes       | pgsql, mariadb, mysql, mssql, oracle  | none          | The database server to run against                                           |
| `MOODLE_DOCKER_WWWROOT`                   | no        | path on your file system              | current directory if ./_moodle-docker.env_ file exists | The path to the Moodle codebase you intend to test. |
| `MOODLE_DOCKER_DB_VERSION`                | no        | image version, for example: 5.7, 8.0 (mysql); 12, 13 (pgsql); 10.7, 10.8 (mariadb) | 5.7 (mysql); 12 (pgsql); 10.7 (mariadb) | The database server version |
| `MOODLE_DOCKER_PHP_VERSION`               | no        | 8.0, 7.4, 7.3, 7.2, 7.1, 7.0, 5.6     | 7.4           | The php version to use                                                       |
| `MOODLE_DOCKER_BROWSER`                   | no        | firefox, chrome,  firefox:&lt;tag&gt;, chrome:&lt;tag&gt; | firefox:3       | The browser to run Behat against. Supports a colon notation to specify a specific Selenium docker image version to use. e.g. firefox:2.53.1 can be used to run with older versions of Moodle (<3.5)              |
| `MOODLE_DOCKER_PHPUNIT_EXTERNAL_SERVICES` | no        | any value                             | not set       | If set, dependencies for memcached, redis, solr, and openldap are added      |
| `MOODLE_DOCKER_BEHAT_FAILDUMP`            | no        | Path on your file system              | not set       | Behat faildumps are already available at http://localhost:8000/_/faildumps/ by default, this allows for mapping a specific filesystem folder to retrieve the faildumps in bulk / automated ways |
| `MOODLE_DOCKER_DB_PORT`                   | no        | any integer value                     | none          | If you want to bind to any host IP different from the default 127.0.0.1, you can specify it with the bind_ip:port format (0.0.0.0 means bind to all). Username is "moodle" (or "sa" for mssql) and password is "m@0dl3ing". |
| `MOODLE_DOCKER_WEB_HOST`                  | no        | any valid hostname                    | localhost     | The hostname for web                                |
| `MOODLE_DOCKER_WEB_PORT`                  | no        | any integer value (or bind_ip:integer)| 127.0.0.1:8000| The port number for web. If set to 0, no port is used.<br/>If you want to bind to any host IP different from the default 127.0.0.1, you can specify it with the bind_ip:port format (0.0.0.0 means bind to all) |
| `MOODLE_DOCKER_WEB_PLATFORM`              | no        | linux/amd64                           | none          | Experimental setting for Apple M1/M2 CPUs                                    |
| `MOODLE_DOCKER_DB_PLATFORM`               | no        | linux/amd64                           | none          | Experimental setting for Apple M1/M2 CPUs                                    |
| `MOODLE_DOCKER_SELENIUM_VNC_PORT`         | no        | any integer value (or bind_ip:integer)| not set       | If set, the selenium node will expose a vnc session on the port specified. Similar to MOODLE_DOCKER_WEB_PORT, you can optionally define the host IP to bind to. If you just set the port, VNC binds to 127.0.0.1 |
| `MOODLE_DOCKER_APP_PATH`                  | no        | path on your file system              | not set       | If set and the chrome browser is selected, it will start an instance of the Moodle app from your local codebase |
| `MOODLE_DOCKER_APP_VERSION`               | no        | a valid [app docker image version](https://docs.moodle.org/dev/Moodle_App_Docker_images) | not set       | If set will start an instance of the Moodle app if the chrome browser is selected |
| `MOODLE_DOCKER_APP_RUNTIME`               | no        | 'ionic3' or 'ionic5'                  | not set       | Set this to indicate the runtime being used in the Moodle app. In most cases, this can be ignored because the runtime is guessed automatically (except on Windows using the `.cmd` binary). In case you need to set it manually and you're not sure which one it is, versions 3.9.5 and later should be using Ionic 5. |

For backwards compatibility it is also possible to use environment variables instead of the environment file,
for example:

```bash
    cd /path/to/moodle-docker
    export MOODLE_DOCKER_WWWROOT=/path/to/moodle
    export MOODLE_DOCKER_DB=pgsql
    ./bin/moodle-docker-compose up -d
```

## Extra compose configuration file _./moodle-docker.yml_

Instead of environmental variables it is also possible to supply extra compose configuration file.

For example if you want to use private git repositories from containers you can to add SSH keys
by creating __moodle-docker.yml__ file in current directory:

```yml
services:
  webserver:
    volumes:
    - /path/to/docker/ssh/id_ed25519:/root/.ssh/id_ed25519:ro
    - /path/to/docker/ssh/id_ed25519.pub:/root/.ssh/id_ed25519.pub:ro
```

Another example override when you want to run `MOODLE_DOCKER_PHP_VERSION=5.6` with `MOODLE_DOCKER_DB=mssql`:

```yml
services:
  webserver:
    environment:
      MOODLE_DOCKER_DBTYPE: mssql
```

Changes in the configuration file should be done **before** calling `bin/docker_up`. If your containers are running
first call `bin/docker_down`, then update the configuration file and finally start the containers again.

## Using XDebug for live debugging

The XDebug PHP Extension is not included in this setup and there are reasons not to include it by default.

However, if you want to work with XDebug, especially for live debugging, you can add XDebug to a running webserver container easily:

```bash
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

```bash
# Disable XDebug extension in Apache and restart the webserver container
moodle-docker-compose exec webserver sed -i 's/^zend_extension=/; zend_extension=/' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
moodle-docker-compose restart webserver

# Enable XDebug extension in Apache and restart the webserver container
moodle-docker-compose exec webserver sed -i 's/^; zend_extension=/zend_extension=/' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
moodle-docker-compose restart webserver
```

## Advanced usage

As can be seen in [bin/moodle-docker-compose](https://github.com/moodlehq/moodle-docker/blob/master/bin/moodle-docker-compose),
this repo is just a series of Docker Compose configurations and light wrapper which make use of companion docker images. Each part
is designed to be reusable and you are encouraged to use the docker [compose] commands as needed.

## Companion docker images

The following Moodle customised docker images are close companions of this project:

* [moodle-php-apache](https://github.com/moodlehq/moodle-php-apache): Apache/PHP Environment preconfigured for all Moodle environments
* [moodle-db-mssql](https://github.com/moodlehq/moodle-db-mssql): Microsoft SQL Server for Linux configured for Moodle
* [moodle-db-oracle](https://github.com/moodlehq/moodle-db-oracle): Oracle XE configured for Moodle

## PhpStorm configuration

PhpStorm can be configured to use moodle-docker directly which eliminates the need to install PHP binaries,
webserver or database.

There is also a simple _Docker manager_ in Services tab in PhpStorm which can be used to stop/start the containers. 

### Configure remote docker PHP CLI interpreter

First of all set up a moodle-docker instance - see Quick start section above.

Then open your Moodle project directory in PhpStorm and add a remote PHP CLI interpreter:

1. Open "Preferences / PHP"
2. Add new _CLI Interpreter_ by clicking "..."
3. Click "+" and select "From Docker, Vagrant, VM, WSL, remote..."
4. Select existing docker server or click "Docker compose" and press "New..."  in "Server:" field
5. Select __./moodle-docker-final.yml__ file in "Configuration files:" field
6. Select __webserver__ in "Service:" field
7. Press "OK"
8. Switch lifecycle to __Connect to existing container ('docker-compose exec')__
9. Press reload icon in "PHP executable:" field, PhpStorm should detect correct PHP binary
10. You should customise the interpreter name at the top and make it "Visible only for this project"
11. Press "OK" to save interpreter settings
12. Verify the new interpreter is selected in "CLI Interpreter:" field
13. Press "OK" to save PHP settings

### Configure remote PHPUnit interpreter

First make sure your docker compose instance is running and PHPUnit was initialised.
The remote PHP CLI interpreter must be already configured in your PhpStorm.

1. Open "Preferences / PHP / Test Frameworks"
2. Click "+" and select "PHPUnit by remote interpreter"
3. Select your docker interpreter that was created for this project and press "OK"
4. Verify "Path to script:" field is set to `/var/www/html/vendor/autoload.php`
5. Verify "Default configuration file:" field is enabled and set it to `/var/www/html/phpunit.xml`
6. Press "Apply" and verify correct PHPUnit version was detected
7. Press "OK"

You may want to delete all unused interpreters.
To execute PHPUnit tests open a testcase file and click on a green arrow gutter icon.

### Configure remote Behat interpreter

First make sure your docker compose project is running and Behat was initialised.
The remote PHP CLI interpreter must be already configured in your PhpStorm.

1. Open "Preferences / PHP / Test Frameworks"
2. Click "+" and select "Behat by remote interpreter"
3. Select your docker interpreter that was created for this project and press "OK"
4. Set "Path to Behat executable:" field to `/var/www/html/vendor/behat/behat/bin/behat`
5. Enable "Default configuration file:" field and se it to `/var/www/behatdata/behatrun/behat/behat.yml`
6. Press "Apply" and verify correct Behat version was detected - if not check the instance is running and Behat was initialised manually
7. Press "OK"

You may want to delete all unused interpreters.
To execute Behat tests open a feature file and click on a green arrow gutter icon.
If you have configured a VNC port then you can watch the scenario progress in your VPN client.

### Connect PhpStorm to docker database

In order to connect to database from your local computer you need to add `MOODLE_DOCKER_DB_PORT`
to your __moodle-docker.env__ file.

Make sure your docker compose project is running and test site was initialised.

Then setup new database connection in PhpStorm through the exposed port, for example:

1. Open "Database" tab in PhpStorm
2. Press "+" and select "Database source / PostgreSQL"
3. Set "User:" field to 'moodle'
4. Set "Password:" field to 'm@0dl3ing'
5. Set "Database:" field to 'moodle'
6. Set "Port:" field to MOODLE_DOCKER_DB_PORT value
7. Press "OK"
8. Refresh the database metadata
9. Open "Preferences / Language & Frameworks / SQL Dialects"
10. Set "Project SQL Dialect:" field to 'PostgreSQL'
11. Press "OK"
12. Copy __.phpstorm.meta.php__ file from `moodle-docker/templates/` directory into your Moodle project
13. You may need to use "File / Invalidate caches..." and restart the IDE

As a test open lib/accesslib.php and find some full SQL statement and verify the SQL syntax
is highlighted and SQL syntax errors are detected.

## Visual Studio Code configuration

1. Install _Docker_ extension from Microsoft
2. Add __moodle-docker.env__ to your Moodle project
3. Create docker instance with `../moodle-docker/bin/docker_up`
4. Copy `../moodle-docker/templates/php` to you Moodle project
5. Configure VSCode to use emulated _php_:
```json
{
    "php.validate.executablePath": "./php"
}
```

### Use _Better PHPUnit_ to run tests in VSCode

1. Initialise phpunit with `../moodle-docker/bin/phpunit_init`
2. Install _Better PHPUnit_ extension
3. Update VSCode configuration (note you need to edit project path):
```json
{
    "better-phpunit.docker.command": "docker compose -f moodle-docker-final.yml exec webserver",
    "better-phpunit.docker.enable": true,
    "better-phpunit.phpunitBinary": "vendor/bin/phpunit",
    "better-phpunit.docker.paths": {
        "/path/to/your/moodle": "/var/www/html"
    },
    "better-phpunit.xmlConfigFilepath": "/var/www/html/phpunit.xml"
}
```
4. Open a test file, go to method and press Cmd+shif+p and select one of _Better PHPUnit_ options to run tests.

## Contributions

Are extremely welcome!
