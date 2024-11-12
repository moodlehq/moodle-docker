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

# Decorator to output information message to the user.
# Takes 1 param, then message to be displayed.
info_message() {
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
    echo
    echo "${CYAN}$1${NC}"
    echo
}

# Decorator to output error message to the user.
# Takes 1 param, then message to be displayed.
error_message() {
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo
    echo "${RED}$1${NC}"
    echo
}

start_server() {
     # Start the server
     bin/moodle-docker-compose up -d
     # Sleep for 6 seconds to allow database to come up
     sleep 6
     # Just in case there is still some latency.
     bin/moodle-docker-wait-for-db
     return 0
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

# Variables
# MOODLE_DOCKER_DB          - database used by Moodle - default maria db
# MOODLE_DOCKER_WWWROOT     - folder where the Moodle code is located;
# MOODLE_DOCKER_PORT        - port (default 8000);
# MOODLE_DOCKER_PHP_VERSION - php version used in Moodle - default 8.1;
# COMPOSE_PROJECT_NAME      - Docker project name - used to identify sites;

if [ $# -eq 0 ];  then
    echo "No arguments supplied"
    help_messages
    exit 1
fi

if [ $# -lt 1 ] || [ $# -gt 4 ] ;  then
    echo "Invalid number of arguments passed in. Must be between 1 and 4 arguments"
    help_messages
    exit 1
fi

list_of_options="--build  --destroy --help --reboot --stop --start --restart"
cwd=$( dirname "$PWD" )
count=0
for var in "$@"
do
    count=$((count+1))
    if [ "$count" -eq 1 ]; then
        SWITCH=${var}
        # Check to see if the list of arguments is valid.
        if  exists_in_list "$list_of_options" " " $SWITCH;  then
            echo "Invalid option $SWITCH."
            help_messages
            exit 1
        fi
        # Check for any swithes that don't need options.
        case $SWITCH in
           "--build")
                if [ -n "$(docker ps -f "name=${var}-webserver-1" -f "status=running" -q )" ]; then
                    echo "The first site is already running!. It cannot be re-initialized."
                    exit 1
                fi
                # Do the basics to start the site.
                export MOODLE_DOCKER_DB=mariadb
                export COMPOSE_PROJECT_NAME=site1
                cp local.yml_many local.yml
                ;;
           "--help")
              help_messages
              exit 1
              ;;
            "--destroy")
                if ! docker ps | grep -q 'moodlehq'; then
                   info_message "No containers running. Nothing to shutdown."
                   exit 1
                fi
                docker stop $(docker ps -a -q)
                docker rm $(docker ps -a -q)
                info_message "All containers shut down and removed."
                exit 1
                ;;
             # Restart
            "--restart")
                if ! docker ps | grep -q 'moodlehq'; then
                     info_message "No containers running. Nothing to reboot."
                     exit 1
                fi
                docker restart $(docker ps -q)
                info_message "All sites restarted."
                exit 1
                ;;
            # Start
            "--start")
                if [ -n "$(docker ps -f "name=site1-webserver-1" -f "status=running" -q )" ]; then
                     info_message "Sites are already running."
                     exit 1
                fi
                docker start $(docker ps -a -q -f status=exited)
                info_message "All sites started."
                exit 1
                ;;
            # Stop
            "--stop")
                if ! docker ps | grep -q 'moodlehq'; then
                   info_message "No containers running. Nothing to stop."
                   exit 1
               fi
               docker stop $(docker ps -q)
               info_message "All sites stopped."
               exit 1
               ;;

        esac
    else
        # Used to name the project according to the folder name
        # which makes it easier to recognize who is who in Docker.
        projectname="${var}"

        # Full path of the folder containing the Moodle files.
        folder="${cwd}/${var}"
        if [ ! -d "${folder}" ]; then
            echo "${folder} is not valid"
            exit 1
        fi

        # Start the site
        # Check the Moodle version. If its 4.5 then set php version to 8.3
        export MOODLE_DOCKER_PHP_VERSION=8.1
        moodlever=$(grep "$branch   = '405';" $folder/version.php)
        if [ "$moodlever" ]; then
           export MOODLE_DOCKER_PHP_VERSION=8.3
        fi
        export MOODLE_DOCKER_WWWROOT=${folder}
        cp config.docker-template.php $MOODLE_DOCKER_WWWROOT/config.php
        case $count in
           "2")
               export COMPOSE_PROJECT_NAME=${projectname}
               export MOODLE_DOCKER_WEB_PORT=8000
               start_server
               bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="${projectname}" --shortname="${projectname}" --summary="${projectname}" --adminpass="test" --adminemail="admin@example.com"
               info_message "${folder} site started - port 8000"
            ;;
            "3")
               export COMPOSE_PROJECT_NAME=${projectname}
               export MOODLE_DOCKER_WEB_PORT=1234
               start_server
               bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="${projectname}" --shortname="${projectname}" --summary="${projectname}" --adminpass="test" --adminemail="admin@example.com"
               info_message "${folder} site started - port 1234"
            ;;
            "4")
               export COMPOSE_PROJECT_NAME=${projectname}
               export MOODLE_DOCKER_WEB_PORT=6789
               start_server
               bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="${projectname}" --shortname="${projectname}" --summary="${projectname}" --adminpass="test" --adminemail="admin@example.com"
               info_message "${folder} site started - port 6789"
            ;;
         esac
    fi
done

return
