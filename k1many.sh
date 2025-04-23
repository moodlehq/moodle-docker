#!/usr/bin/env bash

# Define colors for various the output messages.
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

help_messages () {
    echo
    echo
    echo -e "${GREEN}Usage:${NC}"
    echo "    Script that can start multiple Moodle instances."
    echo "    ./k1many.sh option folder1 [folder2] [folder3]"
    echo
    echo -e "${GREEN}Options:${NC}"
    echo "    --build       Create and start the containers for the passed folders."
    echo "    --destroy     Stop and remove all running containers. All data is lost."
    echo "    --help        Display this message."
    echo "    --restart     Restart all running containers."
    echo "    --start       Start all stopped containers. Needs folder(s) path as well. See examples."
    echo "    --stop        Stop all running containers."
    echo
    echo -e "${GREEN}Folders:${NC}"
    echo "    folder1       Folder pointing to first Moodle instance (Mandatory)."
    echo "    [folder2]     Folder pointing to second Moodle instance (optional)."
    echo "    [folder3]     Folder pointing to third Moodle instance (optional)."
    echo
    echo -e "${GREEN}Examples:${NC}"
    echo "    Start three Moodle instances. Path starts at /home/username/projects/[folder]."
    echo "    In this example, the fist Moodle instance will be in /home/username/projects/M405."
    echo "    ./k1many.sh --build M405 M401 MT"
    echo
    echo "    Start all Moodle instances passed in script parameters. Same as --build."
    echo "    ./k1many.sh --start folder1 [folder2] [folder3]"
    echo
    echo "    Stops all running containers."
    echo "    ./k1many.sh --stop"
    echo
    echo "    Stops and removes all running containers. All data is lost."
    echo "    ./k1many.sh --destroy"
    echo
    echo
}

# Decorator to output information message to the user.
# Takes 1 param, then message to be displayed.
info_message() {
    echo
    echo -e "${CYAN}$1${NC}"
    echo
}

# Decorator to output error message to the user.
# Takes 1 param, then message to be displayed.
error_message() {
    echo
    echo -e "${RED}$1${NC}"
    echo
}

start_server() {
    # Start the server
    bin/moodle-docker-compose up -d

    # Sleep for 6 seconds to allow database to come up
    # sleep 6

    # Just in case there is still some latency.
    bin/moodle-docker-wait-for-db
}

start_instances() {

    # Project name.
    projectname=$1

    # Starts the container and wait for DB.
    start_server

    info_message "${projectname} is available at http://localhost:${MOODLE_DOCKER_WEB_PORT}"
}

# Function to group the commands to build the each instances.
# The params are validated before this function is called.
build_instances() {
    # Project name (folder that contains the Moodle files)
    projectname=$1

    # Full path of the Moodle folder.
    folder=$2

    # xDebug port. Must be different for each instances.
    # xdebugport=$3

    # Reset the xDebug config file from previous boot.
    # We reset it to set the client port back 9003 to
    # make sure the sed will find and replace it with
    # the new client port.
    # git checkout assets/php/docker-php-ext-xdebug.ini

    # Change xDebug port for this instance.
    # sed -i -e 's/xdebug.client_port=9003/xdebug.client_port='"${xdebugport}"'/g' assets/php/docker-php-ext-xdebug.ini

    # Starts the container and wait for DB.
    start_server

    # This is a Moodle admin plugin that provides developers with insights into
    # not only what pages in your site are slow, but why.
    # It uses the the Excimer sampling php profiler to so.
    bin/moodle-docker-compose exec webserver pecl install excimer
    bin/moodle-docker-compose exec webserver docker-php-ext-enable excimer

    # Install Moodle.
    bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="${projectname}" --shortname="${projectname}" --summary="${projectname}" --adminpass="test" --adminemail="admin@example.com"

    # Set the session cookie to avoid login problem between instances.
    bin/moodle-docker-compose exec webserver php admin/cli/cfg.php --name=sessioncookie --set="${projectname}"

    # Enable course recycle bin
    bin/moodle-docker-compose exec webserver php admin/cli/cfg.php --name=coursebinenable --set=0

    # Include users in course backup
    # Sets the default for whether to include users in backups.
    php admin/cli/cfg.php --component=backup --name=backup_general_users --set=0


    # Install xdebug extention in the new webserser.
    # If already installed, the install will just fail.
    bin/moodle-docker-compose exec webserver pecl install xdebug

    # Enable XDebug extension in Apache and restart the webserver container
    bin/moodle-docker-compose exec webserver docker-php-ext-enable xdebug
    bin/moodle-docker-compose restart webserver

    info_message "${folder} is available at http://localhost:${MOODLE_DOCKER_WEB_PORT}"
}

