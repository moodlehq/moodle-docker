#!/bin/bash

thisfile=$( readlink "${BASH_SOURCE[0]}" ) || thisfile="${BASH_SOURCE[0]}"
basedir="$( cd "$( dirname "$thisfile" )/../" && pwd -P )"
#SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

SWITCH1=$1
SWITCH2=$2
SWITCH3=$3

echo "== K1Run =="
echo

# make sure that env MOODLE_DOCKER_WWWROOT is set.
if [[ -z "${MOODLE_DOCKER_WWWROOT}" ]]; then
    echo "Environment variable MOODLE_DOCKER_WWWROOT has not been set."
    echo "Please set it before proceeding # k1run.sh --root /var/www/html"
    echo "Exiting."
    exit 1
else
    echo "MOODLE_DOCKER_WWWROOT=$MOODLE_DOCKER_WWWROOT.  ✔"
fi

# check if MOODLE_DOCKER_DB is set.
if [[ -z "${MOODLE_DOCKER_DB}" ]]; then
    # Always use mariadb as a database.
    export MOODLE_DOCKER_DB=mariadb
    echo "Setting MOODLE_DOCKER_DB=${MOODLE_DOCKER_DB}.  ✔"
else
    echo "MOODLE_DOCKER_DB=${MOODLE_DOCKER_DB}.  ✔"
fi

echo "Script path= $basedir."
echo
echo "== == == == == == == == == == == =="
echo

# if no argument passed, defaults to --start
if [[ -z "${SWITCH1}" ]]; then
    echo "No argument(s) passed, defaulting to --start."
    SWITCH1="--start"
fi

# Help
if [ "$SWITCH1" = "--help" ]; then
    echo "Usage: sh run.sh --[command] [argument1] [argument2]"
    echo "Script that automates managing docker. See: https://jira.knowledgeone.ca:9443/x/3wCnCQ"
    echo "Command --root must be run first to set the Moodle path."
    echo
    echo "If no parameter is passed then boot and initialize the site."
    echo
    echo "--start    Boot and initialize the site. (default)"
    echo "--root     Pass absolute path to MOODLE_DOCKER_WWWROOT to set ENV variable."
    echo "--build    Start the site and initialize the site."
    echo "--initdb     Drop and re-initialize the Moodle database, with new credential."
    echo "             With two arguments: [email] [password]"
    echo "             With no arguments: admin@example.com m@0dl3ing (defaults)"
    echo "--reload   Reload the site, use existing data"
    echo "--down     Stop the site. Keep data"
    echo "--destroy  Stop the site, destory data"
    echo "--reboot   Restart the site - destroy all containers and re-initialize"
    echo "--php      Reload php config in assets/php/10-docker-php-moodle.ini"
    echo "--phpunit  Initialize for phpunit tests"
    echo "--behat    Initialize for behat tests"
    echo "--help     Print this message"

# Root
elif [ "$SWITCH1" = "--root" ]; then 
    echo "--root : Attempting to set Moodle root directory."
    if [[ -d "${SWITCH2}" ]]; then
        export MOODLE_DOCKER_WWWROOT=$SWITCH2
        echo "Set MOODLE_DOCKER_WWWROOT=${SWITCH2}"        
    else
        echo "This isn't a valid path: ${SWITCH2}. Exiting."
    fi

# Start
elif [ "$SWITCH1" = "--start" ]; then
    # ...
    ${basedir}/bin/moodle-docker-compose up -d

# Init
elif [ "$SWITCH1" = "--initdb" ]; then
    if [[ -z "${SWITCH2}" ]] || [[ -z "${SWITCH3}" ]] ; then
        # Defaults: admin@example.com m@0dl3ing
        ${basedir}/bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="moodle" --shortname="moodle" --summary="K1 Moodle dev" --adminpass="m@0dl3ing" --adminemail="admin@example.com"
        echo "Run install_database.php with default credentials: admin@example.com m@0dl3ing."
    else
        ${basedir}/bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="moodle" --shortname="moodle" --summary="K1 Moodle dev" --adminpass="${SWITCH2}" --adminemail="${SWITCH3}"
        echo "Run install_database.php with provided credentials."
    fi
    
# Build
elif [ "$SWITCH1" = "--build" ]; then
    # Start up containers
    ${basedir}/bin/moodle-docker-compose up -d
    # Wait for DB to come up
    ${basedir}/bin/moodle-docker-wait-for-db
    # Initialize the database
    ${basedir}/bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="K1MOODLE" --shortname="K1MOODLE" --summary="K1 Moodle dev" --adminpass="test" --adminemail="admin@example.com"

# Down
elif [ "$SWITCH1" = "--down" ]; then
    # Stop the containers
    ${basedir}/bin/moodle-docker-compose stop

# Reboot
elif [ "$SWITCH1" = "--reboot" ]; then
    # Stop the containers
    ${basedir}/bin/moodle-docker-compose down
    echo "Wait for it..."
    sleep 3
    # Start up containers
    ${basedir}/bin/moodle-docker-compose up -d
    ${basedir}/bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="K1MOODLE" --shortname="K1MOODLE" --summary="K1 Moodle dev" --adminpass="test" --adminemail="admin@example.com"

# Load
elif [ "$SWITCH1" = "--reload" ]; then
    # Reloads all docker images
    ${basedir}/bin/moodle-docker-compose start

# Reload php setting in webserver image
elif [ "$SWITCH1" = "--php" ]; then
    # reloads
    ${basedir}/bin/moodle-docker-compose restart webserver 
    echo "Reloading PHP configuration by restarting webserver image."

# Behat
elif [ "$SWITCH1" = "--behat" ]; then
    # Add in unit tests initialization.
    ${basedir}/bin/moodle-docker-compose exec webserver php admin/tool/behat/init.php

# Destroy
elif [ "$SWITCH1" = "--destroy" ]; then
    bin/moodle-docker-compose down

# PHPUnit
elif [ "$SWITCH1" = "--phpunit" ]; then
   # Start up containers
   bin/moodle-docker-compose up -d
   # Wait for DB to come up
   bin/moodle-docker-wait-for-db
   bin/moodle-docker-compose exec webserver php admin/tool/phpunit/cli/init.php

# Behat
elif [ "$SWITCH1" = "--behat" ]; then
   # Start up containers
   bin/moodle-docker-compose up -d
   # Wait for DB to come up
   bin/moodle-docker-wait-for-db
   bin/moodle-docker-compose exec webserver php admin/tool/behat/cli/init.php

fi

exit 1