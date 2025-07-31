#!/usr/bin/env bash
set -e
basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"

export MOODLE_DOCKER_WWWROOT="${basedir}/moodle"

if [ -d "${MOODLE_DOCKER_WWWROOT}/public" ];
then
    MOODLE_BEHAT_CLI_ROOT="public/admin/tool/behat/cli"
else
    MOODLE_BEHAT_CLI_ROOT="admin/tool/behat/cli"
fi

if [ "$SUITE" = "behat" ];
then
    initcmd="bin/moodle-docker-compose exec -T webserver php ${MOODLE_BEHAT_CLI_ROOT}/init.php"
else
    echo "Error, unknown suite '$SUITE'"
    exit 1
fi

echo "Pulling docker images"
$basedir/bin/moodle-docker-compose pull
echo "Starting up container"
$basedir/bin/moodle-docker-compose up -d
echo "Waiting for DB to come up"
$basedir/bin/moodle-docker-wait-for-db
echo "Running: $initcmd"
$basedir/$initcmd
