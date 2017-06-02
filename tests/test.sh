#!/usr/bin/env bash
set -e

basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"

if [ "$SUITE" = "phpunit" ];
then
    testcmd="bin/moodle-docker-compose exec -T webserver vendor/bin/phpunit core_dml_testcase lib/dml/tests/dml_test.php"
elif [ "$SUITE" = "behat" ];
then
    testcmd="bin/moodle-docker-compose exec -T webserver php admin/tool/behat/cli/run.php --tags=@core_tag"
elif [ "$SUITE" = "phpunit-full" ];
then
    testcmd="bin/moodle-docker-compose exec -T webserver vendor/bin/phpunit --verbose"
else
    echo "Error, unknown suite '$SUITE'"
    exit 1
fi

echo "Running: $testcmd"
$basedir/$testcmd
