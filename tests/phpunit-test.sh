#!/usr/bin/env bash
set -e

basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"

export MOODLE_DOCKER_WWWROOT="${basedir}/moodle"

if [ "$SUITE" = "phpunit" ];
then
    testcmd="bin/moodle-docker-compose exec -T webserver vendor/bin/phpunit --filter core_dml_testcase"
elif [ "$SUITE" = "phpunit-full" ];
then
    testcmd="bin/moodle-docker-compose exec -T webserver vendor/bin/phpunit --verbose"
else
    echo "Error, unknown suite '$SUITE'"
    exit 1
fi

echo "Running: $testcmd"
$basedir/$testcmd
