#!/usr/bin/env bash
set -e

basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"

export MOODLE_DOCKER_WWWROOT="${basedir}/moodle"
export MOODLE_DOCKER_DB=pgsql

echo "Stopping down container"
$basedir/bin/moodle-docker-compose down
