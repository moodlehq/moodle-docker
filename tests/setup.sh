#!/usr/bin/env bash
set -e
basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"

if [ "$SUITE" = "phpunit" ];
then
    initcmd="bin/moodle-docker-compose exec -T webserver php admin/tool/phpunit/cli/init.php"
elif [ "$SUITE" = "behat" ];
then
    initcmd="bin/moodle-docker-compose exec -T webserver php admin/tool/behat/cli/init.php"
elif [ "$SUITE" = "phpunit-full" ];
then
    export MOODLE_DOCKER_PHPUNIT_EXTERNAL_SERVICES=true
    initcmd="bin/moodle-docker-compose exec -T webserver php admin/tool/phpunit/cli/init.php"
elif [ "$SUITE" = "behat-app" ];
then
    git clone --branch "v$APP_VERSION" --depth 1 git://github.com/moodlehq/moodle-local_moodlemobileapp $HOME/moodle/local/moodlemobileapp

    initcmd="bin/moodle-docker-compose exec -T webserver php admin/tool/behat/cli/init.php"
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
echo "Waiting for Moodle app to come up"
$basedir/bin/moodle-docker-wait-for-app
echo "Running: $initcmd"
$basedir/$initcmd
