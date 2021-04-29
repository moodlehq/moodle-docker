#!/usr/bin/env bash
set -e
basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"

export MOODLE_DOCKER_WWWROOT="${basedir}/moodle"
export MOODLE_DOCKER_BROWSER="chrome"

if [ "$SUITE" = "app-development" ];
then
    export MOODLE_DOCKER_APP_PATH="${basedir}/app"

    if [[ $RUNTIME = ionic5 ]];
    then
        git clone --branch "ionic5" --depth 1 git://github.com/moodlehq/moodleapp $basedir/app
        git clone --branch "ionic5" --depth 1 git://github.com/moodlehq/moodle-local_moodlemobileapp $basedir/moodle/local/moodlemobileapp
    else
        git clone --branch "v$MOODLE_DOCKER_APP_VERSION" --depth 1 git://github.com/moodlehq/moodleapp $basedir/app
        git clone --branch "v$MOODLE_DOCKER_APP_VERSION" --depth 1 git://github.com/moodlehq/moodle-local_moodlemobileapp $basedir/moodle/local/moodlemobileapp
    fi

    if [[ $RUNTIME = ionic5 ]];
    then
        docker run --volume $basedir/app:/app --workdir /app node:14 npm ci
    else
        docker run --volume $basedir/app:/app --workdir /app node:11 npm run setup
        docker run --volume $basedir/app:/app --workdir /app node:11 npm ci
    fi

    initcmd="bin/moodle-docker-compose exec -T webserver php admin/tool/behat/cli/init.php"
elif [ "$SUITE" = "app" ];
then
    if [[ $RUNTIME = ionic5 ]];
    then
        git clone --branch "ionic5" --depth 1 git://github.com/moodlehq/moodle-local_moodlemobileapp $basedir/moodle/local/moodlemobileapp
    else
        git clone --branch "v$MOODLE_DOCKER_APP_VERSION" --depth 1 git://github.com/moodlehq/moodle-local_moodlemobileapp $basedir/moodle/local/moodlemobileapp
    fi

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
