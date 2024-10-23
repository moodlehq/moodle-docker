#!/bin/bash

help_messages () {
    echo "Usage: sh k1many.sh [option] [folder1] [folder2] [folder2]"
    echo "Script that can start multiple sites."
    echo
    echo "--build       Start the site and initialize the sites."
    echo "--destroy     Stop the sites. Destroy all data"
    echo "--help        display this message"
    echo "--restart     Restart all running sites."
    echo "--start       Start all stopped sites."
    echo "--stop        Stop all running sites."

    echo "{folder1}     -folder pointing to first Moodle site (Mandatory)"
    echo "{folder2}     -folder pointing to second Moodle site (optional)"
    echo "{folder3}     -folder pointing to third Moodle site (optional)"
    echo "
        Examples:
            sh k1many.sh --build M405            # Start a site with the folder in docker/M405 folder
            sh k1many.sh --build M405 M401 MT    # Start three sites with based in docker/M405, docker/M401, docker/MT
            sh k1many.sh --start                 # Start all stopped sites
            sh k1many.sh --stop                  # Stop all stopped sites
            sh k1many.sh --destroy               # Stop and destroy sites
        "
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

SWITCH=$1

if [ "$SWITCH" = "--destroy" ]; then
   # Stop containers.
   docker stop $(docker ps -a -q)
   # Remove all containers.
   docker rm $(docker ps -a -q)
   echo "All sites shutdown and destroyed"
   return
fi

if [ "$SWITCH" = "--help" ]; then
    help_messages
    return
fi

if [ $# -lt 1 ] || [ $# -gt 4 ] ;  then
    echo "Invalid number of arguments passed in. Must be between 1 and 4 arguments"
    help_messages
    return
fi

# Check to see if the options are valid.
list_of_options="--build --down --destroy --reboot --load --stop --start --restart"

if  exists_in_list "$list_of_options" " " $SWITCH;  then
    echo "Invalid option $SWITCH"
    help_messages
    return
fi

# Count the variables passed in.
variablecount=$#

cwd=$( dirname "$PWD" )

# Check to be sure that all folders are valid.
folder1="${2}"
folder1="${cwd}/${folder1}"
if [ ! -d "${folder1}" ]; then
   echo "${folder1} is not valid"
   return
fi

if [ "$variablecount" -gt 2 ]; then
   folder2="${3}"
   folder2="${cwd}/${folder2}"
   if [ ! -d "${folder2}" ]; then
      echo "${folder2} is not valid"
      return
   fi
   if [ "$variablecount" -gt 3 ]; then
      folder3="${4}"
      folder3="${cwd}/${folder3}"
      if [ ! -d "${folder3}" ]; then
        echo "${folder3} is not valid"
        return
      fi
    fi
fi

# Variables
# MOODLE_DOCKER_DB          - database used by Moodle - default maria db
# MOODLE_DOCKER_WWWROOT     - folder where the Moodle code is located;
# MOODLE_DOCKER_PORT        - port (default 8000);
# MOODLE_DOCKER_PHP_VERSION - php version used in Moodle - default 8.1;
# COMPOSE_PROJECT_NAME      - Docker project name - used to identify sites;

# Always use mariadb as a database.

export MOODLE_DOCKER_DB=mariadb
export MOODLE_DOCKER_WWWROOT=${folder1}
export COMPOSE_PROJECT_NAME=site1

# Use the local.yml for multiple sites.
cp local.yml_many local.yml

# Build
if [ "$SWITCH" = "--build" ]; then
    if [ -n "$(docker ps -f "name=site1-webserver-1" -f "status=running" -q )" ]; then
        echo "The first site is already running!. It cannot be re-initialized."
        return;
    fi
    # Check the Moodle version. If its 4.5 then set php version to 8.3
    export MOODLE_DOCKER_PHP_VERSION=8.1
    moodlever=$(grep "$branch   = '405';" $folder1/version.php)
    if [ "$moodlever" ]; then
       export MOODLE_DOCKER_PHP_VERSION=8.3
    fi
    cp config.docker-template.php $MOODLE_DOCKER_WWWROOT/config.php
    # Start up containers
    bin/moodle-docker-compose up -d
    # Wait for DB to come up
    bin/moodle-docker-wait-for-db
    # Initialize the database
    bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="site1" --shortname="site1" --summary="Site 1" --adminpass="test" --adminemail="admin@example.com"
    echo "${folder1} site started - port 8000"

    if [ "$variablecount" -gt 2 ]; then
        # Check to see if the docker containers are running.
        export MOODLE_DOCKER_PHP_VERSION=8.1
        moodlever=$(grep "$branch   = '405';" $folder2/version.php)
        if [ "$moodlever" ]; then
           export MOODLE_DOCKER_PHP_VERSION=8.3
        fi
        export MOODLE_DOCKER_WEB_PORT=1234
        export MOODLE_DOCKER_WWWROOT=${folder2}
        export COMPOSE_PROJECT_NAME=site2
        cp config.docker-template.php $MOODLE_DOCKER_WWWROOT/config.php
        # Start up containers
        bin/moodle-docker-compose up -d
        # Wait for DB to come up
        bin/moodle-docker-wait-for-db
        # Initialize the database
        bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="site2" --shortname="site2" --summary="Site 2" --adminpass="test" --adminemail="admin@example.com"
        echo "${folder2} site started - port 1234"

        if [ "$variablecount" -gt 3 ]; then
            export MOODLE_DOCKER_PHP_VERSION=8.1
            moodlever=$(grep "$branch   = '405';" $folder3/version.php)
            if [ "$moodlever" ]; then
               export MOODLE_DOCKER_PHP_VERSION=8.3
            fi
            export MOODLE_DOCKER_WEB_PORT=6789
            export MOODLE_DOCKER_WWWROOT=${folder3}
            export COMPOSE_PROJECT_NAME=site3
            cp config.docker-template.php $MOODLE_DOCKER_WWWROOT/config.php
            # Start up containers
            bin/moodle-docker-compose up -d
            # Wait for DB to come up
            bin/moodle-docker-wait-for-db
            # Initialize the database
            bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="site3" --shortname="site3" --summary="Site 3" --adminpass="test" --adminemail="admin@example.com"
            echo "${folder3} site started - port 6789"
        fi
    fi
fi

# Restart
if [ "$SWITCH" = "--restart" ]; then
    if ! docker ps | grep -q 'moodlehq'; then
        echo "No containers running. Nothing to reboot"
        exit 1
    fi
    docker restart $(docker ps -q)
    echo "All sites restarted"
fi

# Start
if [ "$SWITCH" = "--start" ]; then
    if [ -n "$(docker ps -f "name=site1-webserver-1" -f "status=running" -q )" ]; then
        echo "Sites are already running."
        return;
    fi
    docker start $(docker ps -a -q -f status=exited)
    echo "All sites started"
fi

# Stop
if [ "$SWITCH" = "--stop" ]; then
    if ! docker ps | grep -q 'moodlehq'; then
        echo "No containers running. Nothing to stop"
        exit 1
    fi
    docker stop $(docker ps -q)
    echo "All sites stopped"
fi

return
