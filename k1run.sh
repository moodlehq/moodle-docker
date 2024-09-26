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

help_messages () {
    echo "Usage: sh k1run.sh [folder] [option] [option2]"
    echo "Script that automate managing docker."
    echo
    echo "If no parameter is passed then boot and initialize the site."
    echo
    echo "--build    Start the site and initialize the site."
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
    echo "No arguments supplied"
    help_messages
    return
fi
#Count the variables passed in.
variablecount=$#
if [ $# -lt 2 ] || [ $# -gt 3 ] ;  then
    echo "Invalid number of arguments passed in. Must be between 2 and 3 arguments"
    help_messages
    return
fi

cwd=$( dirname "$PWD" )

folder="${1}"

folder="${cwd}/${folder}"
if [ ! -d "${folder}" ]; then
   echo "${folder} is not valid"
   return
fi

SWITCH=$2
SWITCH2=$3

# Variables
# MOODLE_DOCKER_DB - database used by Moodle - default maria db
# MOODLE_DOCKER_WWWROOT - folder where the Moodle code is located;

if [ "$SWITCH" = "--help" ]; then
    help_messages
fi

# Check to see if the options are valied.

list_of_options="--build --down --destroy --reboot --load --phpunit --behat"

if  exists_in_list "$list_of_options" " " $SWITCH;  then
    echo "Invalid option $SWITCH"
    help_messages
    return
fi

if [ "$variablecount" -eq 3 ]; then 
    if  exists_in_list "$list_of_options" " " $SWITCH2;  then
        echo "Invalid option $SWITCH2"
        help_messages
        return
    fi
fi

# Always use mariadb as a database.

export MOODLE_DOCKER_DB=mariadb
export MOODLE_DOCKER_WWWROOT=${folder}
#export MOODLE_DOCKER_PHP_VERSION=8.3

# Use the local.yml_single for one site - includes adminer..
cp local.yml_single local.yml
cp config.docker-template.php $MOODLE_DOCKER_WWWROOT/config.php

# Build
if [ "$SWITCH" = "--build" ]; then
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
    bin/moodle-docker-compose down
fi

# PNPUNIT ONLY
if [ "$SWITCH" = "--phpunit" ]; then
   # Start up containers
   bin/moodle-docker-compose up -d
   # Wait for DB to come up 
   bin/moodle-docker-wait-for-db
   bin/moodle-docker-compose exec webserver php admin/tool/phpunit/cli/init.php
   adminer_plugins    
fi

# PNPUNIT ONLY
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
    bin/moodle-docker-compose down
    sleep 3
    # Start up containers
    bin/moodle-docker-compose up -d
    bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="K1MOODLE" --shortname="K1MOODLE" --summary="K1 Moodle dev" --adminpass="test" --adminemail="admin@example.com"
fi

# PHPUNIT
if [ "$SWITCH" = "--phpunit" ]; then
    # Add in unit tests initialization.
    bin/moodle-docker-compose exec webserver php admin/tool/phpunit/cli/init.php
    adminer_plugins   
fi

# BEHAT
if [ "$SWITCH" = "--behat" ]; then
    # Add in unit tests initialization.
    bin/moodle-docker-compose exec webserver php admin/tool/behat/init.php
fi

# DOWN
if [ "$SWITCH" = "--down" ]; then
    # Stop the containers 
    bin/moodle-docker-compose stop
fi

# DOWN
if [ "$SWITCH" = "--load" ]; then
    # Start the containers 
    bin/moodle-docker-compose start
    adminer_plugins   
fi

return
