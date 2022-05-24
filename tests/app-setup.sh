#!/usr/bin/env bash
set -e
basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"
initcmd="bin/moodle-docker-compose exec -T webserver php admin/tool/behat/cli/init.php"

export MOODLE_DOCKER_WWWROOT="${basedir}/moodle"
export MOODLE_DOCKER_BROWSER="chrome"

if [ "$SUITE" = "app-development" ];
then
    export MOODLE_DOCKER_APP_PATH="${basedir}/app"

    git clone --branch "v$MOODLE_DOCKER_APP_VERSION" --depth 1 https://github.com/moodlehq/moodleapp $basedir/app
    git clone --branch "v$MOODLE_DOCKER_APP_VERSION" --depth 1 https://github.com/moodlehq/moodle-local_moodlemobileapp $basedir/moodle/local/moodlemobileapp

    if [[ $RUNTIME = ionic5 ]];
    then
        docker run --volume $basedir/app:/app --workdir /app node:14 bash -c "npm install npm@7 -g && npm ci"
    else
        docker run --volume $basedir/app:/app --workdir /app node:11 npm run setup
        docker run --volume $basedir/app:/app --workdir /app node:11 npm ci
    fi
elif [ "$SUITE" = "app" ];
then
    appversion=`echo $MOODLE_DOCKER_APP_VERSION | grep -E -o "[0-9]+\.[0-9]+\.[0-9]"`

    git clone --branch "v$appversion" --depth 1 https://github.com/moodlehq/moodle-local_moodlemobileapp $basedir/moodle/local/moodlemobileapp
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
