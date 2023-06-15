#!/usr/bin/env bash
set -e
basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"

export MOODLE_DOCKER_WWWROOT="${basedir}/moodle"

rm -f $basedir/moodle/local/moodleappbehat/tests/behat/app.feature

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
