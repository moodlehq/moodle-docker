#!/bin/bash

adminer_plugins () {
     # Add in Adminer plugins
    docker cp assets/adminer/plugins/readable-dates.php docker-Adminer:/var/www/html/plugins/readable-dates.php
    docker cp assets/adminer/plugins/table-header-scroll.php docker-Adminer:/var/www/html/plugins/table-header-scroll.php
    docker cp assets/adminer/plugins/pretty-json-column.php docker-Adminer:/var/www/html/plugins/pretty-json-column.php
    docker cp assets/adminer/plugins/002-readable-dates.php docker-Adminer:/var/www/html/plugins-enabled/002-readable-dates.php
    docker cp assets/adminer/plugins/003-table-header-scroll.php docker-Adminer:/var/www/html/plugins-enabled/003-table-header-scroll.php
    docker cp assets/adminer/plugins/004-pretty-json-column.php docker-Adminer:/var/www/html/plugins-enabled/004-pretty-json-column.php
}

error_message() {
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo
    echo "${RED}$1${NC}"
    echo
}

help_messages () {
    echo
    echo "Script that automates managing docker."
    echo
    echo "Usage: sh k1run.sh [folder] [option] [option2]"
    echo
    echo "If no parameter is passed then display this help message."
    echo
    echo "--build    Start the site and initialize the site."
    echo "--build --phpunit|--behat Start the containers, install Moodle then initialize Behat or PHPUnit"
    echo "--down     Stop the site. Keep data"
    echo "--destroy  Stop the site, destory data"
    echo "--reboot   Restart the site - destroy all containers and re-initialize"
    echo "--load     Reload the site, use existing data"
    echo "--phpunit  Initialize for phpunit tests"
    echo "--behat    Initialize for behat tests"
}

exists_in_list() {
    LIST=$1
    DELIMITER=$2
    VALUE=$3
    LIST_WHITESPACES=`echo $LIST | tr "$DELIMITER" " "`
    for x in $LIST_WHITESPACES; do
        if [ "$x" = "$VALUE" ]; then
            return 1
        fi
    done
    return 0
}

if [ $# -eq 0 ];  then
    help_messages
    exit 1
fi

#Count the variables passed in.
variablecount=$#
if [ $# -lt 1 ] || [ $# -gt 3 ] ;  then
    error_message "Invalid number of arguments passed in. Must be between 1 and 3 arguments"
    help_messages
    exit 1
fi

cwd=$( dirname "$PWD" )

folder="${1}"

folder="${cwd}/${folder}"
if [ ! -d "${folder}" ]; then
   error_message "${folder} is not valid"
   help_messages
   exit 1
fi

SWITCH=$2
SWITCH2=$3

# Variables
# MOODLE_DOCKER_DB - database used by Moodle - default maria db.
# MOODLE_DOCKER_WWWROOT - folder where the Moodle code is located;
# MOODLE_DOCKER_PHP_VERSION - version of PHP used by Moodle. Default 8.1.

if [ "$SWITCH" = "--help" ]; then
    help_messages
    exit 1
fi

list_of_options="--build --down --destroy --reboot --load --phpunit --behat"

if  exists_in_list "$list_of_options" " " $SWITCH;  then
    error_message "Invalid option $SWITCH"
    help_messages
    exit 1
fi

if [ "$variablecount" -eq 3 ]; then
    if  exists_in_list "$list_of_options" " " $SWITCH2;  then
        error_message "Invalid option $SWITCH2"
        help_messages
        exit 1
    fi
fi

# Always use mariadb as a database.
export MOODLE_DOCKER_DB=mariadb
export MOODLE_DOCKER_WWWROOT=${folder}

# Check the Moodle version. If its 4.5 then set php version to 8.3
moodlever=$(grep "$branch   = '405';" $folder/version.php)
if [ "$moodlever" ]; then
   export MOODLE_DOCKER_PHP_VERSION=8.3
fi

# Use the local.yml_single for one site - includes adminer.
cp local.yml_single local.yml
cp config.docker-template.php $MOODLE_DOCKER_WWWROOT/config.php

# Build
if [ "$SWITCH" = "--build" ]; then
    # Check to see if the docker containers are running.
    if [ -n "$(docker ps -f "name=docker-webserver-1" -f "status=running" -q )" ]; then
       error_message "The Webserver is already running!. It cannot be re-initialized."
       help_messages
       exit 1
    fi
    # Start up containers
    bin/moodle-docker-compose up -d
    # Wait for DB to come up
    bin/moodle-docker-wait-for-db
    # Initialize the database
    bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="K1MOODLE" --shortname="K1MOODLE" --summary="K1 Moodle dev" --adminpass="test" --adminemail="admin@example.com"
    if [ "$SWITCH2" = "--phpunit" ]; then
       # Add in unit tests initialization.
       bin/moodle-docker-compose exec webserver php admin/tool/phpunit/cli/init.php
    fi
    if [ "$SWITCH2" = "--behat" ]; then
       # Add in unit tests initialization.
       bin/moodle-docker-compose exec webserver php admin/tool/behat/init.php
    fi
    adminer_plugins
fi

# DESTROY
if [ "$SWITCH" = "--destroy" ]; then
    if ! docker ps | grep -q 'moodlehq'; then
        error_message "No containers running. Nothing to shutdown"
        exit 1
    fi
    bin/moodle-docker-compose down
fi

# PNPUNIT ONLY
if [ "$SWITCH" = "--phpunit" ]; then
    # Only start the containers if they are not running.
    if ! docker ps | grep -q 'moodlehq'; then
        # Start up containers
        bin/moodle-docker-compose up -d
        # Wait for DB to come up
        bin/moodle-docker-wait-for-db
    fi
    bin/moodle-docker-compose exec webserver php admin/tool/phpunit/cli/init.php
    adminer_plugins
fi

# BEHAT ONLY
if [ "$SWITCH" = "--behat" ]; then
   # Start up containers
   bin/moodle-docker-compose up -d
   # Wait for DB to come up
   bin/moodle-docker-wait-for-db
   bin/moodle-docker-compose exec webserver php admin/tool/behat/cli/init.php
fi

# REBOOT
if [ "$SWITCH" = "--reboot" ]; then
    # Stop the containers
    if ! docker ps | grep -q 'moodlehq'; then
        error_message "No containers running. Nothing to reboot"
        exit 1
    fi
    bin/moodle-docker-compose stop
    sleep 3
    # Re-start up containers
    bin/moodle-docker-compose start
fi

# DOWN
if [ "$SWITCH" = "--down" ]; then
    # Check to see if containers are running.
    if ! docker ps | grep -q 'moodlehq'; then
        error_message "No containers running. Nothing to shutdown"
        exit 1
    fi
    # Stop the containers
    bin/moodle-docker-compose stop
fi

# LOAD existing data.
if [ "$SWITCH" = "--load" ]; then
    # Start the containers
    bin/moodle-docker-compose start
    adminer_plugins
fi

exit 0
