#!/usr/bin/env bash
set -e

basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"

export MOODLE_DOCKER_WWWROOT="${basedir}/moodle"
export MOODLE_DOCKER_BROWSER=chrome
export MOODLE_DOCKER_DB=pgsql

if [ "$SUITE" = "app" ] || [ "$SUITE" = "app-development" ];
then
    testcmd="bin/moodle-docker-compose exec -T webserver php admin/tool/behat/cli/run.php --tags=@app&&@moodledocker"
else
    echo "Error, unknown suite '$SUITE'"
    exit 1
fi

echo "Running: $testcmd"
$basedir/$testcmd
