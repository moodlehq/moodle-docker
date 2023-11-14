#!/usr/bin/env bash
set -e

basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"

export MOODLE_DOCKER_DB=pgsql
export MOODLE_DOCKER_WWWROOT="${basedir}/moodle"

echo "Pulling docker images"
$basedir/bin/moodle-docker-compose pull
echo "Starting up container"
$basedir/bin/moodle-docker-compose up -d
echo "Waiting for DB to come up"
$basedir/bin/moodle-docker-wait-for-db
