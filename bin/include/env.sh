#!/usr/bin/env bash

# If moodle-docker.env file found then use it as default environment values.
filename="moodle-docker.env"
if [ -f $filename ]; then
    envbackup=$( export -p)
    export $(grep -v '^#' $filename | xargs)
    eval "$envbackup"
    if [ -z "$MOODLE_DOCKER_WWWROOT" ] && [ -f 'lib/moodlelib.php' ];
    then
        # We know that moodle is in current directory, so use it as default value.
        currentdir="$( pwd -P )";
        export MOODLE_DOCKER_WWWROOT="$currentdir";
    fi
    if [ -z "$COMPOSE_PROJECT_NAME" ] && [ -f 'lib/moodlelib.php' ];
    then
        # Use moodle directory name as default Compose project name.
        name="$( basename "$( pwd -P )" )"
        export COMPOSE_PROJECT_NAME="$name";
    fi
fi

if [ ! -d "$MOODLE_DOCKER_WWWROOT" ]; then
    echo 'Error: MOODLE_DOCKER_WWWROOT is not set or not an existing directory'
    exit 1
fi

if [ -z "$MOODLE_DOCKER_DB" ];
then
    echo 'Error: MOODLE_DOCKER_DB is not set'
    exit 1
fi