# This function resets all config files used during boot of project.
# Should be used when --destroy containers.
reset_config_files() {
    rm local.yml
    git checkout assets/php/docker-php-ext-xdebug.ini
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

validate_folder_path() {
    if [ ! -d "${1}" ]; then
        error_message "${1} is not a valid folder."
        help_messages
        exit 1
    fi
}

###################
### Validations ###
if [ $# -eq 0 ]; then
    error_message "No arguments supplied. See help message below."
    help_messages
    exit 1
fi

if [ $# -lt 1 ] || [ $# -gt 4 ]; then
    error_message "Invalid number of arguments passed in. Must be between 1 and 4 arguments."
    help_messages
    exit 1
fi

# Validate the switch passed to the script.
list_of_options="--build --destroy --help --reboot --stop --start --restart"
SWITCH=$1
if  exists_in_list "$list_of_options" " " $SWITCH; then
    error_message "Invalid option $SWITCH."
    help_messages
    exit 1
fi

# Display help message if the --help switch is present.
if [ "$SWITCH" = "--help" ]; then
    help_messages
    exit 0
fi

########################
### Global variables ###
# MOODLE_DOCKER_DB          - database used by Moodle - default maria db
# MOODLE_DOCKER_WWWROOT     - folder where the Moodle code is located;
# MOODLE_DOCKER_PORT        - port (default 8000);
# MOODLE_DOCKER_PHP_VERSION - php version used in Moodle - default 8.1;
# COMPOSE_PROJECT_NAME      - Docker project name - used to identify sites;

# We always use Maria DB for all our Moodle.
export MOODLE_DOCKER_DB=mariadb

# Current working dir.
# Typically gives /home/username/projects.
cwd=$( dirname "$PWD" )

# Moodle Docker Port.
# AKA which port the webserver container will listen to.
moodleDockerPort=(8000 1234 5678)

# xDebug ports
# Each containers must have a their own port.
xdebugPort=(9003 9004 9005)

# Use the multiple instances local.yml file.
cp local.yml_many local.yml

################################################
### Process swithes that don't need options. ###
case $SWITCH in
    "--destroy")
        if ! docker ps | grep -q 'moodlehq'; then
            info_message "No containers running. Nothing to shutdown."
            exit 1
        fi
        docker stop $(docker ps -a -q)
        docker rm $(docker ps -a -q)
        reset_config_files
        info_message "All containers shut down and removed."
        exit 1
        ;;
    "--restart")
        if ! docker ps | grep -q 'moodlehq'; then
            info_message "No containers running. Nothing to reboot."
            exit 1
        fi
        docker restart $(docker ps -q)
        info_message "All sites restarted."
        exit 1
        ;;
    "--stop")
        if ! docker ps | grep -q 'moodlehq'; then
            info_message "No containers running. Nothing to stop."
            exit 1
        fi
        docker stop $(docker ps -q)
        # reset_config_files
        info_message "All sites stopped."
        exit 1
        ;;
esac

#############################################
### Process swithes that require options. ###

# Ignore first parm passed to the script.
# Skip the --switch to cycle the folders in argument.
shift

iteratior=0

# Iterate the passed folders.
for i in "$@"
do
    # Folder passed in args to the script.
    argfolder="$i"

    # Full system path of the Moodle instance.
    validate_folder_path "${cwd}/${argfolder}"
    fullfolderpath="${cwd}/${argfolder}"
    export MOODLE_DOCKER_WWWROOT=${fullfolderpath}

    # Check the Moodle version. If its 4.5 then set php version to 8.3.
    export MOODLE_DOCKER_PHP_VERSION=8.1
    moodlever=$(grep "$branch   = '405';" $fullfolderpath/version.php)
    if [ "$moodlever" ]; then
        export MOODLE_DOCKER_PHP_VERSION=8.3
    fi

    # Used to name the project according to the folder name
    # which makes it easier to recognize who is who in Docker.
    projectname="${argfolder}"
    export COMPOSE_PROJECT_NAME=${projectname}

    # Set the port for the webserver.
    export MOODLE_DOCKER_WEB_PORT="${moodleDockerPort[$iteratior]}"

    # Copy the config.php file to the Moodle folder.
    cp config.docker-template.php $MOODLE_DOCKER_WWWROOT/config.php

    case $SWITCH in
        "--build")
            if [ -n "$(docker ps -f "name=${projectname}-webserver-1" -f "status=running" -q )" ]; then
                error_message "The first site is already running! It cannot be re-initialized."
                exit 1
            fi

            # Build containers and install Moodle.
            build_instances ${projectname} ${fullfolderpath} "${xdebugPort[$iteratior]}"
            ;;
        "--start")

            # Start all Moodle instances.
            start_instances ${projectname} "${xdebugPort[$iteratior]}"
            ;;
    esac

    # Increment loop counter.
    iteratior=$((iteratior+1))
done
exit 0
