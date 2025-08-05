#!/usr/bin/env bash
set -e
basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"

export MOODLE_DOCKER_WWWROOT="${basedir}/moodle"

if [ -d "$MOODLE_DOCKER_WWWROOT/public" ];
then
    MOODLE_PUBLIC_ROOT="$MOODLE_DOCKER_WWWROOT/public"
else
    MOODLE_PUBLIC_ROOT="$MOODLE_DOCKER_WWWROOT"
fi

rm -f ${MOODLE_PUBLIC_ROOT}/local/moodleappbehat/tests/behat/app.feature

if [ "$SUITE" = "phpunit" ];
then
    echo
elif [ "$SUITE" = "phpunit-full" ];
then
    export MOODLE_DOCKER_PHPUNIT_EXTERNAL_SERVICES=true
else
    echo "Error, unknown suite '$SUITE'"
    exit 1
fi

echo "Stopping down container"
$basedir/bin/moodle-docker-compose down
