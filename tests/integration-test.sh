#!/usr/bin/env bash
set -e

basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"

export MOODLE_DOCKER_WWWROOT="${basedir}/moodle"
export MOODLE_DOCKER_DB=pgsql

echo "Checking that PHP CLI is available"

out=$("${basedir}/bin/moodle-docker-compose" exec -T webserver php -r 'echo "Up!";')
if [[ ! "$out" =~ 'Up!' ]]; then
    echo "Error: PHP CLI isn't available"
    exit 1
fi

echo "Checking that the web server is up"

if ! curl -s -f 'http://localhost:8000' > /dev/null; then
    echo "Error: Webserver not available in port 8000"
    exit 1
fi

echo "Checking that the Moodle site is ready to install"

out=$(curl -s -L 'http://localhost:8000')
if ! grep -qz 'Installation | Moodle ' <<< "$out"; then
    echo "Error: Moodle site not ready to install"
    exit 1
fi

echo "Checking that mailpit is up"

if ! curl -s -f -L 'http://localhost:8000/_/mail' > /dev/null; then
    echo "Error: Mailpit not available @ http://localhost:8000/_/mail"
    exit 1
fi

echo "Checking that mailpit is using existing JS and CSS files"

out=$(curl -s -L 'http://localhost:8000/_/mail')
js=$(grep -oP '(?<=<script src=")[^"\?]+' <<< "$out")
if ! curl -s -f "http://localhost:8000$js" > /dev/null; then
    echo "Error: Mailpit JS not available @ http://localhost:8000$js"
    exit 1
fi
css=$(grep -oP '(?<=<link rel=stylesheet href=")[^"\?]+' <<< "$out")
if ! curl -s -f "http://localhost:8000$css" > /dev/null; then
    echo "Error: Mailpit CSS not available @ http://localhost:8000$css"
    exit 1
fi
