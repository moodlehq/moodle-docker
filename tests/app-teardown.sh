#!/usr/bin/env bash
set -e
basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"

export MOODLE_DOCKER_WWWROOT="${basedir}/moodle"
export MOODLE_DOCKER_BROWSER="chrome"

if [ "$SUITE" = "app-development" ];
then
    export MOODLE_DOCKER_APP_PATH="${basedir}/app"
elif [ "$SUITE" = "app" ];
then
    echo
else
    echo "Error, unknown suite '$SUITE'"
    exit 1
fi

echo "Stopping down container"
$basedir/bin/moodle-docker-compose down
