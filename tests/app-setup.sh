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

export MOODLE_DOCKER_BROWSER=chrome
export MOODLE_DOCKER_DB=pgsql

initcmd="bin/moodle-docker-compose exec -T webserver php ${MOODLE_BEHAT_CLI_ROOT}/init.php"

if [ -d "$basedir/moodle/public" ];
then
    MOODLE_PUBLIC_ROOT="$basedir/moodle/public"
else
    MOODLE_PUBLIC_ROOT="$basedir/moodle"
fi

if [ "$SUITE" = "app-development" ];
then
    export MOODLE_DOCKER_APP_PATH="${basedir}/app"

    git clone --branch "$MOODLE_DOCKER_APP_VERSION" --depth 1 https://github.com/moodlehq/moodleapp $basedir/app
    git clone --branch "$MOODLE_DOCKER_APP_VERSION" --depth 1 https://github.com/moodlehq/moodle-local_moodleappbehat ${MOODLE_PUBLIC_ROOT}/local/moodleappbehat

    if [[ ! -f $basedir/app/.npmrc  || -z "$(cat $basedir/app/.npmrc | grep unsafe-perm)" ]];
    then
        echo -e "\nunsafe-perm=true" >> $basedir/app/.npmrc
    fi

    nodeversion="$(cat $MOODLE_DOCKER_APP_PATH/.nvmrc | sed -E "s/v(([0-9]+\.?)+)/\1/" || true)"
    nodeversion="${nodeversion//\//-}"

    docker run --volume $basedir/app:/app --workdir /app node:$nodeversion bash -c "npm ci"
elif [ "$SUITE" = "app" ];
then
    branch=`echo $MOODLE_DOCKER_APP_VERSION | grep -P -o "next|latest|\d\.\d\.\d"`

    if [ "$branch" = "next" ];
    then
        branch="main"
    elif [ "$branch" != "latest" ];
    then
        branch="v$branch"
    fi

    git clone --branch "$branch" --depth 1 https://github.com/moodlehq/moodle-local_moodleappbehat ${MOODLE_PUBLIC_ROOT}/local/moodleappbehat

else
    echo "Error, unknown suite '$SUITE'"
    exit 1
fi

cp $basedir/assets/appbehattests/app.feature ${MOODLE_PUBLIC_ROOT}/local/moodleappbehat/tests/behat/app.feature

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
