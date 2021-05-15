#!/usr/bin/env bash
set -e
basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"

export MOODLE_DOCKER_WWWROOT="${basedir}/moodle"

if [ "$SUITE" = "behat" ];
then
    echo
else
    echo "Error, unknown suite '$SUITE'"
    exit 1
fi

echo "Stopping down container"
$basedir/bin/moodle-docker-compose down
